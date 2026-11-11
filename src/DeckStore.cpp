#include "DeckStore.h"

#include <QDir>
#include <QDesktopServices>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>
#include <QDebug>
#include <algorithm>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

namespace {
QStringList strings(const QVariant &value) {
    if (value.canConvert<QStringList>())
        return value.toStringList();
    QStringList out;
    for (const QVariant &item : value.toList())
        out.append(item.toString());
    return out;
}
QStringList uniqueValues(const QStringList &values) {
    QStringList out;
    for (const QString &entry : values)
        if (!entry.trimmed().isEmpty() && !out.contains(entry))
            out.append(entry.trimmed());
    return out;
}
QVariantList normalizeCustoms(const QVariantList &input) {
    QVariantList output;
    QStringList ids;
    for (const QVariant &item : input) {
        const QVariantMap map = item.toMap();
        const QString id = map.value(QStringLiteral("id")).toString();
        const QString label = map.value(QStringLiteral("label")).toString().trimmed().left(64);
        if (id.isEmpty() || id.size() > 90 || label.isEmpty() || ids.contains(id))
            continue;
        if (!(id.startsWith(QStringLiteral("custom-")) ||
              id == QStringLiteral("custom_1") || id == QStringLiteral("custom_2")))
            continue;
        output.append(QVariantMap{{QStringLiteral("id"),id},{QStringLiteral("label"),label}});
        ids.append(id);
        if (output.size() >= 100) break;
    }
    return output;
}
QUrl validatedLink(const QString &value) {
    const QString url = value.trimmed();
    if (url.size() > 2048 || url.contains(QChar::Space))
        return {};
    const QUrl parsed(url, QUrl::StrictMode);
    if (!parsed.isValid() || parsed.host().isEmpty() || !parsed.userInfo().isEmpty() ||
        (parsed.scheme() != QStringLiteral("http") && parsed.scheme() != QStringLiteral("https")))
        return {};
    return parsed;
}
QString imageUrl(const QString &filename) {
    if (filename.isEmpty() || !QFileInfo::exists(filename))
        return {};
    return QUrl::fromLocalFile(filename).toString();
}
}

DeckStore::DeckStore(QObject *parent) : QAbstractListModel(parent) {
    m_folder = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
               + QStringLiteral("/MTGTrackerDesktop");
    if (!QDir().mkpath(m_folder + QStringLiteral("/images")))
        report(QStringLiteral("Could not create application data folder"));
    load();
}

int DeckStore::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : int(m_decks.size());
}

int DeckStore::count() const { return int(m_decks.size()); }

QVariant DeckStore::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= count())
        return {};
    const auto &d = m_decks[size_t(index.row())];
    switch (role) {
    case IdRole: return d.id;
    case NameRole: return d.name;
    case CommanderRole: return d.commander;
    case ArtworkRole: return imageUrl(d.artwork);
    case TrackerCountRole: return d.trackers.size();
    case ColorsRole: return d.colors;
    default: return {};
    }
}

QHash<int, QByteArray> DeckStore::roleNames() const {
    return {
        {IdRole, "deckId"},
        {NameRole, "deckName"},
        {CommanderRole, "commanderName"},
        {ArtworkRole, "artUrl"},
        {TrackerCountRole, "trackerCount"},
        {ColorsRole, "manaColors"}
    };
}

QVariantMap DeckStore::toMap(const DeckProfile &d) {
    return {
        {QStringLiteral("id"), d.id},
        {QStringLiteral("name"), d.name},
        {QStringLiteral("commander"), d.commander},
        {QStringLiteral("artwork"), d.artwork},
        {QStringLiteral("deckUrl"), d.deckUrl},
        {QStringLiteral("customTrackers"), d.customTrackers},
        {QStringLiteral("artworkUrl"), imageUrl(d.artwork)},
        {QStringLiteral("trackers"), d.trackers},
        {QStringLiteral("colors"), d.colors},
        {QStringLiteral("trackerCount"), d.trackers.size()}
    };
}

