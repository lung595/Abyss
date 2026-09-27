import QtQuick
import qs.Common
import "Mesh.js" as Mesh

// The peer's creature on its open card, as in Orbit: it leaves its place in
// the water, glides onto the card's top edge and grows (a beat later) into a
// medallion that breaks out of the frame; on close it swims back home.
// Brief transitions only, never a loop; instant with Reduce motion.
Item {
    id: hero

    property var scene
    property bool open: false
    // The peer shown; kept while flying back after the card closed
    property string peerId: ""
    // Where its creature is drawn in the water, and how big it is there
    property point from
    property real fromScale: 1
    // Medallion centre on the card's top edge, and its diameter
    property point to
    property real diameter: 104

    readonly property var peer: scene.peerById[peerId] || null
    readonly property bool live: !!peer && peer.online && scene.connected
    readonly property color tint: peer ? scene.tintOf(peer.name) : "white"
    // The creature art is drawn in a 96 px box; it fills ~75% of the medallion
    readonly property real toScale: diameter / 104

    // 0 = in the water, 1 = on the card (a slight overshoot, like a spring)
    property real flight: 0
    // 0 = water size, 1 = medallion size
    property real grow: 0

    readonly property int _ms: scene.reduceMotion ? 0 : 1

    visible: !!peer && (flight > 0.001 || grow > 0.001)
    x: from.x + (to.x - from.x) * flight
    y: from.y + (to.y - from.y) * flight

    onOpenChanged: {
        flyIn.stop();
        flyOut.stop();
        (open ? flyIn : flyOut).restart();
    }
    // Another card opened straight away: start the flight again from its creature
    onPeerIdChanged: {
        if (!open)
            return;
        flyOut.stop();
        flight = 0;
        grow = 0;
        flyIn.restart();
    }

    ParallelAnimation {
        id: flyIn
        NumberAnimation {
            target: hero
            property: "flight"
            to: 1
            duration: 560 * hero._ms
            easing.type: Easing.OutBack
            easing.overshoot: 0.7
        }
        SequentialAnimation {
            PauseAnimation {
                duration: 140 * hero._ms
            }
            NumberAnimation {
                target: hero
                property: "grow"
                to: 1
                duration: 520 * hero._ms
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }
    }
    ParallelAnimation {
        id: flyOut
        NumberAnimation {
            target: hero
            property: "flight"
            to: 0
            duration: 400 * hero._ms
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: hero
            property: "grow"
            to: 0
            duration: 340 * hero._ms
            easing.type: Easing.OutCubic
        }
    }

    // The medallion: the card bulging around its creature
    Rectangle {
        width: hero.diameter
        height: width
        radius: width / 2
        x: -width / 2
        y: -width / 2
        scale: 0.6 + 0.4 * hero.grow
        opacity: Math.min(1, hero.grow)
        color: Qt.rgba(hero.scene.abyss.r, hero.scene.abyss.g, hero.scene.abyss.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(hero.tint.r, hero.tint.g, hero.tint.b, 0.45)
    }

    Item {
        scale: hero.fromScale + (hero.toScale - hero.fromScale) * hero.grow
        // Keeps breathing on the card while the deep flows
        y: hero.scene.flowing ? Math.sin(hero.scene.t * 0.9) * 2 * hero.grow : 0

        Halo {
            width: 130
            height: 130
            x: -65
            y: -65
            color: hero.tint
            opacity: hero.live ? 0.35 + 0.5 * Mesh.level(hero.peer.down + hero.peer.up) : 0.08
        }
        CreatureShape {
            x: -48
            y: -48
            kind: hero.peer ? hero.peer.kind : "desktop"
            color: hero.live ? Qt.lighter(hero.tint, 1.25) : hero.scene.sleepColor
            glow: hero.live ? 0.9 : 0.1
            asleep: !hero.live
        }
    }
}
