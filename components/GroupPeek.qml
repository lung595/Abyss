import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh
import "Swim.js" as Swim

// An open group: its members spread out large over the blurred deep, on
// rings with the busiest at the top, inside their shoal's ring grown into a
// lit pool (their home). The camera
// glides to it and it blooms out of the shoal into the middle, and folds
// back into it (brief transitions, instant with Reduce motion). The pointer's lamp and lens work here as in the deep; a
// click opens a member's card, a click near them opens the one the lens is on.
Item {
    id: gp

    property var scene
    // Groups.js item; kept while the bubble shrinks back after it closed
    property var item: null
    property bool open: false
    // The shoal it grows out of, and where it settles
    property point from
    property point centre
    property real radius: 120
    // Peer ids (busiest first) and their places around the centre (Layout.ringSpots)
    property var members: []
    property var spots: []

    property var _shown: null
    onItemChanged: {
        if (item)
            _shown = item;
    }

    // 0 = folded into the shoal, 1 = open in the middle: it rides the
    // scene's camera, so the group and the deep behind move as one
    readonly property real grow: scene.camera
    readonly property real _g: Math.min(1, grow)
    readonly property real cx: from.x + (centre.x - from.x) * _g
    readonly property real cy: from.y + (centre.y - from.y) * _g
    // Fewer members, bigger creatures
    readonly property real memberScale: members.length <= 8 ? 0.62 : members.length <= 18 ? 0.5 : 0.42
    readonly property color tint: _shown ? scene.tintOfItem(_shown) : "white"
    readonly property int total: _shown ? _shown.members.length : 0
    readonly property real down: _shown ? _shown.members.reduce((a, id) => {
        const p = scene.peerById[id];
        return a + (p && p.online ? p.down : 0);
    }, 0) : 0

    visible: grow > 0.01

    // Their home: the shoal's ring (School.qml, 22 px) grows with the zoom
    // into a pool round the members, so you are inside the circle you
    // clicked; the deep outside it is darkened by the scene (see its vignette)
    readonly property real homeR: 22 + (radius + 34 - 22) * _g
    readonly property real _fullR: radius + 34

    // The pool's water, lit in the group's colour: painted once at full
    // size, then only scaled (no repaint while the camera moves)
    Halo {
        width: gp._fullR * 2.3
        height: width
        x: gp.cx - width / 2
        y: gp.cy - height / 2
        scale: gp.homeR / gp._fullR
        color: gp.tint
        strength: 0.2
        opacity: gp._g
    }
    // No drawn rim: the scene bends the water round the pool instead
    // (AbyssScene, poolRing)

    // Where a member's creature is drawn, in scene coordinates (the card's
    // flight leaves from here)
    function memberPose(peerId) {
        const i = members.indexOf(peerId), q = spots[i] || {
            "x": 0,
            "y": 0
        };
        const o = scene.offsetOf("m:" + peerId);
        return {
            "x": cx + q.x * grow + o.x,
            "y": cy + q.y * grow + o.y,
            "s": o.s * (0.35 + (memberScale - 0.35) * _g)
        };
    }

    // The pointer's lamp, over the blurred deep (the one in the water is
    // part of the still picture behind)
    Halo {
        readonly property real reach: gp.scene.lensReach * 1.3
        visible: opacity > 0.01
        opacity: gp.scene.lampMix * gp._g
        width: reach * 2
        height: reach * 2
        x: gp.scene.lensX - reach
        y: gp.scene.lensY - reach
        color: gp.scene.ink
        strength: 0.11
    }

    // Near the members, a click opens the one the lens is on (no need to hit
    // the creature itself); further out, the scene's catcher closes the group
    MouseArea {
        width: gp.radius * 2
        height: width
        x: gp.cx - gp.radius
        y: gp.cy - gp.radius
        enabled: gp.open
        cursorShape: gp.scene.focusId.indexOf("m:") === 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (gp.scene.focusId.indexOf("m:") === 0)
                gp.scene.activate(gp.scene.focusId);
        }
    }

    // What the group is, in one line (shown by GroupTitle, at the top)
    readonly property string summary: total + (total === 1 ? " peer" : " peers") + (scene.connected ? "  ·  ↓" + Mesh.fmtShort(down) : "") + (total > members.length ? "  ·  +" + (total - members.length) + " more: type to search" : "")

    Repeater {
        model: gp.members
        Item {
            id: m
            required property int index
            required property string modelData
            readonly property var p: gp.scene.peerById[modelData] || null
            readonly property var spot: gp.spots[index] || {
                "x": 0,
                "y": 0
            }
            readonly property var pose: gp.scene.offsetOf("m:" + modelData)
            readonly property bool focused: gp.scene.focusId === "m:" + modelData
            readonly property bool live: !!p && p.online && gp.scene.connected
            readonly property real glow: live ? 0.15 + 0.85 * Mesh.level(p.down + p.up) : 0.04
            readonly property color tint: p ? gp.scene.tintOf(p.name) : "white"
            readonly property real s: pose.s * (0.35 + (gp.memberScale - 0.35) * gp._g)
            // Names stay readable: all of them for a few members, else the
            // busiest three and the one the lens is on
            // Alive while the group is open (Swim.idle), calmer when asleep
            readonly property var life: gp.scene.peekLive && p ? Swim.idle(p.kind, gp.scene.swim, Swim.seed(modelData), live ? 1 : 0) : Swim.REST
            readonly property bool named: gp.members.length <= 8 || index < 3 || focused
            // Labels sit outward: above for the upper half, below for the lower
            readonly property bool above: spot.y < -4

            visible: !!p
            x: gp.cx + spot.x * gp.grow + pose.x
            y: gp.cy + spot.y * gp.grow + pose.y
            z: focused ? 2 : 0

            Item {
                scale: m.s
                // Hidden while its twin sits on the open card, back in fade as ‹ › steps away (CardHero)
                opacity: m.p ? gp.scene.heroOpacity(m.p.id) : 1

                Halo {
                    width: 110
                    height: 110
                    x: -55
                    y: -55
                    color: m.tint
                    opacity: m.glow
                }
                CreatureShape {
                    x: -48 + m.life.dx
                    y: -48 + m.life.dy
                    kind: m.p ? m.p.kind : "desktop"
                    color: m.live ? Qt.lighter(m.tint, 1.25) : gp.scene.sleepColor
                    glow: m.glow
                    asleep: !m.live
                    transform: [
                        Scale {
                            origin.x: 48
                            origin.y: 48
                            xScale: m.life.f * m.life.sx
                            yScale: m.life.sy
                        },
                        Rotation {
                            origin.x: 48
                            origin.y: 48
                            angle: m.life.a
                        }
                    ]
                }
            }

            Chip {
                id: label
                visible: m.named || m.focused
                opacity: Math.max(0, gp.grow * 2.5 - 1.5)
                x: -width / 2
                y: m.above && !m.focused ? -34 * m.s - height - 2 : 34 * m.s + 2
                title: m.p ? m.p.name : ""
                titleSize: m.focused ? 12 : 11
                sub: !m.focused || !m.p ? "" : !m.p.online ? "offline" : !gp.scene.connected ? "" : "↓" + Mesh.fmtShort(m.p.down) + "  ↑" + Mesh.fmtShort(m.p.up)
                third: m.focused && m.live ? Math.round(m.p.latencyMs) + " ms · " + (m.p.relayed ? "via " + m.p.relay : "direct") : ""
                ink: m.live ? gp.scene.ink : gp.scene.inkDim
                subInk: gp.scene.inkDim
                color: Qt.rgba(gp.scene.abyss.r, gp.scene.abyss.g, gp.scene.abyss.b, m.focused ? 0.85 : 0.5)
            }

            GrabArea {
                x: -30 * Math.max(0.8, m.s)
                y: -30 * Math.max(0.8, m.s)
                width: 60 * Math.max(0.8, m.s)
                height: width
                enabled: gp.open
                scene: gp.scene
                itemId: "m:" + m.modelData
                onTapped: gp.scene.openCard(m.modelData)
            }
        }
    }
}
