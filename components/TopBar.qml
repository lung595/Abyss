import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

// The strip above the surface: connection switch, who is online and the
// live totals; on the right, profile, networks and the offline filter.
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

    readonly property bool on: view.state === "connected" || view.state === "connecting"

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // The connection switch
        Rectangle {
            width: 36
            height: 22
            radius: 11
            anchors.verticalCenter: parent.verticalCenter
            color: bar.on ? Theme.primary : Qt.rgba(bar.scene.ink.r, bar.scene.ink.g, bar.scene.ink.b, 0.2)
            Rectangle {
                width: 16
                height: 16
                radius: 8
                y: 3
                x: bar.on ? 17 : 3
                color: bar.on ? Theme.primaryText : bar.scene.ink
                Behavior on x {
                    NumberAnimation {
                        duration: 160
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (bar.source)
                        bar.source.toggle();
                }
            }
        }
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
