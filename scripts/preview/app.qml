import QtQuick
import QtQuick.Window
import "../../app/views"

// The app window content with fictitious state, saved as a PNG:
//   scripts/preview/app.sh <dark|light> <station> <out.png> [compact] [state]
Window {
    id: root

    visible: true
    // "compact" renders the 900 x 600 minimum
    readonly property bool compact: Qt.application.arguments[Qt.application.arguments.length - 4] === "compact"

    // connected | stopped | missing | unknown, or "longname": an unknown device
    readonly property string scene: Qt.application.arguments[Qt.application.arguments.length - 5]

    width: compact ? 900 : 1280
    height: compact ? 600 : 800

    AppFrame {
        id: frame

        anchors.fill: parent
        station: Qt.application.arguments[Qt.application.arguments.length - 3]
        netbirdState: ["stopped", "missing", "unknown"].includes(root.scene) ? root.scene : "connected"
        device: root.scene === "longname" ? "workstation-with-a-very-long-device-name.netbird.cloud" : ""
        peers: root.scene === "longname" ? [] : [
            { id: "p1", name: "laptop-anna", fqdn: "laptop-anna.netbird.cloud", ip: "100.64.0.11", online: true },
            { id: "p2", name: "nas-box", fqdn: "nas-box.netbird.cloud", ip: "100.64.0.12", online: true },
            { id: "p3", name: "phone-tab", fqdn: "phone-tab.netbird.cloud", ip: "100.64.0.13", online: false }
        ]
    }

    Timer {
        interval: 400
        running: true
        onTriggered: frame.grabToImage(r => {
            r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 2]);
            Qt.quit();
        })
    }
}
