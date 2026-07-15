import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: root
    visible: true
    width: 640
    height: 420
    title: qsTr("Qt 6 QML / Quick 3D Smoke Test")

    Quick3DScene {
        anchors.fill: parent
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        text: qsTr("Qt Quick 3D")
        color: "white"
        font.pixelSize: 20
    }
}
