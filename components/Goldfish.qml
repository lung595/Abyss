import QtQuick
import "Goldfish.js" as Fish

// Darwin, the goldfish companion (Goldfish.js is his life; this draws it):
// a round orange fish with big eyes, two little arms and no legs.
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
    readonly property color orange: "#f5892b"
    readonly property color deep: "#d8661c"
    readonly property color light: "#ffb066"

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

    // Darwin himself: a round orange body, two big eyes standing up on
    // top, a small tail, two little arms and no legs. Drawn facing left,
    // turned round by his heading
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

        // Two little arms (the far one behind him, darker). The near one
        // paddles, scrubs the glass and waves hello; the far one swings as
        // he swims. Both reach forward from his front, never down like legs
        component Arm: Item {
            id: arm
            // 0 reaches forward and down; positive lifts it forward and up
            property real angle: 0
            property color ink: gf.orange
            rotation: 135 + angle
            transformOrigin: Item.TopLeft
            Rectangle {
                y: -0.9
                width: 6.5
                height: 1.8
                radius: 0.9
                color: arm.ink
            }
            Rectangle {
                x: 5.4
                y: -1.7
                width: 3.4
                height: 3.4
                radius: 1.7
                color: arm.ink
            }
        }
        Arm {
            x: -3
            y: 6
            angle: gf.p ? gf.p.arms * 0.8 - 10 : 0
            ink: gf.deep
        }

        // A small tail: two rounded lobes, swinging
        Item {
            x: 8
            y: 1
            rotation: gf.p ? gf.p.tail * 0.8 : 0
            transformOrigin: Item.Left
            Rectangle {
                y: -5.5
                width: 8
                height: 5.5
                radius: 2.8
                color: gf.deep
                rotation: -28
                transformOrigin: Item.BottomLeft
            }
            Rectangle {
                width: 8
                height: 5.5
                radius: 2.8
                color: gf.deep
                rotation: 28
                transformOrigin: Item.TopLeft
            }
        }
        // The body: a ball, a lighter cheek where the light falls
        Rectangle {
            x: -10
            y: -9
            width: 20
            height: 19
            radius: 9.5
            color: gf.orange
            border.width: 0.6
            border.color: gf.deep
            // A soft light on his back
            Rectangle {
                x: 11
                y: 4
                width: 4
                height: 6
                radius: 2
                color: gf.light
                opacity: 0.55
            }
        }
        // Mouth: a small dark smile that opens while he munches
        Rectangle {
            x: -10.8
            y: 1 - height / 2
            width: 3
            height: 1.2 + 2.6 * (gf.p ? gf.p.mouth : 0)
            radius: 1.2
            color: "#6b2a0e"
        }
        Arm {
            x: -5
            y: 6.5
            angle: gf.p ? -gf.p.fin * 1.2 : 0
            ink: gf.light
        }

        // Two big eyes standing up on top, the far one just behind the near
        // one, both looking where he goes; a blink closes them from above
        component Eye: Item {
            id: eye
            width: 9
            height: 10.5
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "white"
                border.width: 0.6
                border.color: "#c9c3bd"
            }
            Rectangle {
                x: 1.3
                y: 3.6
                width: 4
                height: 4.4
                radius: 2
                color: "#15151d"
                Rectangle {
                    x: 0.6
                    y: 0.6
                    width: 1.1
                    height: 1.1
                    radius: 0.55
                    color: "white"
                }
            }
            // The lid: closes from above; shut, a dark line marks it
            Rectangle {
                width: parent.width
                height: parent.height * (gf.p ? gf.p.lid : 0)
                radius: width / 2
                color: gf.orange
                border.width: height > 2 ? 0.6 : 0
                border.color: gf.deep
                Rectangle {
                    visible: parent.height > parent.width * 0.8
                    x: 1.5
                    y: parent.height * 0.62
                    width: parent.width - 3
                    height: 0.9
                    radius: 0.45
                    color: "#6b2a0e"
                }
            }
        }
        Eye {
            x: -3
            y: -17
        }
        Eye {
            x: -10
            y: -16
        }

        // "z" while he sleeps
        Text {
            visible: !!gf.p && gf.p.asleep
            x: -4
            y: -27
            text: "z"
            font.pixelSize: 9
            color: gf.scene ? gf.scene.inkDim : "white"
            transform: Scale {
                xScale: gf.s && gf.s.dir > 0 ? -1 : 1
            }
        }
        MouseArea {
            x: -14
            y: -18
            width: 30
            height: 30
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Fish.wave(gf.fish);
                gf.frame++;
            }
        }
    }
}
