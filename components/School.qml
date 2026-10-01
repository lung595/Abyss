import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

// A group of peers (Groups.js): a small shoal with one short label. Resting
// the pointer on it (or a click) opens it as a bubble (GroupPeek), so the
// shoal itself stays simple. Two special shoals: the asleep ones (grey, on
// the floor) and the fog (what a search left out: blurred and dim, never in
// the way).
Item {
    id: sc

    property var scene
    // Groups.js item: {id, label, members: [ids], asleep, fog}
    property var item
    property point spot
    property color tint: "white"
    property real phase: 0

    // Busiest first: they sit at the heart of the spiral
    readonly property var peers: item.members.map(id => scene.peerById[id]).filter(p => !!p).sort((a, b) => (b.down + b.up) - (a.down + a.up))
    readonly property real down: peers.reduce((a, p) => a + (p.online ? p.down : 0), 0)
    readonly property bool broken: peers.some(p => scene.isBroken(p))
    readonly property bool quiet: !!item.asleep || !!item.fog
    readonly property bool focused: !quiet && scene.focusId === item.id
    // Lens spring and grab: offset and scale from its place (AbyssScene.offsetOf)
    readonly property var pose: scene.offsetOf(item.id)

    // Its members are in the open bubble
    visible: scene.peekId !== item.id
    x: spot.x
    y: spot.y
    z: focused ? 2 : 0
    // No Behavior on x/y: a move is a swim trip (AbyssScene, Swim.js), in pose

    Item {
        id: body
        x: sc.pose.x
        y: sc.pose.y
        scale: sc.pose.s

        // The fog is drawn blurred once, then only redrawn if its members change
        layer.enabled: sc.item.fog === true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.7
            blurMax: 20
        }
        opacity: sc.item.fog ? 0.32 : 1

        Rectangle {
            visible: !sc.item.fog
            width: 44
            height: 44
            radius: 22
            x: -22
            y: -22
            color: "transparent"
            border.width: 1
            border.color: sc.broken ? Theme.warning : Qt.rgba(sc.tint.r, sc.tint.g, sc.tint.b, sc.item.asleep ? 0.12 : sc.focused ? 0.5 : 0.24)
        }

        // Members: a tight spiral that turns slowly while the deep flows
        Repeater {
            model: Math.min(sc.peers.length, 12)
            Item {
                required property int index
                readonly property var p: sc.peers[index]
                readonly property real a: index * 2.4 + (sc.quiet || !sc.scene.flowing ? 0 : sc.scene.t * 0.25 + sc.phase)
                readonly property real r: 3 + Math.sqrt(index) * 5.5
                x: Math.cos(a) * r
                y: Math.sin(a) * r * 0.65

                Halo {
                    visible: !sc.quiet
                    width: 24
                    height: width
                    x: -width / 2
                    y: -width / 2
                    color: sc.scene.isBroken(p) ? Theme.warning : sc.scene.tintOf(p.name)
                    opacity: 0.2 + 0.6 * Mesh.level(p.down + p.up)
                }
                CreatureShape {
                    x: -48
                    y: -48
                    kind: p.kind
                    color: p.online && !sc.item.asleep ? Qt.lighter(sc.scene.tintOf(p.name), 1.25) : sc.scene.sleepColor
                    glow: 0.3
                    asleep: !p.online
                    scale: 0.3
                }
            }
        }
    }

    // Internet goes out through one of its members: a small still sun
    // beside its label, so a closed group says it lends
    readonly property bool lending: !!sc.scene.exitPeer && sc.item.members.indexOf(sc.scene.exitPeer.id) >= 0
    SunGlyph {
        visible: sc.lending && !sc.scene._carrying
        spinning: false
        color: sc.scene.sunColor
        x: label.x - width - 3
        y: label.y + (label.height - height) / 2
    }

    // One short line: what the group is, and what it pulls
    Chip {
        id: label
        x: body.x - width / 2
        y: body.y + (sc.quiet ? 22 : 28) * body.scale
        title: sc.item.label
        titleSize: sc.item.fog ? 10 : 11
        sub: sc.item.dozing ? "wake on use" : sc.quiet ? "" : "↓" + Mesh.fmtShort(sc.down) + (sc.broken ? "  ⚠" : "")
        ink: sc.quiet ? sc.scene.inkDim : sc.scene.ink
        subInk: sc.broken ? Theme.warning : sc.scene.inkDim
        color: Qt.rgba(sc.scene.abyss.r, sc.scene.abyss.g, sc.scene.abyss.b, sc.quiet ? 0.25 : 0.45)
    }

    GrabArea {
        x: body.x - 44
        y: body.y - 40
        width: 88
        height: 96
        scene: sc.scene
        itemId: sc.item.id
        onTapped: sc.scene.activate(sc.item.id)
    }
}
