import QtQuick
import qs.Common
import qs.Widgets

// Internet, as the light at the surface. Drag it onto a peer: all your
// Internet traffic then goes out through that peer (its exit node). Rest it
// on a shoal and the group opens (scene.dragOver); leave it on a member, or
// in the middle of a group of yours for the whole group. Drag it back to the
// surface, or anywhere empty, to stop. A click lists where it can go;
// Escape while carrying puts it back.
Item {
    id: sun

    property var scene
    // Where it rests: above the exit peer, or at the right of the surface
    property point home
    property string label: ""
    // What goes through the beam now ("↓ 9.5 Mb/s  ↑ 1.2 Mb/s"), "" when nothing
    property string rates: ""
    readonly property bool dragging: area.drag.active
    property bool reduceMotion: false
    // Where it is drawn: `home`, but a new home (an exit picked from the
    // menu, a drop, Escape) is reached by gliding there in 0.6 s instead of
    // jumping. Small moves (its peer swimming) are followed at once.
    property point shown: home
    readonly property bool gliding: glide.running

    // Asks the scene for the peer under a point
    signal dropped(real px, real py)

    width: 44
    height: 44
    // Dragging writes x/y directly; the release puts these bindings back
    x: shown.x - width / 2
    y: shown.y - height / 2
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
    Column {
        // Left of the light, or right of it when the edge is too near
        id: words
        objectName: "sunWords"
        readonly property bool onRight: sun.x - implicitWidth - 2 < 4
        x: onRight ? sun.width + 2 : -implicitWidth - 2
        // The name level with the light, the traffic hanging under it
        y: (sun.height - title.implicitHeight) / 2
        visible: !sun.dragging && sun.label !== ""
        StyledText {
            id: title
            x: words.onRight ? 0 : words.width - implicitWidth
            text: sun.label
            wrapMode: Text.NoWrap
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: sun.scene.ink
        }
        StyledText {
            x: words.onRight ? 0 : words.width - implicitWidth
            visible: sun.rates !== ""
            text: sun.rates
            wrapMode: Text.NoWrap
            font.pixelSize: 10
            font.family: Theme.monoFontFamily
            color: sun.scene.inkDim
        }
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

    // The glide: a Timer at 60 Hz rather than an animation, so only this
    // window redraws (P40), and only for the 0.6 s of the trip. It aims at
    // the live home, which may still move while it travels.
    property point _from
    property real _t0: 0
    // A refused drop comes back with a little bounce past its place
    property bool _bounce: false
    function glideFrom(px, py, bounce) {
        _bounce = !!bounce;
        _from = Qt.point(px, py);
        _t0 = Date.now();
        if (reduceMotion || Math.hypot(home.x - px, home.y - py) < 2) {
            glide.stop();
            shown = Qt.binding(() => sun.home);
        } else {
            shown = _from;
            glide.start();
        }
    }
    function _settle() {
        sun.x = Qt.binding(() => sun.shown.x - sun.width / 2);
        sun.y = Qt.binding(() => sun.shown.y - sun.height / 2);
    }
    property point _last: home
    onHomeChanged: {
        // A far move, even halfway through a trip: set off again from
        // where it is, so it never jumps
        const far = Math.hypot(home.x - _last.x, home.y - _last.y) > 24;
        if (far && !dragging)
            glide.running ? glideFrom(shown.x, shown.y) : glideFrom(_last.x, _last.y);
        _last = home;
    }
    Timer {
        id: glide
        interval: 16
        repeat: true
        onTriggered: {
            const k = Math.min(1, (Date.now() - sun._t0) / 600);
            // Ease in and out: sets off gently, lands softly. Refused: sets
            // off at once and overshoots a little before settling (ease out back)
            const c = 1.4;
            const e = sun._bounce ? 1 + (c + 1) * Math.pow(k - 1, 3) + c * Math.pow(k - 1, 2) : k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2;
            sun.shown = Qt.point(sun._from.x + (sun.home.x - sun._from.x) * e, sun._from.y + (sun.home.y - sun._from.y) * e);
            if (k >= 1) {
                stop();
                sun.shown = Qt.binding(() => sun.home);
            }
        }
    }

    Connections {
        target: sun.scene
        function onCarryCancelled() {
            area.cancelled = true;
            sun.glideFrom(sun.x + sun.width / 2, sun.y + sun.height / 2);
            sun._settle();
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: sun.scene.sunHovered = containsMouse
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: cancelled ? null : sun
        // Heavy to lift: a brush or a click never carries it away
        drag.threshold: 16
        // Escape (AbyssScene.cancelCarry): let go without dropping
        property bool cancelled: false
        onPressed: cancelled = false
        // A click, no drag: where Internet can go, as a list
        onClicked: sun.scene.openMenu("sun", Qt.point(sun.x - 160, sun.y + sun.height))
        onPositionChanged: {
            if (drag.active && !cancelled)
                sun.scene.dragOver(sun.x + sun.width / 2, sun.y + sun.height / 2);
        }
        onReleased: {
            const wasDragged = drag.active;
            if (drag.active && !cancelled)
                sun.dropped(sun.x + sun.width / 2, sun.y + sun.height / 2);
            // From where it was let go back up to its (maybe new) home
            if (wasDragged)
                sun.glideFrom(sun.x + sun.width / 2, sun.y + sun.height / 2, sun.scene.sunRefused);
            sun._settle();
        }
    }
}
