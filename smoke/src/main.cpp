#include "widget_window.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QQmlApplicationEngine>
#include <QTimer>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("qt6_toolchain_smoke"));

    QCommandLineParser parser;
    parser.addHelpOption();
    QCommandLineOption qmlOption(QStringLiteral("qml"), QStringLiteral("Run the QML and Quick 3D smoke scene."));
    parser.addOption(qmlOption);
    parser.process(app);

    if (parser.isSet(qmlOption)) {
        QQmlApplicationEngine engine;
        QObject::connect(
            &engine,
            &QQmlApplicationEngine::objectCreationFailed,
            &app,
            [] { QCoreApplication::exit(2); },
            Qt::QueuedConnection);
        engine.loadFromModule(QStringLiteral("ToolchainSmoke"), QStringLiteral("Main"));
        QTimer::singleShot(3000, &app, &QCoreApplication::quit);
        return app.exec();
    }

    WidgetWindow window;
    window.show();
    QTimer::singleShot(1500, &app, &QCoreApplication::quit);
    return app.exec();
}
