import QtQuick
import "Goldfish.js" as Fish

// Darwin, the goldfish companion (Goldfish.js is his life; this draws it):
// two little arms, no legs.
// Plain rectangles turned and scaled from his pose: nothing is painted on a
// canvas, nothing runs here. The scene's clock moves him while someone
// watches (setting "Companion"); a click and he waves back.
Item {
    id: gf

    property var scene
    // The Goldfish.js state, and a counter the scene bumps after each step
    // (the state is changed in place, so bindings need the nudge)
    property var fish: null
    property int frame: 0

    readonly property var s: frame >= 0 ? fish : null
    readonly property var p: s ? Fish.pose(s, scene.t) : null
    readonly property color orange: "#f2913a"
    readonly property color deep: "#d9661f"

    // The glass clouding over where he has not scrubbed yet
    Repeater {
        model: gf.s ? gf.s.spots.length : 0
        Rectangle {
            required property int index
            readonly property var spot: gf.frame >= 0 && gf.s ? gf.s.spots[index] : null
            visible: !!spot && spot.dirt > 0.04
            x: spot ? spot.x - spot.r : 0
            y: spot ? spot.y - spot.r : 0
            width: spot ? spot.r * 2 : 0
            height: width
            radius: width / 2
            color: Qt.rgba(0.45, 0.62, 0.38, 1)
            opacity: spot ? spot.dirt * 0.14 : 0
        }
    }
    // Crumbs falling from the traffic
    Repeater {
        model: gf.s ? gf.s.crumbs.length : 0
        Rectangle {
            required property int index
            readonly property var c: gf.frame >= 0 && gf.s ? gf.s.crumbs[index] : null
            visible: !!c
            x: c ? c.x - 1.5 : 0
            y: c ? c.y - 1.5 : 0
            width: 3
            height: 3
            radius: 1.5
            color: "#e8c88a"
            opacity: 0.85
        }
    }

    // Darwin himself, drawn facing left; turned round by his heading
    Item {
        id: body
        visible: !!gf.s
        x: gf.s ? gf.s.x : 0
        y: gf.s ? gf.s.y + (gf.p ? gf.p.bob : 0) : 0
        transform: [
            Rotation {
                angle: gf.p ? gf.p.tilt * -(gf.s ? gf.s.dir : -1) : 0
            },
            Scale {
                xScale: gf.s && gf.s.dir > 0 ? -1 : 1
            }
        ]

        // Tail: two lobes, swinging
        Item {
            x: 9
            rotation: gf.p ? gf.p.tail : 0
            transformOrigin: Item.Left
            Rectangle {
                y: -7
                width: 11
                height: 7
                radius: 4
                color: gf.deep
                rotation: -24
                transformOrigin: Item.BottomLeft
                opacity: 0.92
            }
            Rectangle {
                y: 0
                width: 11
                height: 7
                radius: 4
                color: gf.deep
                rotation: 24
                transformOrigin: Item.TopLeft
                opacity: 0.92
            }
        }
        // Body and belly
        Rectangle {
            x: -12
            y: -7
            width: 23
            height: 14
            radius: 7
            color: gf.orange
        }
        Rectangle {
            x: -9
            y: 0
            width: 15
            height: 6
            radius: 3
            color: "#f7b26a"
        }
        // Two little arms, no legs. The near one paddles, scrubs the glass
        // and waves hello; the far one, behind him, swings as he swims
        component Arm: Item {
            id: arm
            // 0 reaches forward and down, like a little arm (never hanging
            // straight down, where it would read as a leg); positive lifts
            // it forward and up (he faces left)
            property real angle: 0
            property color ink: gf.orange
            rotation: 135 + angle
            transformOrigin: Item.TopLeft
            Rectangle {
                y: -0.9
                width: 7.5
                height: 1.8
                radius: 0.9
                color: arm.ink
            }
            // A round little hand
            Rectangle {
                x: 6.2
                y: -1.8
                width: 3.6
                height: 3.6
                radius: 1.8
                color: arm.ink
            }
        }
        Arm {
            x: -3
            y: 2
            z: -1
            angle: gf.p ? gf.p.arms * 0.8 - 10 : 0
            ink: gf.deep
        }
        // From his flank: a wave rises in front of his face (fin -100..-40
        // lifts it up), a scrub reaches forward, a paddle stays low
        Arm {
            x: -5
            y: 2.5
            angle: gf.p ? -gf.p.fin * 1.2 : 0
            ink: "#ffc27a"
        }
        // Eye and its lid
        Rectangle {
            x: -9
            y: -4
            width: 5
            height: 5
            radius: 2.5
            color: "white"
            Rectangle {
                x: 0.8
                y: 1.2
                width: 2.6
                height: 2.6
                radius: 1.3
                color: "#1b1b24"
            }
            Rectangle {
                width: 5
                height: 5 * (gf.p ? gf.p.lid : 0)
                radius: 2.5
                color: gf.orange
            }
        }
        // Mouth: opens while he munches
        Rectangle {
            x: -13
            y: 0.5
            width: 2.5
            height: 1 + 2.5 * (gf.p ? gf.p.mouth : 0)
            radius: 1
            color: "#7a2f10"
        }
        // "z" while he sleeps
        Text {
            visible: !!gf.p && gf.p.asleep
            x: -6
            y: -22
            text: "z"
            font.pixelSize: 9
            color: gf.scene ? gf.scene.inkDim : "white"
            transform: Scale {
                xScale: gf.s && gf.s.dir > 0 ? -1 : 1
            }
        }
        MouseArea {
            x: -16
            y: -12
            width: 36
            height: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Fish.wave(gf.fish);
                gf.frame++;
            }
        }
    }
}
