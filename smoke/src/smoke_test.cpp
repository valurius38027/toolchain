#include <QScopedPointer>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QtTest>

class ToolchainSmokeTest final : public QObject
{
    Q_OBJECT

private slots:
    void qtVersionIsAvailable()
    {
        QVERIFY2(QString::fromLatin1(qVersion()).startsWith(QStringLiteral("6.")), qVersion());
    }

    void quick3DModuleLoads()
    {
        QQmlEngine engine;
        QQmlComponent component(&engine);
        component.setData("import QtQuick3D\nNode {}", QUrl(QStringLiteral("inmemory:Quick3DProbe.qml")));
        QScopedPointer<QObject> object(component.create());
        QVERIFY2(object, qPrintable(component.errorString()));
    }
};

QTEST_MAIN(ToolchainSmokeTest)
#include "smoke_test.moc"
