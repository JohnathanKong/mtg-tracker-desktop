#pragma once

#include <QObject>
#include <QThread>
#include <QStringList>
#include <QVariantList>

class DeviceSync final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList ports READ ports NOTIFY portsChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
public:
    explicit DeviceSync(QObject *parent = nullptr);
    ~DeviceSync() override;

    QStringList ports() const { return m_ports; }
    bool busy() const { return m_busy; }
    int progress() const { return m_progress; }
    QString status() const { return m_status; }

    Q_INVOKABLE void refreshPorts();
    Q_INVOKABLE void sync(const QString &port, const QVariantList &decks);

signals:
    void portsChanged();
    void busyChanged();
    void progressChanged();
    void statusChanged();
    void syncSucceeded(int count);
    void syncFailed(const QString &reason);

private:
    void updateProgress(int percent, const QString &message);
    void complete(bool success, const QString &detail, int count);
    QStringList m_ports;
    QString m_status = QStringLiteral("Connect the ESP32-S3 over USB to get started.");
    bool m_busy = false;
    int m_progress = 0;
    QThread *m_thread = nullptr;
};
