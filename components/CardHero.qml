import QtQuick
import qs.Common
import "Mesh.js" as Mesh

// The peer's creature on its open card, as in Orbit: it leaves its place in
// the water, glides onto the card's top edge and grows (a beat later) into a
// medallion that breaks out of the frame; on close it swims back home.
// Stepping to another peer (‹ ›) keeps the medallion still and cross-fades
// the two creatures inside it (switchTo).
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

    // The peer stepped away from, fading out while this one fades in (0 → 1)
    property string prevId: ""
    property real swap: 1

    readonly property var peer: scene.peerById[peerId] || null
    readonly property var prevPeer: prevId !== "" ? scene.peerById[prevId] || null : null
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
        if (!open || _stepping)
            return;
        flyOut.stop();
        flight = 0;
        grow = 0;
        flyIn.restart();
    }

    // Steps to another peer while the card stays open: no flight, the new
    // creature appears in the medallion as the old one fades back home
    property bool _stepping: false
    function switchTo(id) {
        if (id === peerId)
            return;
        cross.stop();
        prevId = peerId;
        _stepping = true;
        peerId = id;
        _stepping = false;
        swap = 0;
        cross.restart();
    }
    NumberAnimation {
        id: cross
        target: hero
        property: "swap"
        to: 1
        duration: 260 * hero._ms
        easing.type: Easing.InOutQuad
        onFinished: hero.prevId = ""
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

        Twin {
            peer: hero.prevPeer
            opacity: 1 - hero.swap
        }
        Twin {
            peer: hero.peer
            opacity: hero.prevPeer ? hero.swap : 1
        }
    }

    // One creature in the medallion: its halo says how busy it is
    component Twin: Item {
        id: twin
        property var peer
        readonly property bool live: !!peer && peer.online && hero.scene.connected
        readonly property color tint: peer ? hero.scene.tintOf(peer.name) : "white"
        visible: !!peer && opacity > 0.01

        Halo {
            width: 130
            height: 130
            x: -65
            y: -65
            color: twin.tint
            opacity: twin.live ? 0.35 + 0.5 * Mesh.level(twin.peer.down + twin.peer.up) : 0.08
        }
        CreatureShape {
            x: -48
            y: -48
            kind: twin.peer ? twin.peer.kind : "desktop"
            color: twin.live ? Qt.lighter(twin.tint, 1.25) : hero.scene.sleepColor
            glow: twin.live ? 0.9 : 0.1
            asleep: !twin.live
        }
    }
}
