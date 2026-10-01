import QtQuick
import "Goldfish.js" as Fish

// Darwin, the goldfish companion (Goldfish.js is his life; this draws it).
// His picture is the one from the show, cut out of the reference images
// (assets/darwin/): the body with the face, and two hands that move on
// their own. Only transforms change as he moves; his lids, and the mouth
// he opens to eat, are drawn over the picture.
Item {
    id: gf

    property var scene
    // The Goldfish.js state, and a counter the scene bumps after each step
    // (the state is changed in place, so bindings need the nudge)
    property var fish: null
    property int frame: 0

    readonly property var s: frame >= 0 ? fish : null
    readonly property var p: s ? Fish.pose(s, scene.t) : null
    // The orange of the picture, for the lids drawn over it
    readonly property color orange: "#ff7a12"
    readonly property color ink: "#1c1a24"
    // The picture is 729 px wide; he is about 25 px on screen
    readonly property real unit: 0.034

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

    // Darwin himself, as in the picture: tail to the left, face a little to
    // the right. (0, 0) is the middle of the picture (729 x 483)
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
                yScale: gf.unit * (1 + (gf.p ? gf.p.tail * 0.0012 : 0))
            }
        ]

        // His hands, behind him: they hang from under his body. Rest low;
        // the front one waves hello, scrubs the glass
        Image {
            id: handBack
            source: "assets/darwin/hand_l.png"
            smooth: true
            mipmap: true
            width: 200
            height: 158
            x: -230
            y: 140
            z: -1
            transformOrigin: Item.TopRight
            rotation: gf.p ? gf.p.arms * 0.8 : 0
        }
        Image {
            id: handFront
            source: "assets/darwin/hand_r.png"
            smooth: true
            mipmap: true
            width: 185
            height: 139
            x: 60
            y: 150
            z: -1
            transformOrigin: Item.TopLeft
            // Waving swings it up and out; rest hangs at his side
            rotation: gf.p ? -(gf.p.fin * 1.1 + 15) : 0
        }

        Image {
            id: picture
            source: "assets/darwin/body.png"
            smooth: true
            mipmap: true
            x: -364.5
            y: -241.5
            width: 729
            height: 483
        }

        // Lids: shut when he sleeps or blinks (the eyes of the picture stay
        // underneath), with the curve of a closed eye
        component Lid: Item {
            id: lid
            // The eye's middle and size in the picture
            property real cx: 0
            property real cy: 0
            property real rx: 100
            property real ry: 80
            visible: !!gf.p && gf.p.lid > 0.5
            Rectangle {
                x: lid.cx - lid.rx
                y: lid.cy - lid.ry
                width: lid.rx * 2
                height: lid.ry * 2
                radius: lid.ry
                color: gf.orange
            }
            Rectangle {
                x: lid.cx - lid.rx * 0.55
                y: lid.cy + lid.ry * 0.1
                width: lid.rx * 1.24
                height: 16
                radius: 8
                color: gf.ink
                clip: true
            }
        }
        // (the eyes of the picture: left x 177-362, y 98-270; right x 409-581, y 91-256)
        Lid {
            cx: -364.5 + 270
            cy: -241.5 + 184
            rx: 104
            ry: 97
        }
        Lid {
            cx: -364.5 + 495
            cy: -241.5 + 174
            rx: 98
            ry: 94
        }
        // The cheeks of the picture again, over the lids (they overlap the
        // lower part of the eyes)
        Image {
            visible: !!gf.p && gf.p.lid > 0.5
            source: "assets/darwin/body.png"
            smooth: true
            mipmap: true
            sourceClipRect: Qt.rect(150, 252, 470, 215)
            x: -364.5 + 150
            y: -241.5 + 252
            width: 470
            height: 215
        }

        // The mouth he opens to eat: over his smile (x 355-440, y 322)
        Item {
            // (not while asleep, when his mouth is barely moving)
            visible: !!gf.p && gf.p.mouth > 0.35 && !gf.p.asleep
            x: -364.5 + 398
            y: -241.5 + 330
            Rectangle {
                readonly property real o: gf.p ? gf.p.mouth : 0
                x: -52
                y: -12
                width: 104
                height: 20 + 70 * o
                radius: 26
                color: "#d9322c"
                border.width: 8
                border.color: gf.ink
            }
        }

        // "z" while he sleeps
        Text {
            visible: !!gf.p && gf.p.asleep
            x: 240
            y: -330
            text: "z"
            font.pixelSize: 260
            color: gf.scene ? gf.scene.inkDim : "white"
            transform: Scale {
                xScale: gf.s && gf.s.dir > 0 ? 1 : -1
            }
        }
        MouseArea {
            x: -364
            y: -241
            width: 729
            height: 483
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Fish.wave(gf.fish);
                gf.frame++;
            }
        }
    }
}
