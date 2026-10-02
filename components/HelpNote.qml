import QtQuick
import qs.Common
import qs.Widgets

// Shown when something you tried cannot be done: never a silent refusal.
// One short line says why, a second what to do, and the GitHub mark opens
// the README section that explains it (in your browser, on click only; the
// plugin itself never goes online). It fades away after a few seconds, or
// stays while the pointer rests on it so the link can be reached.
Rectangle {
    id: note

    property var scene
    // { title, hint, anchor, x, y }: set by scene.explain(), null when gone
    readonly property var info: scene.note

    // The user guide the link opens (the README only installs); the anchor
    // picks the section
    readonly property string readme: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#"

    visible: opacity > 0.01
    opacity: info ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: note.scene.reduceMotion ? 0 : 150
        }
    }
    width: row.implicitWidth + 20
    height: row.implicitHeight + 14
    // Under what was refused, kept inside the view
    x: info ? Math.max(6, Math.min(scene.width - width - 6, info.x - width / 2)) : x
    y: info ? Math.max(6, Math.min(scene.height - height - 6, info.y)) : y
    z: 45
    radius: 10
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.96)
    border.width: 1
    border.color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.14)

    // Only runs while a note is shown, and waits while it is pointed at
    Timer {
        running: !!note.info && !hover.hovered
        interval: 4000
        onTriggered: note.scene.note = null
    }
    HoverHandler {
        id: hover
    }

    Row {
        id: row
        x: 10
        y: 7
        spacing: 10
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            StyledText {
                text: note.info ? note.info.title : ""
                font.pixelSize: 12
                font.weight: Font.Bold
                color: note.scene.ink
            }
            StyledText {
                text: note.info ? note.info.hint : ""
                font.pixelSize: 11
                color: note.scene.inkDim
            }
        }
        // The way to the explanation
        Item {
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            GitHubMark {
                anchors.centerIn: parent
                size: 16
                color: link.containsMouse ? Theme.primary : note.scene.inkDim
            }
            MouseArea {
                id: link
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Qt.openUrlExternally(note.readme + (note.info ? note.info.anchor : ""));
                    note.scene.note = null;
                }
            }
        }
    }
}
