import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

// The strip above the surface: who is online and the live totals; on the
// right, profile, networks and the offline filter. Connecting is the
// jellyfish's job alone (a click on it; ON/OFF written beside it).
Rectangle {
    id: bar

    property var scene
    property var view
    property var source
    property bool compact: false

    signal networksClicked

    height: 38
    radius: 12
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.55)
    border.width: 1
    border.color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.12)


    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Column {
            anchors.verticalCenter: parent.verticalCenter
            StyledText {
                text: ({
                        "connected": bar.view.online + "/" + bar.view.total + " online",
                        "connecting": "Connecting…",
                        "needsLogin": "Sign-in needed",
                        "stopped": "NetBird is off"
                    })[bar.view.state] || "Disconnected"
                wrapMode: Text.NoWrap
                font.pixelSize: 13
                font.weight: Font.Bold
                color: bar.scene.ink
            }
            StyledText {
                visible: bar.view.state === "connected"
                text: "↓ " + Mesh.fmtRate(bar.view.down) + "  ↑ " + Mesh.fmtRate(bar.view.up)
                wrapMode: Text.NoWrap
                font.pixelSize: 11
                font.family: Theme.monoFontFamily
                color: bar.scene.inkDim
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // In the test lab a flask, so a made-up mesh is never taken for yours
        ActionChip {
            readonly property bool lab: bar.scene.lab
            visible: !!bar.source && bar.source.profiles.length > 1 && !bar.compact
            icon: lab ? "science" : "badge"
            text: bar.source ? bar.source.profile : ""
            ink: bar.scene.ink
            tip: lab ? "Test lab: switch the made-up mesh" : "Switch profile"
            onClicked: {
                const ps = bar.source.profiles;
                bar.source.setProfile(ps[(ps.indexOf(bar.source.profile) + 1) % ps.length]);
            }
        }
        ActionChip {
            visible: !!bar.source && (bar.source.networks.length > 0 || bar.source.exitNode !== "")
            icon: "lan"
            text: bar.source ? bar.source.networks.filter(n => n.on).length + "/" + bar.source.networks.length : ""
            ink: bar.scene.ink
            onClicked: bar.networksClicked()
        }
        ActionChip {
            icon: bar.scene.prefs.showOffline ? "visibility" : "visibility_off"
            checked: !bar.scene.prefs.showOffline
            ink: bar.scene.ink
            onClicked: bar.scene.prefs.set("showOffline", !bar.scene.prefs.showOffline)
        }
    }
}
