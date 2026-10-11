import QtQuick
import QtQuick.Window

// CPU bench scene, runs until stopped:
//   qml-qt6 -I imports scan-loop.qml -- <idle|scan> /dev/null
// idle: a still window. scan: a card opens on an online peer and closes again
// every 3 s (ServiceScan.active toggles, the same as PeerCard does). On a
// commit without ServiceScan.qml the scene does nothing, so it serves as base.
Window {
    id: root

    visible: true
    width: 400
    height: 300

    readonly property string mode: Qt.application.arguments[Qt.application.arguments.length - 2]
    property var scan: null

    Component.onCompleted: {
        const c = Qt.createComponent("../../components/ServiceScan.qml");
        if (c.status === Component.Ready)
            root.scan = c.createObject(root, {
                "ip": "127.0.0.1"
            });
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.mode === "scan" && root.scan !== null
        onTriggered: root.scan.active = !root.scan.active
    }
}
