#pragma once

#include <QAbstractListModel>
#include <QJsonObject>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>
#include <vector>

struct DeckProfile {
    QString id;
    QString name;
    QString commander;
    QString artwork;
    QString deckUrl;
    QVariantList customTrackers;
    QStringList trackers;
    QStringList colors;
};

class DeckStore final : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY decksChanged)
public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        CommanderRole,
        ArtworkRole,
        TrackerCountRole,
        ColorsRole
    };

    explicit DeckStore(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const;

    Q_INVOKABLE QVariantList allDecks() const;
    Q_INVOKABLE QVariantMap deck(const QString &id) const;
    Q_INVOKABLE QString saveDeck(const QVariantMap &profile);
    Q_INVOKABLE bool deleteDeck(const QString &id);
    Q_INVOKABLE QString importArtwork(const QUrl &source);
    Q_INVOKABLE bool openDeckUrl(const QString &url);
    Q_INVOKABLE QString dataDirectory() const;
    Q_INVOKABLE QString lastError() const { return m_lastError; }

signals:
    void decksChanged();
    void errorOccurred(const QString &message);

private:
    std::vector<DeckProfile> m_decks;
    QString m_folder;
    QString m_lastError;

    static QVariantMap toMap(const DeckProfile &deck);
    static DeckProfile fromMap(const QVariantMap &map);
    void load();
    bool persist();
    void migrateLegacy();
    void report(const QString &message);
};
