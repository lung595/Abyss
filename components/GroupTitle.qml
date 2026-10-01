import QtQuick
import qs.Common
import qs.Widgets

// The name of an open group, at the top of the scene. A group of mine is
// renamed by clicking its name; the small ⚙ beside it opens what can be
// done with the group (the same as its right-click menu).
Item {
    id: title

    property var scene
    // Groups.js group item: {id, label, members, mine}
    property var item: null
    property string sub: ""
    property color tint: "white"
    // 0..1 while the group zooms open
    property real reveal: 0

    readonly property bool mine: !!item && !!item.mine
    readonly property bool hasMenu: !!item && !item.fog

    width: col.width
    height: col.height
    opacity: reveal

    function _below() {
        return title.mapToItem(title.scene, 0, col.height + 4);
    }

    Column {
        id: col
        spacing: 2
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            StyledText {
                id: name
                text: title.item ? title.item.label : ""
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.underline: title.mine && nameArea.containsMouse
                color: title.scene ? title.scene.ink : "white"
                MouseArea {
                    id: nameArea
                    anchors.fill: parent
                    enabled: title.mine && title.reveal > 0.5
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        const at = title._below();
                        title.scene.openMenu(title.item.id, Qt.point(at.x + (title.width - 200) / 2, at.y));
                        title.scene.naming = title.item.mine;
                    }
                }
            }
            StyledText {
                visible: title.hasMenu
                anchors.verticalCenter: name.verticalCenter
                text: "⚙"
                font.pixelSize: 14
                color: title.scene ? (gearArea.containsMouse ? title.scene.ink : title.scene.inkDim) : "white"
                MouseArea {
                    id: gearArea
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: title.reveal > 0.5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const at = title._below();
                        title.scene.openMenu(title.item.id, Qt.point(at.x + (title.width - 200) / 2, at.y));
                    }
                }
            }
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: title.mine && nameArea.containsMouse ? "Click to rename" : title.sub
            font.pixelSize: 11
            color: title.scene ? title.scene.inkDim : "white"
        }
    }
}
