import QtQuick
import qs.Common
import qs.Widgets
import "Commands.js" as Commands

// The panel under the search bar. Empty search: one-click shortcuts to what
// people look for (Phones, Slow…). Typing: the commands its words find
// ("add" → Add a device). Devices themselves are found in the deep, which
// fogs what the search leaves out.
Rectangle {
    id: panel

    property var scene

    readonly property bool hints: scene.searchFocus && scene.query === "" && scene.prefs.searchHints
    readonly property bool cmds: scene.query !== "" && scene.commands.length > 0 && (scene.searchFocus || scene.arr.hits === 0)
    visible: opacity > 0.01
    opacity: (hints || cmds) && scene.cardId === "" ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: scene.reduceMotion ? 0 : 140
        }
    }
    height: col.implicitHeight + 16
    radius: 14
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.96)
    border.width: 1
    border.color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.16)

    // Keep clicks here
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: col
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 6

        StyledText {
            x: 4
            visible: panel.hints
            text: "FIND"
            font.pixelSize: 9
            font.letterSpacing: 1.2
            font.weight: Font.Bold
            color: panel.scene.inkDim
        }
        Flow {
            visible: panel.hints
            width: parent.width
            spacing: 5
            Repeater {
                model: Commands.SUGGESTIONS
                ActionChip {
                    required property var modelData
                    height: 26
                    icon: modelData.icon
                    text: modelData.text
                    ink: panel.scene.ink
                    onClicked: panel.scene.query = modelData.q
                }
            }
        }
        StyledText {
            x: 4
            visible: panel.hints
            width: parent.width - 8
            text: "Or type a name, >100ms, or a command: add, share, disconnect"
            font.pixelSize: 10
            color: panel.scene.inkDim
            wrapMode: Text.WordWrap
        }

        StyledText {
            x: 4
            visible: panel.cmds
            text: "ACTIONS"
            font.pixelSize: 9
            font.letterSpacing: 1.2
            font.weight: Font.Bold
            color: panel.scene.inkDim
        }
        Repeater {
            model: panel.cmds ? panel.scene.commands : []
            Rectangle {
                id: row
                required property var modelData
                required property int index
                width: col.width
                height: 40
                radius: 10
                readonly property bool first: index === 0 && panel.scene.arr.hits === 0
                color: area.containsMouse ? Qt.rgba(panel.scene.sunColor.r, panel.scene.sunColor.g, panel.scene.sunColor.b, 0.18) : first ? Qt.rgba(panel.scene.ink.r, panel.scene.ink.g, panel.scene.ink.b, 0.08) : "transparent"
                DankIcon {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    name: row.modelData.icon
                    size: 18
                    color: panel.scene.sunColor
                }
                Column {
                    x: 38
                    width: parent.width - (row.first ? 100 : 48)
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText {
                        width: parent.width
                        text: row.modelData.text
                        wrapMode: Text.NoWrap
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: panel.scene.ink
                        elide: Text.ElideRight
                    }
                    StyledText {
                        visible: text !== ""
                        width: parent.width
                        text: row.modelData.sub
                        wrapMode: Text.NoWrap
                        font.pixelSize: 10
                        color: panel.scene.inkDim
                        elide: Text.ElideRight
                    }
                }
                StyledText {
                    visible: row.first
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter ↵"
                    font.pixelSize: 10
                    font.family: Theme.monoFontFamily
                    color: panel.scene.inkDim
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.scene.runCommand(row.modelData.act)
                }
            }
        }
    }
}
