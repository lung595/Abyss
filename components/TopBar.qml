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

    // Where the search field sits, for the panel under it
    readonly property real searchX: search.x
    readonly property real searchW: search.width

    signal networksClicked
    signal listClicked

    height: 38
    radius: 12
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.55)
    border.width: 1
    border.color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.12)


    Row {
        id: status
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

    // Search: always there, in the middle. Typing anywhere in the deep
    // writes here too; it finds devices, and commands ("add", "share"…)
    Rectangle {
        id: search
        anchors.left: status.right
        anchors.leftMargin: 12
        anchors.right: actions.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        radius: 14
        readonly property bool on: field.activeFocus
        color: Qt.rgba(bar.scene.ink.r, bar.scene.ink.g, bar.scene.ink.b, on ? 0.12 : hover.containsMouse ? 0.09 : 0.06)
        border.width: on ? 1.5 : 1
        border.color: on ? bar.scene.sunColor : Qt.rgba(bar.scene.ink.r, bar.scene.ink.g, bar.scene.ink.b, 0.14)
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            onClicked: field.forceActiveFocus()
        }
        DankIcon {
            id: lens
            x: 9
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: 16
            color: search.on ? bar.scene.sunColor : bar.scene.inkDim
        }
        TextInput {
            id: field
            anchors.left: lens.right
            anchors.leftMargin: 6
            anchors.right: clear.visible ? clear.left : parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: bar.scene.query
            font.pixelSize: 12
            color: bar.scene.ink
            selectByMouse: true
            clip: true
            onTextEdited: bar.scene.query = text.toLowerCase()
            onActiveFocusChanged: bar.scene.searchFocus = activeFocus
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (bar.scene.query !== "")
                        bar.scene.query = "";
                    else
                        bar.scene.forceActiveFocus();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    bar.scene.searchEnter();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down && bar.scene.query === "") {
                    bar.scene.forceActiveFocus();
                    event.accepted = true;
                }
            }
        }
        StyledText {
            anchors.left: field.left
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: field.text === ""
            text: bar.compact || search.width < 190 ? "Search" : "Search devices or type a command"
            font.pixelSize: 12
            color: bar.scene.inkDim
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
        // How many it finds, and a way out
        Row {
            id: clear
            visible: bar.scene.query !== ""
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: search.width > 150
                text: bar.scene.arr.hits ? bar.scene.arr.hits + "" : "0"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: bar.scene.arr.hits ? bar.scene.sunColor : Theme.warning
            }
            ActionChip {
                height: 20
                icon: "close"
                ink: bar.scene.ink
                tip: "Clear (Esc)"
                onClicked: {
                    bar.scene.query = "";
                    field.forceActiveFocus();
                }
            }
        }
    }

    Row {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Add a device: this computer or a phone, step by step
        ActionChip {
            icon: "add"
            primary: true
            accent: bar.scene.sunColor
            ink: bar.scene.ink
            tip: "Add a device"
            onClicked: bar.scene.openAdd()
        }
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
        // A big mesh as a list, not only as a picture
        ActionChip {
            visible: bar.scene.listWanted
            icon: "view_list"
            checked: bar.scene.listOpen
            ink: bar.scene.ink
            tip: "All peers as a list"
            onClicked: bar.listClicked()
        }
        ActionChip {
            icon: bar.scene.prefs.showOffline ? "visibility" : "visibility_off"
            checked: !bar.scene.prefs.showOffline
            ink: bar.scene.ink
            onClicked: bar.scene.prefs.set("showOffline", !bar.scene.prefs.showOffline)
        }
    }
}
