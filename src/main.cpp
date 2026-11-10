#include "DeckStore.h"

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
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("deckStore"), &store);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(2); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "QML root failed to load";
        return 2;
    }

    if (app.arguments().contains(QStringLiteral("--smoke-test"))) {
        QTimer::singleShot(2500, &app, &QCoreApplication::quit);
    }

    return app.exec();
}
