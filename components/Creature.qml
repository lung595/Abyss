import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

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

    readonly property bool live: peer.online && scene.connected
    readonly property real glow: live ? 0.15 + 0.85 * Mesh.level(peer.down + peer.up) : 0.04
    // Gentle bob while the scene runs; an offset on a child, never animated
    readonly property real bob: onFloor || !scene.flowing ? 0 : Math.sin(scene.t * 0.9 + phase) * 3

    x: spot.x
    y: spot.y
    // A detailed peer (and its label) rises above its neighbours
    z: detailed ? 1 : 0
    Behavior on x {
        enabled: !cr.scene.reduceMotion
        NumberAnimation {
            duration: 1100
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        enabled: !cr.scene.reduceMotion
        NumberAnimation {
            duration: 1300
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: body
        y: cr.bob

        Halo {
            width: 150
            height: 150
            x: -75
            y: -75
            color: cr.tint
            opacity: cr.muted ? cr.glow * 0.3 : cr.glow
        }
        // Rings: the open card, a search hit
        Rectangle {
            visible: cr.highlighted
            width: 70
            height: 70
            radius: 35
            x: -35
            y: -35
            color: "transparent"
            border.width: 2
            border.color: cr.scene.sunColor
        }
        CreatureShape {
            x: -48
            y: -48
            kind: cr.peer.kind
            color: cr.live ? Qt.lighter(cr.tint, 1.25) : cr.scene.sleepColor
            glow: cr.glow
            asleep: !cr.live || cr.muted
            scale: 0.9 + 0.35 * cr.glow
        }
        StyledText {
            visible: cr.muted && cr.live
            x: 22
            y: -30
            text: "z"
            color: cr.scene.inkDim
        }
    }

    // Details only where the eye needs them: the top consumer, the peer
    // under the pointer and the one whose card is open or was found.
    // Everyone else shows a quiet name; the tentacle already tells its traffic.
    readonly property bool detailed: cr.isTop || cr.hovered || cr.highlighted

    Chip {
        id: label
        // Offline peers stay unlabelled until pointed at
        visible: cr.live || cr.detailed
        x: -width / 2
        y: body.y + (cr.onFloor ? 22 : 36)
        title: (cr.favorite ? "★ " : "") + cr.peer.name
        titleSize: cr.detailed ? 12 : 11
        sub: !cr.detailed ? "" : !cr.peer.online ? "offline" : !cr.scene.connected ? "" : "↓" + Mesh.fmtShort(cr.peer.down) + "  ↑" + Mesh.fmtShort(cr.peer.up)
        third: cr.hovered && cr.live ? Math.round(cr.peer.latencyMs) + " ms · " + (cr.peer.relayed ? "via " + cr.peer.relay : "direct") : ""
        caption: cr.isTop ? "TOP CONSUMER" : ""
        captionInk: cr.tint
        ink: cr.isTop ? cr.scene.abyss : cr.live ? cr.scene.ink : cr.scene.inkDim
        subInk: cr.isTop ? Qt.rgba(cr.scene.abyss.r, cr.scene.abyss.g, cr.scene.abyss.b, 0.8) : cr.scene.inkDim
        color: cr.isTop ? cr.tint : Qt.rgba(cr.scene.abyss.r, cr.scene.abyss.g, cr.scene.abyss.b, cr.detailed ? 0.8 : 0.4)
        opacity: cr.muted ? 0.7 : 1
    }

    MouseArea {
        id: area
        x: -40
        y: -36
        width: 80
        height: label.y + label.height + 36
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cr.scene.openCard(cr.peer.id)
    }
}
