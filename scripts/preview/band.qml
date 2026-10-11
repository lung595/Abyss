import QtQuick
import QtQuick.Window
import qs.Common
import "../../components"

// The install band with a made-up installer, in a plain window.
//   qml-qt6 -I imports band.qml -- <hold|shot-PHASE[-light]> <out.png>
// hold: the states cycle every 2.5 s and the window stays open (safe try).
// shot-PHASE: one frame of that phase written to <out.png>, then exit.
Window {
    id: root

    readonly property string mode: Qt.application.arguments[Qt.application.arguments.length - 2]
    readonly property string out: Qt.application.arguments[Qt.application.arguments.length - 1]
    readonly property bool shot: mode.indexOf("shot-") === 0
    readonly property var phases: ["idle", "checking", "installing", "installed", "failed", "missing"]
    property int index: 0

    visible: true
    width: 400
    height: 420
    color: Theme.surface

    QtObject {
        id: fake
        property string phase: root.shot ? root.mode.split("-")[1] : "idle"
        property int step: phase === "checking" ? 1 : 2
        property string reason: "~/.local/bin is not writable. Nothing was changed."
        property var help: ({
                "name": "Fedora",
                "command": "sudo dnf install quickshell",
                "anchor": "quickshell-is-missing"
            })
        function install() {
            fake.phase = "installing";
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    AppInstallBand {
        installer: fake
        action: "send"
        deviceName: "demo-laptop"
        reduceMotion: root.shot
    }

    Timer {
        interval: 2500
        repeat: true
        running: !root.shot
        onTriggered: fake.phase = root.phases[++root.index % root.phases.length]
    }
    Timer {
        interval: 600
        running: root.shot
        onTriggered: root.contentItem.grabToImage(function (r) {
            r.saveToFile(root.out);
            Qt.quit();
        })
    }
}