DeckProfile DeckStore::fromMap(const QVariantMap &map) {
    DeckProfile d;
    d.id = map.value(QStringLiteral("id")).toString();
    d.name = map.value(QStringLiteral("name")).toString().trimmed();
    d.commander = map.value(QStringLiteral("commander")).toString().trimmed();
    d.artwork = map.value(QStringLiteral("artwork")).toString();
    d.deckUrl = map.value(QStringLiteral("deckUrl")).toString().trimmed();
    d.customTrackers = normalizeCustoms(map.value(QStringLiteral("customTrackers")).toList());
    // Profiles from v0.2 used two unnamed custom slots. Preserve them as
    // editable named trackers so existing deck configurations still work.
    const QStringList previous = strings(map.value(QStringLiteral("trackers")));
    for (int n=1; n<=2; ++n) {
        const QString id = QStringLiteral("custom_") + QString::number(n);
        bool exists = false;
        for (const auto &custom : d.customTrackers)
            if (custom.toMap().value(QStringLiteral("id")).toString() == id)
                exists = true;
        if (previous.contains(id) && !exists)
            d.customTrackers.append(QVariantMap{
                {QStringLiteral("id"), id},
                {QStringLiteral("label"), QStringLiteral("Custom ") + QString::number(n)}
            });
    }
    d.trackers = uniqueValues(strings(map.value(QStringLiteral("trackers"))));
    d.colors = uniqueValues(strings(map.value(QStringLiteral("colors"))));
    return d;
}

QVariantList DeckStore::allDecks() const {
    QVariantList list;
    for (const auto &d : m_decks)
        list.append(toMap(d));
    return list;
}

QVariantMap DeckStore::deck(const QString &id) const {
    for (const auto &d : m_decks)
        if (d.id == id) return toMap(d);
    return {};
}

void DeckStore::report(const QString &message) {
    m_lastError = message;
    qWarning().noquote() << "MTG Tracker:" << message;
    emit errorOccurred(message);
}

void DeckStore::load() {
    const QString path = m_folder + QStringLiteral("/decks.json");
    if (!QFileInfo::exists(path)) {
        migrateLegacy();
        return;
    }
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        report(QStringLiteral("Unable to open saved deck library: ") + file.errorString());
        return;
    }
    QJsonParseError error;
    const QJsonDocument json = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !json.isObject()) {
        report(QStringLiteral("Invalid deck library; data left untouched: ") + error.errorString());
        return;
    }
    const QJsonArray arr = json.object().value(QStringLiteral("decks")).toArray();
    for (const auto &value : arr) {
        if (!value.isObject()) continue;
        DeckProfile profile = fromMap(value.toObject().toVariantMap());
        if (!profile.id.isEmpty())
            m_decks.push_back(std::move(profile));
    }
}

bool DeckStore::persist() {
    QJsonArray arr;
    for (const auto &d : m_decks) {
        QJsonObject object{
            {QStringLiteral("id"), d.id},
            {QStringLiteral("name"), d.name},
            {QStringLiteral("commander"), d.commander},
            {QStringLiteral("artwork"), d.artwork},
            {QStringLiteral("deckUrl"), d.deckUrl},
            {QStringLiteral("customTrackers"), QJsonArray::fromVariantList(d.customTrackers)}
        };
        QJsonArray trackers;
        for (const auto &tracker : d.trackers) trackers.append(tracker);
        QJsonArray colors;
        for (const auto &color : d.colors) colors.append(color);
        object.insert(QStringLiteral("trackers"), trackers);
        object.insert(QStringLiteral("colors"), colors);
        arr.append(object);
    }
    const QJsonObject root{
        {QStringLiteral("formatVersion"), 1},
        {QStringLiteral("decks"), arr}
    };
    QSaveFile file(m_folder + QStringLiteral("/decks.json"));
    if (!file.open(QIODevice::WriteOnly)) {
        report(QStringLiteral("Unable to save deck library: ") + file.errorString());
        return false;
    }
    if (file.write(QJsonDocument(root).toJson(QJsonDocument::Indented)) < 0) {
        report(QStringLiteral("Unable to write deck library: ") + file.errorString());
        file.cancelWriting();
        return false;
    }
    if (!file.commit()) {
        report(QStringLiteral("Unable to finish saving deck library: ") + file.errorString());
        return false;
    }
    return true;
}

