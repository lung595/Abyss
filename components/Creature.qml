import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh
import "Swim.js" as Swim

// One peer in the deep: its creature, its glow (traffic) and its label with
// live rates. The item's origin is the creature's centre.
Item {
    id: cr

    property var scene
    property var peer
    property point spot
    property bool onFloor: false
    property color tint: "white"
    property bool isTop: false
    property bool favorite: false
    property bool muted: false
    property bool highlighted: false
    property bool hovered: area.containsMouse
    property real phase: 0
    // The Groups.js item this peer stands for ("p:<id>")
    property string itemId: ""

    // Details only where the eye needs them: the top consumer, the peer
    // under the pointer and the one whose card is open or was found.
    // Everyone else shows a quiet name; the tentacle already tells its traffic.
    readonly property bool detailed: cr.isTop || cr.hovered || cr.highlighted || cr.focused || cr.broken
    readonly property bool focused: scene.focusId !== "" && scene.focusId === itemId
    readonly property bool broken: scene.isBroken(peer)
    // Lens spring and grab: offset and scale from its place (the item itself
    // keeps its place, so a regroup still eases while the lens swings)
    readonly property var pose: scene.offsetOf(itemId)

    // 0 asleep .. 1 awake: the light reaches it from the jellyfish (wave)
    readonly property real wake: scene.wakeAt(spot.x, spot.y)
    readonly property bool live: peer.online && wake > 0.05
    readonly property real glow: scene.glowOf(peer, wake)
    // Floats while someone watches, barely asleep; an offset on a child, never animated
    // Its own life between trips (tail, wings, a look round): Swim.idle
    readonly property real seed: Swim.seed(itemId)
    readonly property var life: onFloor || !scene.floating ? Swim.REST : Swim.idle(peer.kind, scene.swim, seed, wake)
    readonly property real bob: onFloor || !scene.floating ? 0 : Math.sin(scene.swim * 0.9 + phase) * (0.8 + 2.4 * wake)

    x: spot.x
    y: spot.y
    // A detailed peer (and its label) rises above its neighbours
    z: detailed ? 1 : 0
    // No Behavior on x/y: a move is a swim trip (AbyssScene, Swim.js), in pose,
    // so the creature and its tentacle travel together

    Item {
        id: lensed
        x: cr.pose.x
        y: cr.pose.y
        scale: cr.pose.s
        // Hidden while its twin sits on the open card, back in fade as ‹ › steps away (CardHero)
        opacity: cr.scene.heroOpacity(cr.peer.id)

        Item {
            id: body
            x: cr.life.dx
            y: cr.bob + cr.life.dy

            Halo {
                width: 110
                height: 110
                x: -55
                y: -55
                color: cr.tint
                opacity: cr.muted ? cr.glow * 0.3 : cr.glow
            }
            // Rings: the open card, a search hit
            Rectangle {
                visible: cr.highlighted
                width: 54
                height: 54
                radius: 27
                x: -27
                y: -27
                color: "transparent"
                border.width: 2
                border.color: cr.scene.sunColor
            }
            CreatureShape {
                x: -48
                y: -48
                kind: cr.peer.kind
                color: cr.peer.online ? cr.scene.mix(cr.scene.sleepColor, Qt.lighter(cr.tint, 1.25), cr.wake) : cr.scene.sleepColor
                glow: cr.glow
                asleep: !cr.live || cr.muted
                // Body pulse while it swims (wings, jet)
                scale: cr.scene.creatureScale(cr.peer, cr.wake) * cr.pose.b
                // Faces where it swims (shapes face right) and tilts its nose
                transform: [
                    Scale {
                        origin.x: 48
                        origin.y: 48
                        xScale: cr.pose.f * cr.life.f * cr.life.sx
                        yScale: cr.life.sy
                    },
                    Rotation {
                        origin.x: 48
                        origin.y: 48
                        angle: cr.pose.a + cr.life.a
                    }
                ]
            }
            StyledText {
                visible: cr.muted && cr.live
                x: 22
                y: -30
                text: "z"
                color: cr.scene.inkDim
            }
        }

        Chip {
            id: label
            // The lens grows the creature, but text past ×1.15 only looks bloated
            scale: Math.min(1, 1.15 / cr.pose.s)
            transformOrigin: Item.Top
            // Offline peers stay unlabelled until pointed at
            visible: cr.live || cr.detailed
            x: -width / 2
            y: body.y + (cr.onFloor ? 16 : 26)
            title: (cr.favorite ? "★ " : "") + cr.peer.name
            titleSize: cr.detailed ? 12 : 11
            sub: !cr.detailed ? "" : !cr.peer.online ? (cr.peer.dozing ? "idle · wakes on use" : "offline") : !cr.scene.connected ? "" : "↓" + Mesh.fmtShort(cr.peer.down) + "  ↑" + Mesh.fmtShort(cr.peer.up)
            third: (cr.hovered || cr.focused) && cr.live ? Math.round(cr.peer.latencyMs) + " ms · " + (cr.peer.relayed ? "via " + cr.peer.relay : "direct") : ""
            caption: cr.broken ? "RELAY DOWN" : cr.isTop ? "TOP CONSUMER" : ""
            captionInk: cr.broken ? Theme.warning : cr.tint
            // The top consumer is told by its caption alone: its pill keeps
            // the same colours as every other one
            ink: cr.live ? cr.scene.ink : cr.scene.inkDim
            subInk: cr.scene.inkDim
            color: Qt.rgba(cr.scene.abyss.r, cr.scene.abyss.g, cr.scene.abyss.b, cr.detailed ? 0.8 : 0.4)
            opacity: cr.muted ? 0.7 : 1
        }

        GrabArea {
            id: area
            x: -40
            y: -36
            width: 80
            height: label.y + label.height + 36
            scene: cr.scene
            itemId: cr.itemId
            onTapped: cr.scene.openCard(cr.peer.id)
        }
    }
}
