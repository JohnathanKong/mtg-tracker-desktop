#include "DeviceSync.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QRegularExpression>
#include <QtGlobal>
#include <memory>
#include <stdexcept>

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

namespace {
constexpr int kMaxPayload = 65536;
constexpr int kChunkSize = 256;

quint32 crc32(const QByteArray &bytes) {
    quint32 crc = 0xFFFFFFFFu;
    for (unsigned char ch : bytes) {
        crc ^= ch;
        for (int b=0; b<8; ++b)
            crc = (crc >> 1u) ^ ((crc & 1u) ? 0xEDB88320u : 0u);
    }
    return crc ^ 0xFFFFFFFFu;
}

QString hexCrc(quint32 crc) {
    return QStringLiteral("%1").arg(crc, 8, 16, QLatin1Char('0')).toUpper();
}

QStringList list(const QVariant &value) {
    return value.toStringList();
}

QByteArray buildPayload(const QVariantList &profiles, QString &problem) {
    if (profiles.size() > 100) {
        problem = QStringLiteral("Maximum 100 decks per transfer.");
        return {};
    }
    QJsonArray decks;
    for (const QVariant &value : profiles) {
        const QVariantMap deck = value.toMap();
        const QString id = deck.value(QStringLiteral("id")).toString();
        const QString name = deck.value(QStringLiteral("name")).toString();
        const QString commander = deck.value(QStringLiteral("commander")).toString();

        auto fits = [](const QString &s) { return s.toUtf8().size() <= 128; };
        if (id.isEmpty() || name.isEmpty() || !fits(id) || !fits(name) || !fits(commander)) {
            problem = QStringLiteral("A deck name or ID is missing or exceeds 128 UTF-8 bytes.");
            return {};
        }

        const QStringList colors = list(deck.value(QStringLiteral("colors")));
        const QStringList trackers = list(deck.value(QStringLiteral("trackers")));
        if (colors.size() > 5 || trackers.size() > 150) {
            problem = QStringLiteral("A deck has too many selected trackers or colors.");
            return {};
        }

        QJsonArray trackerArray;
        for (const QString &tracker : trackers) {
            if (tracker.isEmpty() || !fits(tracker)) {
                problem = QStringLiteral("One tracker ID exceeds 128 bytes.");
                return {};
            }
            trackerArray.append(tracker);
        }

        QJsonArray customArray;
        const QVariantList customs = deck.value(QStringLiteral("customTrackers")).toList();
        if (customs.size() > 100) {
            problem = QStringLiteral("Maximum 100 custom trackers per deck.");
            return {};
        }
        for (const QVariant &entry : customs) {
            const QVariantMap custom = entry.toMap();
            const QString customId = custom.value(QStringLiteral("id")).toString();
            const QString label = custom.value(QStringLiteral("label")).toString();
            if (customId.isEmpty() || label.isEmpty() || !fits(customId) || !fits(label)) {
                problem = QStringLiteral("A custom tracker has an invalid name or ID.");
                return {};
            }
            customArray.append(QJsonObject{
                {QStringLiteral("id"), customId},
                {QStringLiteral("label"), label}
            });
        }

        for (const QString &color : colors) {
            if (color.size() != 1 || !QStringLiteral("WUBRG").contains(color)) {
                problem = QStringLiteral("Unknown mana color in a deck.");
                return {};
            }
        }

        decks.append(QJsonObject{
            {QStringLiteral("id"), id},
            {QStringLiteral("name"), name},
            {QStringLiteral("commander"), commander},
            {QStringLiteral("colors"), QJsonArray::fromStringList(colors)},
            {QStringLiteral("trackers"), trackerArray},
            {QStringLiteral("customTrackers"), customArray}
        });
    }

    const QByteArray json = QJsonDocument(QJsonObject{
        {QStringLiteral("version"), 1},
        {QStringLiteral("decks"), decks}
    }).toJson(QJsonDocument::Compact);

    if (json.size() > kMaxPayload) {
        problem = QStringLiteral("Deck data exceeds 64 KB. Artwork is not included in v1.");
        return {};
    }
    return json;
}

#ifdef Q_OS_WIN
struct PortHandle {
    HANDLE handle = INVALID_HANDLE_VALUE;
    ~PortHandle() {
        if (handle != INVALID_HANDLE_VALUE) CloseHandle(handle);
    }
};

void writeBytes(HANDLE port, const QByteArray &bytes) {
    int offset = 0;
    while (offset < bytes.size()) {
        DWORD written = 0;
        const DWORD length = DWORD(bytes.size() - offset);
        if (!WriteFile(port, bytes.constData() + offset, length, &written, nullptr) ||
            written == 0) {
            throw std::runtime_error("USB serial write failed (port disconnected or busy).");
        }
        offset += int(written);
    }
}

void sendLine(HANDLE port, const QByteArray &line) {
    writeBytes(port, line + '\n');
}

QString readReply(HANDLE port, DWORD timeoutMs) {
    const ULONGLONG deadline = GetTickCount64() + timeoutMs;
    QByteArray buffer;
    while (GetTickCount64() < deadline) {
        char ch = 0;
        DWORD got = 0;
        if (!ReadFile(port, &ch, 1, &got, nullptr))
            throw std::runtime_error("USB serial read failed (port disconnected).");
        if (!got) continue;

        if (ch == '\r') continue;
        if (ch == '\n') {
            const QString line = QString::fromLatin1(buffer).trimmed();
            buffer.clear();
            if (line.startsWith(QStringLiteral("MTG1 ERROR ")))
                throw std::runtime_error(
                    QStringLiteral("Device rejected transfer: %1").arg(line.mid(11)).toStdString());
            if (line.startsWith(QStringLiteral("MTG1 ")))
                return line;
            continue; // Ignore board boot logs, not protocol replies.
        }
        if (buffer.size() >= 160) buffer.clear();
        else buffer.append(ch);
    }
    throw std::runtime_error("No reply from the MTG receiver. Check the USB-C orientation and firmware.");
}

void expectReply(HANDLE port, const QString &expected, DWORD timeoutMs = 5000) {
    const QString actual = readReply(port, timeoutMs);
    if (actual != expected) {
        throw std::runtime_error(
            QStringLiteral("Unexpected device reply: %1 (expected %2)")
                .arg(actual, expected).toStdString());
    }
}

template<typename Progress>
void sendToDevice(const QString &device, const QByteArray &payload, int deckCount,
                  const Progress &progress) {
    const QRegularExpression validPort(QStringLiteral("^COM[0-9]{1,3}$"),
                                       QRegularExpression::CaseInsensitiveOption);
    if (!validPort.match(device.trimmed()).hasMatch())
        throw std::runtime_error("Choose a valid serial port such as COM3.");

    const QString portName = QStringLiteral("\\\\.\\") + device.trimmed().toUpper();
    const std::wstring wideName = portName.toStdWString();
    PortHandle port;
    port.handle = CreateFileW(wideName.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                              OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (port.handle == INVALID_HANDLE_VALUE)
        throw std::runtime_error("Cannot open COM port. Close any serial monitor and retry.");

    if (!SetupComm(port.handle, 4096, 4096))
        throw std::runtime_error("Cannot initialize serial buffers.");

    DCB dcb{};
    dcb.DCBlength = sizeof(DCB);
    if (!GetCommState(port.handle, &dcb))
        throw std::runtime_error("Cannot read serial port settings.");
    dcb.BaudRate = CBR_115200;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;
    dcb.fBinary = TRUE;
    dcb.fOutxCtsFlow = FALSE;
    dcb.fOutxDsrFlow = FALSE;
    dcb.fOutX = FALSE;
    dcb.fInX = FALSE;
    if (!SetCommState(port.handle, &dcb))
        throw std::runtime_error("Cannot configure serial port at 115200 baud.");

    COMMTIMEOUTS timeouts{};
    timeouts.ReadIntervalTimeout = 40;
    timeouts.ReadTotalTimeoutConstant = 80;
    timeouts.WriteTotalTimeoutConstant = 4000;
    if (!SetCommTimeouts(port.handle, &timeouts))
        throw std::runtime_error("Cannot set serial port timeouts.");

    Sleep(650); // Allow a board that resets when serial opens to become ready.
    PurgeComm(port.handle, PURGE_RXCLEAR | PURGE_TXCLEAR);

    progress(2, QStringLiteral("Connecting to ESP32-S3..."));
    bool handshook = false;
    for (int attempt = 0; attempt < 3; ++attempt) {
        sendLine(port.handle, "MTG1 HELLO");
        try {
            expectReply(port.handle, QStringLiteral("MTG1 READY 1"), 2500);
            handshook = true;
            break;
        } catch (...) {
            if (attempt == 2) throw;
            Sleep(300);
        }
    }
    if (!handshook) throw std::runtime_error("ESP32-S3 did not complete handshake.");

    const QString checksum = hexCrc(crc32(payload));
    progress(5, QStringLiteral("Device connected; preparing transfer..."));
    sendLine(port.handle,
             QStringLiteral("MTG1 BEGIN %1 %2").arg(payload.size()).arg(checksum).toLatin1());
    expectReply(port.handle, QStringLiteral("MTG1 OK"));

    for (int offset = 0; offset < payload.size(); offset += kChunkSize) {
        const QByteArray chunk = payload.mid(offset, kChunkSize);
        sendLine(port.handle, "MTG1 CHUNK " + QByteArray::number(chunk.size()));
        writeBytes(port.handle, chunk);
        const int total = offset + chunk.size();
        expectReply(port.handle, QStringLiteral("MTG1 NEXT %1").arg(total), 5000);
        progress(5 + int((90.0 * total) / payload.size()),
                 QStringLiteral("Transferring deck profiles... %1 / %2 bytes")
                     .arg(total).arg(payload.size()));
    }

    progress(96, QStringLiteral("Verifying and storing on the device..."));
    sendLine(port.handle, "MTG1 COMMIT");
    expectReply(port.handle,
                QStringLiteral("MTG1 STORED %1 %2").arg(deckCount).arg(checksum),
                12000);
    progress(100, QStringLiteral("Sync verified: %1 deck profiles stored.").arg(deckCount));
}
#endif
} // namespace

DeviceSync::DeviceSync(QObject *parent) : QObject(parent) {
    refreshPorts();
}

DeviceSync::~DeviceSync() {
    if (m_thread) m_thread->wait(); // Don't destroy the receiver of queued callbacks early.
}

void DeviceSync::refreshPorts() {
    QStringList found;
#ifdef Q_OS_WIN
    HKEY key = nullptr;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"HARDWARE\\DEVICEMAP\\SERIALCOMM",
                      0, KEY_READ, &key) == ERROR_SUCCESS) {
        DWORD index = 0;
        while (true) {
            WCHAR name[256]{};
            WCHAR value[256]{};
            DWORD nameLength = 255;
            DWORD valueBytes = sizeof(value);
            DWORD type = 0;
            const LONG code = RegEnumValueW(key, index++, name, &nameLength, nullptr,
                                            &type, reinterpret_cast<BYTE *>(value), &valueBytes);
            if (code == ERROR_NO_MORE_ITEMS) break;
            if (code != ERROR_SUCCESS) continue;
            if (type == REG_SZ && valueBytes >= sizeof(WCHAR) &&
                valueBytes <= sizeof(value)) {
                value[255] = L'\0';
                const QString com = QString::fromWCharArray(value);
                if (!com.isEmpty() && !found.contains(com)) found.append(com);
            }
        }
        RegCloseKey(key);
    }
