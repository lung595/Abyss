import QtQuick

// The Internet light falling from the surface onto the peer that lends it:
// a soft beam, narrow under the sun and opening as it goes down, with a few
// brighter streaks, fading before it reaches the peer, and a small pool of
// light on it. Painted once per colour at a fixed size and only stretched
// to fit: moving it costs nothing.
Item {
    id: shaft

    property color color: "white"
    // Where the light lands, and the surface it falls from (parent coordinates)
    property real toX: 0
    property real toY: 0
    property real fromY: 0

    readonly property real spread: 64
    x: toX - spread / 2
    y: fromY
    width: spread
    height: Math.max(0, toY - fromY)

    Canvas {
        id: beam
        // Painted at this size, then stretched over the shaft
        width: 64
        height: 256
        transform: Scale {
            xScale: shaft.width / beam.width
            yScale: shaft.height / beam.height
        }

        onPaint: {
            const c = getContext("2d"), w = width, h = height, col = shaft.color;
            c.reset();
            // Many faint, ever narrower beams: bright in the middle, soft sides
            const layers = 14;
            for (let i = 1; i <= layers; i++) {
                const k = i / layers, top = w * 0.1 * k, bottom = w * 0.5 * k;
                c.beginPath();
                c.moveTo(w / 2 - top, 0);
                c.lineTo(w / 2 + top, 0);
                c.lineTo(w / 2 + bottom, h);
                c.lineTo(w / 2 - bottom, h);
                c.closePath();
                c.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.035);
                c.fill();
            }
            // A few brighter streaks through the water
            [[-0.22, 0.05], [0.08, 0.07], [0.3, 0.04]].forEach(s => {
                c.beginPath();
                c.moveTo(w / 2 + s[0] * w * 0.2, 0);
                c.lineTo(w / 2 + s[0] * w * 0.2 + 1.5, 0);
                c.lineTo(w / 2 + s[0] * w * 0.9 + 3, h);
                c.lineTo(w / 2 + s[0] * w * 0.9, h);
                c.closePath();
                c.fillStyle = Qt.rgba(col.r, col.g, col.b, s[1]);
                c.fill();
            });
            // Strong under the sun, gone before the peer
            c.globalCompositeOperation = "destination-in";
            const fade = c.createLinearGradient(0, 0, 0, h);
            fade.addColorStop(0, "rgba(0,0,0,1)");
            fade.addColorStop(0.55, "rgba(0,0,0,0.6)");
            fade.addColorStop(1, "rgba(0,0,0,0)");
            c.fillStyle = fade;
            c.fillRect(0, 0, w, h);
        }
    }
    onColorChanged: beam.requestPaint()

    // The pool of light on the peer
    Halo {
        width: 76
        height: 40
        x: (shaft.width - width) / 2
        y: shaft.height - height / 2
        color: shaft.color
        strength: 0.22
    }
}
