import QtQuick
import QtQuick.Shapes
import "Goldfish.js" as Fish

// Darwin, the goldfish companion (Goldfish.js is his life; this draws it),
// in a cartoon style: an orange bean of a body outlined in ink, two big
// round eyes with lashes and brows, puffy cheeks and a small smile, a fan
// of a tail, and two little arms hanging under him (no legs). Vector paths
// (Shape), drawn once; only transforms change as he moves.
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
    readonly property color orange: "#ff7f14"
    readonly property color light: "#ffa04d"
    readonly property color blush: "#ff9a5c"
    readonly property color ink: "#1c1a24"
    // Drawn on a 100-unit grid, then scaled to about 40 px wide
    readonly property real unit: 0.42

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

    // Darwin himself. Drawn facing right on a 100 x 80 grid centred on his
    // body (0, 0), turned round by his heading
    Item {
        id: body
        visible: !!gf.s
        x: gf.s ? gf.s.x : 0
        y: gf.s ? gf.s.y + (gf.p ? gf.p.bob : 0) : 0
        transform: [
            Rotation {
                angle: gf.p ? gf.p.tilt * (gf.s && gf.s.dir > 0 ? 1 : -1) * 0.6 : 0
            },
            Scale {
                xScale: (gf.s && gf.s.dir > 0 ? 1 : -1) * gf.unit
                yScale: gf.unit
            }
        ]

        // An arm: a soft tube with a rounded end, hanging from under him.
        // angle 0 hangs down and curls in a little; positive lifts it
        // forward and up (a wave), negative swings it back
        component Arm: Shape {
            id: arm
            property real angle: 0
            property bool far: false
            preferredRendererType: Shape.CurveRenderer
            rotation: -angle
            transformOrigin: Item.TopLeft
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.4
                fillColor: arm.far ? Qt.darker(gf.orange, 1.12) : gf.orange
                capStyle: ShapePath.RoundCap
                startX: -5
                startY: 0
                PathCubic {
                    x: -4
                    y: 22
                    control1X: -7
                    control1Y: 8
                    control2X: -9
                    control2Y: 16
                }
                PathArc {
                    x: 5
                    y: 21
                    radiusX: 4.6
                    radiusY: 4.6
                    direction: PathArc.Counterclockwise
                }
                PathCubic {
                    x: 5
                    y: 0
                    control1X: 1
                    control1Y: 15
                    control2X: 3
                    control2Y: 8
                }
            }
        }
        Arm {
            x: 14
            y: 22
            z: -1
            far: true
            angle: gf.p ? gf.p.arms * 0.7 : 0
        }

        // The tail: a rounded fan at his back, ribbed, swinging
        Shape {
            preferredRendererType: Shape.CurveRenderer
            x: -38
            y: 10
            rotation: gf.p ? gf.p.tail * 0.6 : 0
            transformOrigin: Item.TopLeft
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.4
                fillColor: gf.orange
                startX: 4
                startY: -9
                PathCubic {
                    x: 2
                    y: 13
                    control1X: -18
                    control1Y: -12
                    control2X: -20
                    control2Y: 16
                }
            }
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 1.6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: -12
                startY: -1
                PathLine {
                    x: -6
                    y: 0
                }
                PathMove {
                    x: -11
                    y: 6
                }
                PathLine {
                    x: -5
                    y: 5
                }
            }
        }

        // The body: a bean, domed at the back, bulging at the face
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.6
                fillColor: gf.orange
                joinStyle: ShapePath.RoundJoin
                startX: -36
                startY: 2
                PathCubic {
                    x: 2
                    y: -30
                    control1X: -38
                    control1Y: -22
                    control2X: -18
                    control2Y: -32
                }
                PathCubic {
                    x: 34
                    y: -10
                    control1X: 22
                    control1Y: -29
                    control2X: 30
                    control2Y: -22
                }
                PathCubic {
                    x: 36
                    y: 20
                    control1X: 46
                    control1Y: -4
                    control2X: 48
                    control2Y: 14
                }
                PathCubic {
                    x: -10
                    y: 26
                    control1X: 24
                    control1Y: 28
                    control2X: 6
                    control2Y: 28
                }
                PathCubic {
                    x: -36
                    y: 2
                    control1X: -28
                    control1Y: 25
                    control2X: -36
                    control2Y: 18
                }
            }
            // The glossy streak on his back
            ShapePath {
                strokeColor: "transparent"
                fillColor: gf.light
                startX: -29
                startY: -4
                PathCubic {
                    x: -20
                    y: -20
                    control1X: -30
                    control1Y: -12
                    control2X: -26
                    control2Y: -18
                }
                PathCubic {
                    x: -24
                    y: 8
                    control1X: -17
                    control1Y: -15
                    control2X: -22
                    control2Y: 0
                }
                PathCubic {
                    x: -29
                    y: -4
                    control1X: -27
                    control1Y: 10
                    control2X: -30
                    control2Y: 2
                }
            }
        }

        // An eye: a big white disc ringed in ink, a black pupil looking
        // ahead, three lashes and a brow; the lid comes down from above
        component Eye: Item {
            id: eye
            // Which side the lashes go (-1 left eye, 1 right eye)
            property int side: 1
            readonly property real lid: gf.p ? gf.p.lid : 0
            // Shut (asleep, or the middle of a blink): a closed eye's curve
            readonly property bool shut: lid >= 0.95
            Rectangle {
                visible: !eye.shut
                x: -12.5
                y: -12.5
                width: 25
                height: 25
                radius: 12.5
                color: "white"
                border.width: 2.4
                border.color: gf.ink
            }
            Rectangle {
                visible: !eye.shut && eye.lid < 0.9
                x: -5
                y: -3 - 3 * eye.lid
                width: 11
                height: 11 * (1 - eye.lid)
                radius: 5.5
                color: gf.ink
            }
            // The lid: orange from the top, shut it leaves a curved line
            Rectangle {
                visible: !eye.shut && eye.lid > 0.05
                x: -12.5
                y: -12.5
                width: 25
                height: 25 * eye.lid
                radius: Math.min(12.5, height / 2)
                color: gf.orange
                border.width: 2.4
                border.color: gf.ink
            }
            Shape {
                visible: eye.shut
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: gf.ink
                    strokeWidth: 2.6
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: -9
                    startY: 1
                    PathQuad {
                        x: 9
                        y: 1
                        controlX: 0
                        controlY: 8
                    }
                }
            }
            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: gf.ink
                    strokeWidth: 1.4
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: 7 * eye.side
                    startY: -9
                    PathLine {
                        x: 10 * eye.side
                        y: -13
                    }
                    PathMove {
                        x: 9.5 * eye.side
                        y: -6
                    }
                    PathLine {
                        x: 13 * eye.side
                        y: -9
                    }
                }
                // The brow, high above the eye
                ShapePath {
                    strokeColor: gf.ink
                    strokeWidth: 2.6
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: -5
                    startY: -16
                    PathQuad {
                        x: 5
                        y: -16
                        controlX: 0
                        controlY: -19
                    }
                }
            }
        }
        Eye {
            x: -1
            y: -9
            side: -1
        }
        Eye {
            x: 25
            y: -9
            side: 1
        }

        // Puffy cheeks under the eyes, a blush on each, and the smile
        // between them; the smile opens while he munches
        component Cheek: Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2
                fillColor: gf.orange
                startX: -7
                startY: -2
                PathArc {
                    x: 7
                    y: -2
                    radiusX: 7.5
                    radiusY: 7
                    direction: PathArc.Counterclockwise
                    useLargeArc: true
                }
            }
            ShapePath {
                strokeColor: "transparent"
                fillColor: gf.blush
                startX: -4
                startY: 0
                PathArc {
                    x: 4
                    y: 0
                    radiusX: 4
                    radiusY: 4
                    useLargeArc: true
                }
                PathArc {
                    x: -4
                    y: 0
                    radiusX: 4
                    radiusY: 4
                    useLargeArc: true
                }
            }
        }
        Cheek {
            x: -1
            y: 7
        }
        Cheek {
            x: 25
            y: 7
        }
        Shape {
            id: smile
            preferredRendererType: Shape.CurveRenderer
            readonly property real open: gf.p ? gf.p.mouth : 0
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.2
                fillColor: smile.open > 0.1 ? "#7a2a12" : "transparent"
                capStyle: ShapePath.RoundCap
                startX: 6
                startY: 9
                PathQuad {
                    x: 18
                    y: 9
                    controlX: 12
                    controlY: 14 + 6 * smile.open
                }
            }
        }

        // The near arm, in front of him: waves hello, scrubs, paddles
        Arm {
            x: 34
            y: 22
            angle: gf.p ? -gf.p.fin * 1.3 : 0
        }

        // "z" while he sleeps
        Text {
            visible: !!gf.p && gf.p.asleep
            x: 10
            y: -58
            text: "z"
            font.pixelSize: 22
            color: gf.scene ? gf.scene.inkDim : "white"
            transform: Scale {
                xScale: gf.s && gf.s.dir > 0 ? 1 : -1
            }
        }
        MouseArea {
            x: -42
            y: -34
            width: 92
            height: 80
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Fish.wave(gf.fish);
                gf.frame++;
            }
        }
    }
}
