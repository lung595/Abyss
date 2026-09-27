import QtQuick

// Click or grab, as in Orbit: a short press is a click; past a few pixels the
// item follows the hand, and swims back home when let go (scene.grab/letGo,
// Spring.js). Grabbing an item still on its way home picks it up where it is.
MouseArea {
    id: grab

    property var scene
    property string itemId: ""
    readonly property bool dragging: _dragging

    signal tapped

    property point _from
    property point _base
    property bool _dragging: false

    hoverEnabled: true
    preventStealing: true
    cursorShape: pressed && _dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

    onPressed: mouse => {
        _from = mapToItem(scene, mouse.x, mouse.y);
        const n = scene.nudgeOf(itemId);
        _base = Qt.point(n.x, n.y);
        _dragging = false;
    }
    onPositionChanged: mouse => {
        if (!pressed)
            return;
        // In scene coordinates: the item moves under the hand while dragged
        const p = mapToItem(scene, mouse.x, mouse.y), dx = p.x - _from.x, dy = p.y - _from.y;
        if (!_dragging && Math.hypot(dx, dy) < 6)
            return;
        _dragging = true;
        scene.grab(itemId, _base.x + dx, _base.y + dy);
    }
    onReleased: {
        if (_dragging)
            scene.letGo(itemId);
    }
    onCanceled: {
        scene.letGo(itemId);
        _dragging = false;
    }
    onClicked: {
        if (!_dragging)
            tapped();
        _dragging = false;
    }
}
