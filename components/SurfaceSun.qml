import QtQuick
import qs.Common
import qs.Widgets

// Internet, as the light at the surface. Drag it onto a peer: all your
// Internet traffic then goes out through that peer (its exit node). Rest it
// on a shoal and the group opens (scene.dragOver); leave it on a member, or
// in the middle of a group of yours for the whole group. Drag it back to the
// surface, or anywhere empty, to stop.
Item {
    id: sun

    property var scene
    // Where it rests: above the exit peer, or at the right of the surface
    property point home
    property string label: ""
    readonly property bool dragging: area.drag.active

    // Asks the scene for the peer under a point
    signal dropped(real px, real py)

    width: 44
    height: 44
    // Dragging writes x/y directly; the release puts these bindings back
    x: home.x - width / 2
    y: home.y - height / 2
    z: 20

    Halo {
        width: 110
        height: 110
        anchors.centerIn: parent
        color: sun.scene.sunColor
        strength: 0.8
    }
    Rectangle {
        width: 18
        height: 18
        radius: 9
        anchors.centerIn: parent
        color: Qt.lighter(sun.scene.sunColor, 1.1)
    }
    StyledText {
        anchors.right: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 2
        visible: !sun.dragging && sun.label !== ""
        text: sun.label
        wrapMode: Text.NoWrap
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: sun.scene.ink
    }
    StyledText {
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        visible: sun.dragging
        text: sun.scene.dropHint
        wrapMode: Text.NoWrap
        font.pixelSize: 11
        font.weight: Font.Bold
        color: sun.scene.sunColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: sun
        // Heavy to lift: a brush or a click never carries it away
        drag.threshold: 16
        onPositionChanged: {
            if (drag.active)
                sun.scene.dragOver(sun.x + sun.width / 2, sun.y + sun.height / 2);
        }
        onReleased: {
            if (drag.active)
                sun.dropped(sun.x + sun.width / 2, sun.y + sun.height / 2);
            sun.x = Qt.binding(() => sun.home.x - sun.width / 2);
            sun.y = Qt.binding(() => sun.home.y - sun.height / 2);
        }
    }
}
