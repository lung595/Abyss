import QtQuick
import QtQuick.Window
import qs.Common

// CPU bench scene, runs until stopped:
//   qml-qt6 -I imports bench-band.qml -- <none|invite|installing|loop> /dev/null
// none: no band (must equal the base). invite / installing: band held in that
// state. loop: the band cycles its phases every second (one-shot animations).
Window {
    id: root

    visible: true
    width: 600
    height: 400

    readonly property string mode: Qt.application.arguments[Qt.application.arguments.length - 2]
    readonly property var phases: ["idle", "checking", "installing", "installed", "idle"]
    property int step: 0

    QtObject {
        id: fake
        property string phase: root.mode === "installing" ? "installing" : "idle"
        property int step: 2
        property string reason: ""
        property var help: ({})
    }

    Loader {
        active: root.mode !== "none"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        // Resolved at run time so the base revision (no band yet) still runs
        // this scene, drawing nothing: the A/B difference is then the band's cost
        source: Qt.resolvedUrl("../../components/AppInstallBand.qml")
        onLoaded: {
            item.installer = fake;
            item.deviceName = "demo-laptop";
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.mode === "loop"
        onTriggered: fake.phase = root.phases[++root.step % root.phases.length]
    }
}
