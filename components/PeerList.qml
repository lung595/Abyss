import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

// Every peer as a compact list, for a mesh too big to read as a picture
// (the chip with the list icon in the top bar). Follows what the search
// says and "Show offline peers"; a click opens the peer's card. Sorted as
// the deep sorts them: online first, the closest first. Nothing here runs
// until it is open.
Rectangle {
    id: list

    property var scene

    readonly property var peers: scene.view.peers.filter(p => (p.online || scene.prefs.showOffline) && scene.filters.every(f => f.test(p)))

    radius: 12
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.97)
    border.width: 1
    border.color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.14)
    clip: true

    StyledText {
        id: head
        x: 14
        y: 8
        text: list.peers.length + (list.peers.length === 1 ? " peer" : " peers") + (scene.query !== "" ? " · " + scene.query : "")
        font.pixelSize: 10
        font.letterSpacing: 1
        color: scene.inkDim
    }

    ListView {
        id: rows
        anchors.fill: parent
        anchors.topMargin: 26
        anchors.bottomMargin: 6
        model: list.peers
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        spacing: 1
        delegate: Rectangle {
            id: row
            required property var modelData
            width: rows.width
            height: 28
            radius: 7
            color: area.containsMouse ? Qt.rgba(list.scene.ink.r, list.scene.ink.g, list.scene.ink.b, 0.1) : "transparent"
            opacity: modelData.online ? 1 : 0.5
            readonly property color tint: list.scene.tintOf(modelData.name)

            Rectangle {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: row.modelData.online ? row.tint : "transparent"
                border.width: row.modelData.online ? 0 : 1
                border.color: list.scene.inkDim
            }
            StyledText {
                x: 32
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(60, parent.width * 0.34)
                elide: Text.ElideRight
                text: (list.scene.prefs.isFavorite(row.modelData.id) ? "★ " : "") + row.modelData.name
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: list.scene.ink
            }
            StyledText {
                x: 32 + Math.max(60, parent.width * 0.34) + 6
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.kind
                font.pixelSize: 10
                color: list.scene.inkDim
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                StyledText {
                    visible: row.modelData.online && row.modelData.relayed && !list.scene.compact
                    text: "via " + row.modelData.relay
                    font.pixelSize: 10
                    color: list.scene.inkDim
                }
                StyledText {
                    visible: row.modelData.online && list.scene.connected && !list.scene.compact
                    width: 96
                    horizontalAlignment: Text.AlignRight
                    text: "↓" + Mesh.fmtShort(row.modelData.down) + " ↑" + Mesh.fmtShort(row.modelData.up)
                    font.pixelSize: 10
                    font.family: Theme.monoFontFamily
                    color: list.scene.inkDim
                }
                StyledText {
                    width: 48
                    horizontalAlignment: Text.AlignRight
                    text: row.modelData.online ? Math.round(row.modelData.latencyMs) + " ms" : "offline"
                    font.pixelSize: 11
                    font.family: Theme.monoFontFamily
                    color: row.modelData.online ? list.scene.ink : list.scene.inkDim
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    list.scene.listOpen = false;
                    list.scene.cardId = row.modelData.id;
                }
            }
        }
    }
}