#endif
    found.sort(Qt::CaseInsensitive);
    if (m_ports != found) {
        m_ports = found;
        emit portsChanged();
    }
}

void DeviceSync::updateProgress(int percent, const QString &message) {
    if (m_progress != percent) {
        m_progress = percent;
        emit progressChanged();
    }
    m_status = message;
    emit statusChanged();
}

void DeviceSync::complete(bool success, const QString &detail, int deckCount) {
    m_busy = false;
    emit busyChanged();
    m_status = detail;
    emit statusChanged();
    if (success) emit syncSucceeded(deckCount);
    else emit syncFailed(detail);
}

void DeviceSync::sync(const QString &port, const QVariantList &decks) {
    if (m_busy) return;

    QString problem;
    const QByteArray payload = buildPayload(decks, problem);
    if (payload.isEmpty()) {
        complete(false, problem, 0);
        return;
    }

    m_busy = true;
    emit busyChanged();
    updateProgress(0, QStringLiteral("Preparing %1 deck profiles...").arg(decks.size()));
    const int deckCount = decks.size();

    struct Result { bool success = false; QString detail; };
    auto result = std::make_shared<Result>();

    QThread *thread = QThread::create([this, port, payload, deckCount, result] {
        auto progress = [this](int percent, const QString &message) {
            QMetaObject::invokeMethod(this, [this, percent, message] {
                updateProgress(percent, message);
            }, Qt::QueuedConnection);
        };

        try {
#ifdef Q_OS_WIN
            sendToDevice(port, payload, deckCount, progress);
            result->success = true;
            result->detail = QStringLiteral("Verified: %1 deck profiles stored on ESP32-S3.").arg(deckCount);
#else
            result->detail = QStringLiteral("USB COM sync currently requires Windows.");
#endif
        } catch (const std::exception &e) {
            result->detail = QString::fromUtf8(e.what());
        }
    });

    m_thread = thread;
    connect(thread, &QThread::finished, this, [this, result, thread, deckCount] {
        if (m_thread == thread) m_thread = nullptr;
        complete(result->success, result->detail, deckCount);
    });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    thread->start();
}
