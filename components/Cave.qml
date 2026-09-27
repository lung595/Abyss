import QtQuick
import qs.Common

// A network (route) reached through a peer, drawn as a cave on the sea floor.
// Its rim always catches a little light so it reads against the black water;
// on, it glows and its mouth burns warm, full of little fish. Click to switch
// it. Painted once per look: the switch is a crossfade of the lit layer.
Item {
    id: cave

    property var scene
    property var net
    readonly property bool on: net.on && scene.connected
    // The pointer is over the cave or its label (the scene then shows its thread)
    readonly property bool hovered: caveArea.containsMouse

    signal toggled

    // A hovered label may be wider than the cave: keep it above its neighbours
    z: hovered ? 1 : 0
    width: 0
    height: 0

    readonly property int _fade: scene && scene.reduceMotion ? 0 : 450
    // The warm heart of a lit mouth: the theme's accent, sunlit
    readonly property color _ember: scene ? scene.mix(Theme.tertiary, scene.sunColor, 0.35) : Theme.tertiary

    // The rock's outline and its mouth, in the canvases' coordinates (the
    // cave's foot is at (56, 60))
    function rockPath(c) {
        c.beginPath();
        c.moveTo(8, 60);
        c.bezierCurveTo(8, 26, 30, 9, 58, 9);
        c.bezierCurveTo(84, 9, 104, 28, 104, 60);
    }
    function mouthPath(c) {
        c.beginPath();
        c.moveTo(32, 60);
        c.bezierCurveTo(32, 38, 42, 28, 56, 28);
        c.bezierCurveTo(70, 28, 80, 38, 80, 60);
    }
    // A vertical fade of a colour, strongest at the top of the rock
    function rimFade(c, col, al) {
        const g = c.createLinearGradient(0, 9, 0, 60);
        g.addColorStop(0, Qt.rgba(col.r, col.g, col.b, al));
        g.addColorStop(0.6, Qt.rgba(col.r, col.g, col.b, al * 0.45));
        g.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0));
        return g;
    }

    // Always a faint light around it, brighter under the pointer
    Halo {
        width: 140
        height: 90
        x: -70
        y: -70
        color: cave.scene.ink
        strength: 0.16
        opacity: cave.on ? 0 : cave.hovered ? 1 : 0.6
        Behavior on opacity {
            NumberAnimation {
                duration: cave._fade
            }
        }
    }
    // On: the accent's glow over the whole cave
    Halo {
        width: 170
        height: 120
        x: -85
        y: -92
        color: Theme.tertiary
        strength: 0.5
        opacity: cave.on ? (cave.hovered ? 1 : 0.8) : 0
        Behavior on opacity {
            NumberAnimation {
                duration: cave._fade
            }
        }
    }

    // The rock itself, dark with a thin lit rim (the same on or off)
    Canvas {
        id: rock
        width: 112
        height: 64
        x: -56
        y: -60
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const d = cave.scene.abyss, ink = cave.scene.ink;
            // Lighter at the crown, sinking into the floor's colour at the foot
            const body = c.createLinearGradient(0, 9, 0, 60);
            body.addColorStop(0, cave.scene.mix(d, ink, 0.1));
            body.addColorStop(1, Qt.darker(d, 2.2));
            cave.rockPath(c);
            c.closePath();
            c.fillStyle = body;
            c.fill();
            // Faint strata: rock, not a blob
            c.lineWidth = 1;
            c.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, 0.05);
            for (let k = 0; k < 2; k++) {
                c.beginPath();
                c.moveTo(18 + k * 4, 44 - k * 12);
                c.quadraticCurveTo(30, 30 - k * 12, 44 + k * 6, 26 - k * 10);
                c.stroke();
            }
            // The mouth: deep black inside
            cave.mouthPath(c);
            c.closePath();
            c.fillStyle = Qt.darker(d, 4);
            c.fill();
            // The rim light, on the outline and around the mouth
            cave.rockPath(c);
            c.strokeStyle = cave.rimFade(c, ink, 0.07);
            c.lineWidth = 5;
            c.stroke();
            c.strokeStyle = cave.rimFade(c, ink, 0.4);
            c.lineWidth = 1.2;
            c.stroke();
            cave.mouthPath(c);
            c.strokeStyle = cave.rimFade(c, ink, 0.16);
            c.lineWidth = 1;
            c.stroke();
        }
        Connections {
            target: cave.scene
            function onAbyssChanged() {
                rock.requestPaint();
            }
            function onInkChanged() {
                rock.requestPaint();
            }
        }
    }

    // The lit layer: the accent along the rim, a warm glowing mouth and its
    // fish. Painted once; switching fades it in or out.
    Canvas {
        id: lit
        width: 112
        height: 64
        x: -56
        y: -60
        opacity: cave.on ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: cave._fade
                easing.type: Easing.InOutQuad
            }
        }
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const t = Theme.tertiary, e = cave._ember;
            // The mouth burns from its floor up
            const glow = c.createRadialGradient(56, 62, 2, 56, 58, 36);
            glow.addColorStop(0, Qt.rgba(Qt.lighter(e, 1.3).r, Qt.lighter(e, 1.3).g, Qt.lighter(e, 1.3).b, 0.95));
            glow.addColorStop(0.45, Qt.rgba(e.r, e.g, e.b, 0.6));
            glow.addColorStop(1, Qt.rgba(t.r, t.g, t.b, 0.08));
            cave.mouthPath(c);
            c.closePath();
            c.fillStyle = glow;
            c.fill();
            // A little shoal, dark against the glow
            const fish = cave.scene.mix(cave.scene.abyss, t, 0.2);
            c.fillStyle = Qt.rgba(fish.r, fish.g, fish.b, 0.85);
            const shoal = [[48, 46, 1], [58, 42, -1], [64, 50, -1], [52, 54, 1], [44, 52, 1], [61, 56, -1]];
            shoal.forEach(f => {
                const [fx, fy, dir] = f;
                c.beginPath();
                c.ellipse(fx - 3, fy - 1.3, 6, 2.6);
                c.fill();
                c.beginPath();
                c.moveTo(fx - dir * 2.5, fy);
                c.lineTo(fx - dir * 5.5, fy - 2);
                c.lineTo(fx - dir * 5.5, fy + 2);
                c.closePath();
                c.fill();
            });
            // The rim catches the accent: a soft halo, then a bright edge
            cave.rockPath(c);
            c.strokeStyle = cave.rimFade(c, t, 0.14);
            c.lineWidth = 7;
            c.stroke();
            c.strokeStyle = cave.rimFade(c, Qt.lighter(t, 1.2), 0.9);
            c.lineWidth = 1.4;
            c.stroke();
            cave.mouthPath(c);
            c.strokeStyle = cave.rimFade(c, Qt.lighter(e, 1.4), 0.75);
            c.lineWidth = 1.2;
            c.stroke();
        }
        Connections {
            target: cave
            function on_EmberChanged() {
                lit.requestPaint();
            }
        }
    }
    // The mouth's light spills onto the floor in front of it
    Halo {
        width: 80
        height: 36
        x: -40
        y: -20
        color: cave._ember
        strength: 0.45
        opacity: cave.on ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: cave._fade
            }
        }
    }

    Chip {
        id: label
        // Above the rock, kept inside the deep when it widens on hover
        x: Math.max(-cave.x + 6, Math.min(-width / 2, (cave.parent ? cave.parent.width : 1e6) - cave.x - width - 6))
        y: -60 - height
        title: cave.net.id
        titleSize: 11
        sub: !cave.hovered ? "" : !cave.scene.connected ? cave.net.cidr : (cave.net.via ? "via " + cave.net.via + " · " : "") + (cave.on ? "click to switch off" : "click to switch on")
        ink: cave.on ? cave.scene.abyss : cave.scene.ink
        subInk: cave.on ? Qt.rgba(cave.scene.abyss.r, cave.scene.abyss.g, cave.scene.abyss.b, 0.75) : cave.scene.inkDim
        color: cave.on ? Theme.tertiary : Qt.rgba(cave.scene.abyss.r, cave.scene.abyss.g, cave.scene.abyss.b, 0.66)
    }
    MouseArea {
        id: caveArea
        x: -52
        y: label.y - 4
        width: 104
        height: 4 - y
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cave.toggled()
    }
}
