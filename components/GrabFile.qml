import QtQuick
import qs.Common
import qs.Widgets
import "GrabMotion.js" as Motion

// The "grab the file" scene: a file appears, the creature's tentacle reaches
// it, carries it over and the file drops in. It is the one scene for every
// way of sending (the menu, Ctrl+V, the launcher), so they all look
// the same; play() starts it and landed() says it is over, when the send's
// own progress takes over. A Timer at 30 Hz runs it, only while it plays: a
// QML animation would redraw the whole shell for these 0.9 seconds.
Item {
    id: grab

    property var scene
    property bool running: false
    property point from: Qt.point(0, 0)
    property point to: Qt.point(0, 0)
    property int count: 1
    property color tint: Theme.primary

    signal landed

    property double _t0: 0
    // 0..1 over Motion.DURATION
    property real _k: 0
    readonly property var pose: Motion.pose(grab._k, grab.from, grab.to)
    readonly property var tip: Motion.tip(grab.to, Qt.point(grab.pose.x, grab.pose.y), grab.pose.reach)

    visible: grab.running
    anchors.fill: parent

    function play(from, to, count, tint) {
        grab.from = from;
        grab.to = to;
        grab.count = count;
        grab.tint = tint;
        grab._k = 0;
        grab._t0 = Date.now();
        grab.running = true;
    }

    // Gone at once (the view closes, or the send already ended)
    function stop() {
        grab.running = false;
    }

    Timer {
        interval: 33
        repeat: true
        running: grab.running
        onTriggered: {
            const k = (Date.now() - grab._t0) / Motion.DURATION;
            if (k < 1) {
                grab._k = k;
                return;
            }
            grab.running = false;
            grab.landed();
        }
    }

    // The tentacle: a line of light from the creature to the file
    Rectangle {
        readonly property real dx: grab.tip.x - grab.to.x
        readonly property real dy: grab.tip.y - grab.to.y
        x: grab.to.x
        y: grab.to.y - height / 2
        width: Math.hypot(dx, dy)
        height: 3
        radius: 1.5
        transformOrigin: Item.Left
        rotation: Math.atan2(dy, dx) * 180 / Math.PI
        color: grab.tint
        opacity: 0.85 * Math.min(1, grab.pose.reach * 3)
    }

    // The file, as a tile with its count when there are several
    Rectangle {
        x: grab.pose.x - width / 2
        y: grab.pose.y - height / 2
        width: 44
        height: 52
        radius: 8
        scale: grab.pose.scale
        opacity: grab.pose.opacity
        color: Qt.rgba(grab.scene.abyss.r, grab.scene.abyss.g, grab.scene.abyss.b, 0.92)
        border.width: 1.5
        border.color: grab.tint

        DankIcon {
            anchors.centerIn: parent
            name: grab.count > 1 ? "file_copy" : "description"
            size: 24
            color: grab.scene.ink
        }
        StyledText {
            visible: grab.count > 1
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            text: grab.count
            font.pixelSize: 10
            font.weight: Font.Bold
            color: grab.tint
        }
    }
}