QString DeckStore::saveDeck(const QVariantMap &data) {
    DeckProfile profile = fromMap(data);
    if (profile.name.isEmpty()) {
        report(QStringLiteral("Give your deck a name first."));
        return {};
    }
    if (!profile.deckUrl.isEmpty() && !validatedLink(profile.deckUrl).isValid()) {
        report(QStringLiteral("Deck list URL must begin with https:// or http:// and have a valid host."));
        return {};
    }
    if (profile.id.isEmpty())
        profile.id = QUuid::createUuid().toString(QUuid::WithoutBraces);

    auto it = std::find_if(m_decks.begin(), m_decks.end(),
                           [&profile](const DeckProfile &d) { return d.id == profile.id; });
    beginResetModel();
    if (it == m_decks.end())
        m_decks.push_back(profile);
    else
        *it = profile;
    endResetModel();
    if (!persist()) return {};
    emit decksChanged();
    return profile.id;
}

bool DeckStore::deleteDeck(const QString &id) {
    auto it = std::find_if(m_decks.begin(), m_decks.end(),
                           [&id](const DeckProfile &d) { return d.id == id; });
    if (it == m_decks.end()) return false;
    beginResetModel();
    m_decks.erase(it);
    endResetModel();
    if (!persist()) return false;
    emit decksChanged();
    return true;
}

QString DeckStore::importArtwork(const QUrl &source) {
    if (!source.isLocalFile()) {
        report(QStringLiteral("Select an image saved on this computer."));
        return {};
    }
    const QString filePath = source.toLocalFile();
    const QFileInfo file(filePath);
    if (!file.exists() || file.size() > 25 * 1024 * 1024) {
        report(QStringLiteral("Image is missing or larger than 25 MB."));
        return {};
    }

    QImageReader reader(filePath);
    if (!reader.canRead()) {
        report(QStringLiteral("Unsupported or unreadable image."));
        return {};
    }
    const QString suffix = file.suffix().toLower();
    if (!QStringList{QStringLiteral("png"), QStringLiteral("jpg"), QStringLiteral("jpeg"),
                      QStringLiteral("bmp"), QStringLiteral("gif"), QStringLiteral("webp")}
              .contains(suffix)) {
        report(QStringLiteral("Choose a PNG, JPEG, WEBP, GIF or BMP image."));
        return {};
    }
    const QString destination = m_folder + QStringLiteral("/images/")
        + QUuid::createUuid().toString(QUuid::WithoutBraces)
        + QStringLiteral(".") + suffix;
    if (!QFile::copy(filePath, destination)) {
        report(QStringLiteral("Could not copy artwork to application storage."));
        return {};
    }
    return destination;
}

bool DeckStore::openDeckUrl(const QString &url) {
    const QUrl parsed = validatedLink(url);
    if (!parsed.isValid()) {
        report(QStringLiteral("Enter a valid HTTPS or HTTP deck list URL."));
        return false;
    }
    if (!QDesktopServices::openUrl(parsed)) {
        report(QStringLiteral("Couldn't open the link in your browser."));
        return false;
    }
    return true;
}

QString DeckStore::dataDirectory() const { return m_folder; }

void DeckStore::migrateLegacy() {
#ifdef Q_OS_WIN
    const QString path = m_folder + QStringLiteral("/decks.ini");
    if (!QFileInfo::exists(path)) return;

    auto readIni = [&path](const std::wstring &section, const wchar_t *key) -> QString {
        std::vector<wchar_t> buffer(32768, L'\0');
        const std::wstring iniPath = path.toStdWString();
        GetPrivateProfileStringW(section.c_str(), key, L"",
                                 buffer.data(), DWORD(buffer.size()), iniPath.c_str());
        return QString::fromWCharArray(buffer.data());
    };

    const QStringList ids = readIni(L"decks", L"ids").split(',', Qt::SkipEmptyParts);
    for (const QString &id : ids) {
        const std::wstring section = (QStringLiteral("deck_") + id).toStdWString();
        DeckProfile deck;
        deck.id = id;
        deck.name = readIni(section, L"name");
        deck.commander = readIni(section, L"commander");
        deck.artwork = readIni(section, L"image");
        deck.trackers = readIni(section, L"counters").split(',', Qt::SkipEmptyParts);
        if (deck.name.isEmpty()) deck.name = QStringLiteral("Untitled deck");
        m_decks.push_back(std::move(deck));
    }
    if (!m_decks.empty())
        persist(); // Keep the original .ini as an untouched backup.
#endif
}
