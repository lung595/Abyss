import QtQuick
import QtQuick.Shapes
import "Goldfish.js" as Fish

// Darwin, the goldfish companion (Goldfish.js is his life; this draws it),
// after the cartoon goldfish: his head is his whole body, an orange blob
// outlined in ink, domed at the back and bulging at the front; two big eyes
// almost touching, with lashes and short brows; round cheeks over the
// bottom of the eyes, a blush on each, the smile between them; a glossy
// streak at the back; a ribbed fan of a tail low behind; his side fins are
// his arms (no legs). Vector paths, drawn once; only transforms change.
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
    // Drawn on a grid about 110 units wide, scaled to about 44 px
    readonly property real unit: 0.4

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

    // Darwin himself, facing the viewer a little to the right (as drawn
    // in the cartoon), turned round by his heading; (0, 0) is his middle
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

        // A side fin, his arm and hand: a rounded flipper from his lower
        // side, curling at the tip. angle 0 rests along his side; positive
        // lifts it up and out (a wave)
        component Fin: Shape {
            id: fin
            property real angle: 0
            property int side: 1
            preferredRendererType: Shape.CurveRenderer
            // At rest it hangs down and out from his lower side, like a hand
            rotation: (50 - angle) * side
            transformOrigin: Item.TopLeft
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.2
                fillColor: gf.orange
                joinStyle: ShapePath.RoundJoin
                startX: 0
                startY: -5
                PathCubic {
                    x: 15 * fin.side
                    y: 4
                    control1X: 8 * fin.side
                    control1Y: -6
                    control2X: 15 * fin.side
                    control2Y: -3
                }
                PathCubic {
                    x: 8 * fin.side
                    y: 8
                    control1X: 15 * fin.side
                    control1Y: 9
                    control2X: 11 * fin.side
                    control2Y: 10
                }
                PathCubic {
                    x: 0
                    y: 5
                    control1X: 5 * fin.side
                    control1Y: 6
                    control2X: 3 * fin.side
                    control2Y: 5
                }
            }
            // The crease of the hand
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 1.4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 9 * fin.side
                startY: 5
                PathQuad {
                    x: 12 * fin.side
                    y: 2
                    controlX: 12 * fin.side
                    controlY: 5
                }
            }
        }
        // The back fin first: behind his body
        Fin {
            x: -26
            y: 28
            z: -1
            side: -1
            angle: gf.p ? gf.p.arms * 0.6 : 0
        }

        // The tail: a rounded, ribbed fan low behind him
        Shape {
            preferredRendererType: Shape.CurveRenderer
            x: -42
            y: 19
            rotation: gf.p ? gf.p.tail * 0.5 : 0
            transformOrigin: Item.TopLeft
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.2
                fillColor: gf.orange
                joinStyle: ShapePath.RoundJoin
                startX: 4
                startY: -8
                PathCubic {
                    x: -11
                    y: -5
                    control1X: -4
                    control1Y: -10
                    control2X: -10
                    control2Y: -9
                }
                PathCubic {
                    x: 2
                    y: 14
                    control1X: -16
                    control1Y: 4
                    control2X: -8
                    control2Y: 16
                }
            }
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 1.4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: -12
                startY: 0
                PathLine {
                    x: -6
                    y: 1
                }
                PathMove {
                    x: -9
                    y: 7
                }
                PathLine {
                    x: -4
                    y: 6
                }
            }
        }

        // His head, which is all of him
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.4
                fillColor: gf.orange
                joinStyle: ShapePath.RoundJoin
                startX: -47
                startY: -3
                PathCubic {
                    x: -12
                    y: -33
                    control1X: -47
                    control1Y: -25
                    control2X: -32
                    control2Y: -33
                }
                PathCubic {
                    x: 27
                    y: -27
                    control1X: 4
                    control1Y: -33
                    control2X: 18
                    control2Y: -32
                }
                PathCubic {
                    x: 50
                    y: 8
                    control1X: 38
                    control1Y: -20
                    control2X: 52
                    control2Y: -8
                }
                PathCubic {
                    x: 32
                    y: 32
                    control1X: 49
                    control1Y: 22
                    control2X: 42
                    control2Y: 31
                }
                PathCubic {
                    x: -14
                    y: 34
                    control1X: 16
                    control1Y: 34
                    control2X: 0
                    control2Y: 35
                }
                PathCubic {
                    x: -47
                    y: -3
                    control1X: -38
                    control1Y: 33
                    control2X: -48
                    control2Y: 18
                }
            }
            // The glossy streak at the back, and a smaller drop under it
            ShapePath {
                strokeColor: "transparent"
                fillColor: gf.light
                startX: -41
                startY: 2
                PathCubic {
                    x: -36
                    y: -16
                    control1X: -43
                    control1Y: -6
                    control2X: -41
                    control2Y: -14
                }
                PathCubic {
                    x: -36
                    y: 4
                    control1X: -32
                    control1Y: -17
                    control2X: -33
                    control2Y: -3
                }
                PathCubic {
                    x: -41
                    y: 2
                    control1X: -38
                    control1Y: 8
                    control2X: -41
                    control2Y: 6
                }
            }
        }

        // An eye: a big white oval ringed in ink, a large black pupil with a
        // glint, three lashes at the outer top, a short brow above
        component Eye: Item {
            id: eye
            // -1 the eye on the left, 1 the one on the right (lashes outward)
            property int side: 1
            readonly property bool shut: gf.p ? gf.p.lid > 0.5 : false
            Rectangle {
                visible: !eye.shut
                x: -15
                y: -16
                width: 30
                height: 32
                radius: 15
                color: "white"
                border.width: 2.4
                border.color: gf.ink
            }
            Rectangle {
                visible: !eye.shut
                x: -5.5 + 1.5 * eye.side * -0.3
                y: -4
                width: 11
                height: 11.5
                radius: 5.5
                color: gf.ink
                Rectangle {
                    x: 2
                    y: 1.8
                    width: 3
                    height: 3
                    radius: 1.5
                    color: "white"
                }
            }
            Shape {
                preferredRendererType: Shape.CurveRenderer
                // Shut (asleep, or a blink): the closed eye's curve
                ShapePath {
                    strokeColor: eye.shut ? gf.ink : "transparent"
                    strokeWidth: 2.6
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: -11
                    startY: 2
                    PathQuad {
                        x: 11
                        y: 2
                        controlX: 0
                        controlY: 10
                    }
                }
                // Three lashes at the outer top
                ShapePath {
                    strokeColor: gf.ink
                    strokeWidth: 1.4
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: 8 * eye.side
                    startY: -12
                    PathLine {
                        x: 10 * eye.side
                        y: -16
                    }
                    PathMove {
                        x: 11 * eye.side
                        y: -9
                    }
                    PathLine {
                        x: 14.5 * eye.side
                        y: -12
                    }
                    PathMove {
                        x: 13 * eye.side
                        y: -5
                    }
                    PathLine {
                        x: 17 * eye.side
                        y: -7
                    }
                }
                // The brow: short and thick, well above
                ShapePath {
                    strokeColor: gf.ink
                    strokeWidth: 3.2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: -5
                    startY: -21
                    PathQuad {
                        x: 5
                        y: -21
                        controlX: 0
                        controlY: -24
                    }
                }
            }
        }
        Eye {
            x: -12
            y: -7
            side: -1
        }
        Eye {
            x: 18
            y: -7
            side: 1
        }

        // A cheek: a round puff over the bottom of the eye, outlined below
        // only, with a lighter blush
        component Cheek: Shape {
            id: cheek
            property int side: 1
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillColor: gf.orange
                startX: -8.5
                startY: 0
                PathArc {
                    x: 8.5
                    y: 0
                    radiusX: 8.5
                    radiusY: 8.5
                    useLargeArc: true
                }
                PathArc {
                    x: -8.5
                    y: 0
                    radiusX: 8.5
                    radiusY: 8.5
                    useLargeArc: true
                }
            }
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: -8 * cheek.side
                startY: -3
                PathArc {
                    x: 6 * cheek.side
                    y: 6
                    radiusX: 8.5
                    radiusY: 8.5
                    direction: cheek.side > 0 ? PathArc.Counterclockwise : PathArc.Clockwise
                }
            }
            ShapePath {
                strokeColor: "transparent"
                fillColor: gf.blush
                startX: -3.4
                startY: -1
                PathArc {
                    x: 3.4
                    y: -1
                    radiusX: 3.4
                    radiusY: 3.4
                    useLargeArc: true
                }
                PathArc {
                    x: -3.4
                    y: -1
                    radiusX: 3.4
                    radiusY: 3.4
                    useLargeArc: true
                }
            }
        }
        Cheek {
            x: -16
            y: 11
            side: -1
        }
        Cheek {
            x: 18
            y: 11
            side: 1
        }
        // The smile between the cheeks; it opens while he munches
        Shape {
            id: smile
            preferredRendererType: Shape.CurveRenderer
            readonly property real open: gf.p ? gf.p.mouth : 0
            ShapePath {
                strokeColor: gf.ink
                strokeWidth: 2.2
                fillColor: smile.open > 0.1 ? "#c8332b" : "transparent"
                capStyle: ShapePath.RoundCap
                startX: -7
                startY: 12
                PathQuad {
                    x: 9
                    y: 12
                    controlX: 1
                    controlY: 17 + 7 * smile.open
                }
            }
        }

        // The front fin, his near arm: rests at his side, waves hello,
        // scrubs the glass
        Fin {
            x: 30
            y: 27
            side: 1
            angle: gf.p ? Math.max(-20, -gf.p.fin * 1.5) : 0
        }

        // "z" while he sleeps
        Text {
            visible: !!gf.p && gf.p.asleep
            x: 22
            y: -62
            text: "z"
            font.pixelSize: 22
            color: gf.scene ? gf.scene.inkDim : "white"
            transform: Scale {
                xScale: gf.s && gf.s.dir > 0 ? 1 : -1
            }
        }
        MouseArea {
            x: -52
            y: -40
            width: 106
            height: 80
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Fish.wave(gf.fish);
                gf.frame++;
            }
        }
    }
}
