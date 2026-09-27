import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh
import "Swim.js" as Swim
import "Layout.js" as Lay

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

    // This group carries your Internet: the light sits in the middle
    readonly property bool lit: open && !!item && !!item.mine && item.mine === scene.prefs.exitGroup && !!scene.exitPeer

    // The light carried over the middle: dropping it here means the whole
    // group, so show it before the drop (a ring where it will rest, faint
    // tentacles to every member)
    readonly property bool aiming: open && scene.aimAll

    // Once dropped, a single pulse runs out to the members (then nothing
    // moves; none with Reduce motion)
    property real pulse: 1
    NumberAnimation {
        id: pulseRun
        target: gp
        property: "pulse"
        from: 0
        to: 1
        duration: 900
        easing.type: Easing.OutCubic
    }
    onLitChanged: {
        if (lit && !scene.reduceMotion)
            pulseRun.restart();
    }

    Rectangle {
        readonly property real r: 24
        x: gp.cx - r
        y: gp.cy - r
        width: r * 2
        height: r * 2
        radius: r
        color: Qt.rgba(gp.scene.sunColor.r, gp.scene.sunColor.g, gp.scene.sunColor.b, 0.08)
        border.width: 1.5
        border.color: Qt.rgba(gp.scene.sunColor.r, gp.scene.sunColor.g, gp.scene.sunColor.b, 0.55)
        opacity: gp.aiming && !gp.lit ? gp._g : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation {
                duration: gp.scene.reduceMotion ? 0 : 150
            }
        }
    }

    // ...tied to every member online, like the jellyfish to its peers: a
    // full line to the one lending the Internet, dashed to those ready to
    // take over. Repainted only when something moves (camera, lens, the
    // one pulse), never by a clock.
    Canvas {
        id: links
        // The pool's square, riding with it (this item has no size of its own)
        width: gp._fullR * 2 + 40
        height: width
        x: gp.cx - width / 2
        y: gp.cy - height / 2
        visible: gp.lit || gp.aiming
        opacity: gp._g
        readonly property var _key: [gp.lit, gp.aiming, gp.pulse, gp.cx, gp.cy, gp.members, gp.scene.poseRev, gp.scene.exitPeer ? gp.scene.exitPeer.id : ""]
        on_KeyChanged: if (visible) requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.reset();
            if (!visible)
                return;
            // Drawn in scene coordinates
            c.translate(-x, -y);
            // Aiming only: every member as a faint dotted promise
            const ghost = !gp.lit;
            const col = gp.scene.sunColor, lend = ghost ? "" : gp.scene.exitPeer.id;
            c.lineCap = "round";
            c.lineJoin = "round";
            gp.members.forEach(id => {
                const p = gp.scene.peerById[id];
                if (!p || !p.online || !p.exit)
                    return;
                const q = gp.memberPose(id), dx = q.x - gp.cx, dy = q.y - gp.cy, L = Math.hypot(dx, dy) || 1;
                // From the light's rim to just short of the creature
                const line = Lay.tentacle([gp.cx + dx / L * 12, gp.cy + dy / L * 12], [q.x - dx / L * 10, q.y - dy / L * 10], null);
                const on = id === lend;
                c.setLineDash(on ? [] : [3, 6]);
                c.beginPath();
                line.forEach((pt, i) => i ? c.lineTo(pt[0], pt[1]) : c.moveTo(pt[0], pt[1]));
                if (on) {
                    c.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.12);
                    c.lineWidth = 6;
                    c.stroke();
                }
                c.strokeStyle = Qt.rgba(col.r, col.g, col.b, on ? 0.85 : ghost ? 0.45 : 0.3);
                c.lineWidth = on ? 2 : 1.2;
                c.stroke();
                // The pulse just after the drop: a bead of light running out
                if (!ghost && gp.pulse < 1) {
                    const pt = line[Math.min(line.length - 1, Math.round(gp.pulse * (line.length - 1)))];
                    c.setLineDash([]);
                    c.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.9 * (1 - gp.pulse * gp.pulse));
                    c.beginPath();
                    c.arc(pt[0], pt[1], 3, 0, Math.PI * 2);
                    c.fill();
                }
            });
        }
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

    // On a member, a click opens it (the lens only counts when the pointer is
    // on the creature); further out, the scene's catcher closes the group
    MouseArea {
        width: gp.radius * 2
        height: width
        x: gp.cx - gp.radius
        y: gp.cy - gp.radius
        enabled: gp.open
        cursorShape: gp.scene.aimedId.indexOf("m:") === 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (gp.scene.aimedId.indexOf("m:") === 0)
                gp.scene.activate(gp.scene.aimedId);
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
            // Steps back while the light is carried if it cannot lend Internet
            opacity: gp.scene.carryFade(p)
            Behavior on opacity {
                NumberAnimation {
                    duration: gp.scene.reduceMotion ? 0 : 150
                }
            }
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
