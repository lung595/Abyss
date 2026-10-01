import QtQuick
import qs.Common
import qs.Widgets

// Shortcuts to the starred devices, along the bottom of the Control
// Center's deep: each one opens its card, its terminal or its files in one
// click. With no star yet, one line says how to get some.
Rectangle {
    id: favs

    property var scene

    readonly property var peers: scene.view.peers.filter(p => scene.prefs.isFavorite(p.id))
    readonly property real chipW: Math.min(220, Math.max(150, (width - 12 - 6 * (peers.length - 1)) / Math.max(1, peers.length)))

    height: 44
    radius: 14
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.82)
    border.width: 1
    border.color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.12)

    StyledText {
        visible: favs.peers.length === 0
        anchors.centerIn: parent
        width: parent.width - 24
        horizontalAlignment: Text.AlignHCenter
        text: "★  Star a device on its card: it gets a shortcut here"
        font.pixelSize: 11
        color: favs.scene.inkDim
        elide: Text.ElideRight
    }

    Flickable {
        visible: favs.peers.length > 0
        anchors.fill: parent
        anchors.margins: 6
        contentWidth: row.implicitWidth
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        Row {
            id: row
            spacing: 6
            Repeater {
                model: favs.peers
                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool live: modelData.online && favs.scene.connected
                    width: favs.chipW
                    height: 32
                    radius: 10
                    color: area.containsMouse ? Qt.rgba(favs.scene.ink.r, favs.scene.ink.g, favs.scene.ink.b, 0.12) : Qt.rgba(favs.scene.ink.r, favs.scene.ink.g, favs.scene.ink.b, 0.06)
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: favs.scene.openCard(chip.modelData.id)
                    }
                    Rectangle {
                        x: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: chip.live ? Theme.success : favs.scene.inkDim
                    }
                    StyledText {
                        x: 22
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 22 - actions.width - 6
                        text: chip.modelData.name
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: chip.live ? favs.scene.ink : favs.scene.inkDim
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Row {
                        id: actions
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        opacity: chip.live ? 1 : 0.35
                        ActionChip {
                            height: 26
                            icon: "terminal"
                            tip: "Terminal"
                            ink: favs.scene.ink
                            onClicked: chip.live && favs.scene.ssh(chip.modelData)
                        }
                        ActionChip {
                            height: 26
                            icon: "folder_open"
                            tip: "Files"
                            ink: favs.scene.ink
                            onClicked: chip.live && favs.scene.reach("files", chip.modelData)
                        }
                    }
                }
            }
        }
    }
}
