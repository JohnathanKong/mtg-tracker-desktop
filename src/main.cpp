#include "DeckStore.h"
#include "DeviceSync.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTimer>
#include <QDebug>

int main(int argc, char *argv[]) {
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("MTGTrackerDesktop"));
    app.setOrganizationName(QStringLiteral("MTGTracker"));
    app.setApplicationVersion(QStringLiteral("0.2.0"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    DeckStore store;
    DeviceSync deviceSync;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("deckStore"), &store);
    engine.rootContext()->setContextProperty(QStringLiteral("deviceSync"), &deviceSync);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(2); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "QML root failed to load";
        return 2;
    }

    if (app.arguments().contains(QStringLiteral("--smoke-test"))) {
        QTimer::singleShot(300, &app, [&engine] {
            if (!engine.rootObjects().isEmpty())
                engine.rootObjects().first()->setProperty("page", QStringLiteral("links"));
        });
        QTimer::singleShot(1000, &app, [&app, &engine] {
            auto *root = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().first();
            auto *loader = root ? root->findChild<QObject *>(QStringLiteral("linksLoader")) : nullptr;
            if (!loader || loader->property("item").isNull()) {
                qCritical() << "QML deck links page failed to load";
                app.exit(4);
            } else {
                root->setProperty("page", QStringLiteral("editor"));
            }
        });
        QTimer::singleShot(1500, &app, [&app, &engine] {
            auto *root = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().first();
            if (root) root->setProperty("page", QStringLiteral("device"));
        });
        QTimer::singleShot(2300, &app, [&app, &engine] {
            auto *root = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().first();
            auto *loader = root ? root->findChild<QObject *>(QStringLiteral("deviceLoader")) : nullptr;
            if (!loader || loader->property("item").isNull()) {
                qCritical() << "QML device sync page failed to load";
                app.exit(5);
            } else {
                root->setProperty("page", QStringLiteral("editor"));
            }
        });
        QTimer::singleShot(3400, &app, [&app, &engine] {
            auto *root = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().first();
            auto *loader = root ? root->findChild<QObject *>(QStringLiteral("editorLoader")) : nullptr;
            if (!loader || loader->property("item").isNull()) {
                qCritical() << "QML deck editor failed to load";
                app.exit(3);
            } else {
                app.quit();
            }
        });
    }

    return app.exec();
}
