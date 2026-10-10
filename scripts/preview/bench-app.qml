import QtQuick
import QtQuick.Window
import "../../app/views"

// CPU bench scene, runs until stopped:
//   qml-qt6 -I tests/scene/imports scripts/preview/bench-app.qml -- <idle|switch> /dev/null
// idle: window open and still. switch: a station change every second, the
// same call a gauge click makes (the dive animation runs each time).
Window {
    id: root

    visible: true
    width: 1280
    height: 800

    readonly property string mode: Qt.application.arguments[Qt.application.arguments.length - 2]
    readonly property var order: ["map", "send", "settings", "send"]
    property int step: 0

    AppFrame {
        id: frame

        anchors.fill: parent
        netbirdState: "connected"
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.mode === "switch"
        onTriggered: frame.show(root.order[++root.step % root.order.length])
    }
}
