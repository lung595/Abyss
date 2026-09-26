import QtQuick
import qs.Common

// A network (route) reached through a peer, drawn as a cave on the sea floor.
// Lit and full of little fish when the route is on. Click to switch it.
Item {
    id: cave

    property var scene
    property var net
    readonly property bool on: net.on && scene.connected

    signal toggled

    width: 0
    height: 0

    Halo {
        visible: cave.on
        width: 110
        height: 110
        x: -55
        y: -70
        color: Theme.tertiary
        strength: 0.5
    }
    Canvas {
        id: rock
        width: 96
        height: 56
        x: -48
        y: -52
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const d = cave.scene.abyss;
            c.fillStyle = Qt.darker(d, 1.1);
            c.beginPath();
            c.moveTo(0, 56);
            c.quadraticCurveTo(2, 4, 48, 2);
            c.quadraticCurveTo(94, 4, 96, 56);
            c.closePath();
            c.fill();
            c.fillStyle = "#010205";
            c.beginPath();
            c.moveTo(24, 56);
            c.quadraticCurveTo(25, 22, 48, 20);
            c.quadraticCurveTo(71, 22, 72, 56);
            c.closePath();
            c.fill();
            if (cave.on) {
                const t = Theme.tertiary;
                c.fillStyle = Qt.rgba(t.r, t.g, t.b, 0.9);
                for (let k = 0; k < 12; k++) {
                    const a = k * 0.52;
                    c.beginPath();
                    c.ellipse(48 + Math.cos(a) * 14 - 2.4, 42 + Math.sin(a * 1.3) * 8 - 1.2, 4.8, 2.4);
                    c.fill();
                }
            }
        }
        Connections {
            target: cave
            function onOnChanged() {
                rock.requestPaint();
            }
        }
    }
    Chip {
        id: label
        x: -width / 2
        y: -86
        title: cave.net.id
        titleSize: 11
        sub: !caveArea.containsMouse ? "" : cave.on || !cave.scene.connected ? cave.net.cidr : "click to open"
        ink: cave.on ? cave.scene.abyss : cave.scene.ink
        subInk: cave.on ? Qt.rgba(cave.scene.abyss.r, cave.scene.abyss.g, cave.scene.abyss.b, 0.75) : cave.scene.inkDim
        color: cave.on ? Theme.tertiary : Qt.rgba(cave.scene.abyss.r, cave.scene.abyss.g, cave.scene.abyss.b, 0.66)
    }
    MouseArea {
        id: caveArea
        x: -50
        y: -90
        width: 100
        height: 94
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cave.toggled()
    }
}
