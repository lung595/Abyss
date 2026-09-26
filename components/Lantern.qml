import QtQuick
import qs.Common

// A relay: a coral lantern the tentacles of relayed peers go through. It
// flickers in warning colour when the relay stops answering.
Item {
    id: lantern

    property var scene
    property string name: ""
    property bool down: false
    property bool flash: false
    property color tint: Theme.primary

    readonly property color col: down ? Theme.warning : tint
    // Flicker only while the scene clock runs (no animation of its own)
    readonly property real flicker: down && scene.flowing ? (Math.sin(scene.t * 13) > 0.2 ? 1 : 0.35) : 1

    width: 0
    height: 0

    Halo {
        width: 90
        height: 90
        x: -45
        y: -45
        color: lantern.col
        opacity: (lantern.scene.connected ? 0.8 : 0.15) * lantern.flicker
    }
    Canvas {
        id: coral
        width: 48
        height: 44
        x: -24
        y: -26
        opacity: lantern.flicker
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const col = lantern.col;
            c.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.85);
            c.fillStyle = Qt.lighter(col, 1.3);
            c.lineWidth = 2;
            for (let k = 0; k < 5; k++) {
                const a = -Math.PI / 2 + (k - 2) * 0.45;
                const ex = 24 + Math.cos(a) * 19, ey = 30 + Math.sin(a) * 19;
                c.beginPath();
                c.moveTo(24, 42);
                c.quadraticCurveTo(24 + Math.cos(a) * 8, 30 + Math.sin(a) * 8, ex, ey);
                c.stroke();
                c.beginPath();
                c.arc(ex, ey, 3, 0, Math.PI * 2);
                c.fill();
            }
        }
        Connections {
            target: lantern
            function onColChanged() {
                coral.requestPaint();
            }
        }
    }
    Chip {
        visible: lantern.down
        x: -width / 2
        y: 20
        title: (lantern.down ? "⚠ " : "") + lantern.name
        titleSize: 10
        ink: lantern.down ? lantern.scene.abyss : lantern.scene.inkDim
        color: lantern.down ? Theme.warning : Qt.rgba(lantern.scene.abyss.r, lantern.scene.abyss.g, lantern.scene.abyss.b, 0.6)
        border.width: lantern.flash ? 2 : 0
        border.color: Theme.warning
    }
}
