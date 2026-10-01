import QtQuick
import qs.Common
import "Bowl.js" as Bowl
import "Mesh.js" as Mesh

// Who is online and the live totals, written in the bowl's bed like the
// sand bottles of a seaside shop: a sand of another colour (the theme's
// accent) poured against the glass, so the letters show in the side of the
// bed, following its curve, behind the front glass and its highlights.
// Fine and quiet: small light letters, their edges a little loose and
// peppered with lighter, darker and missing grains. Painted only when the
// text changes; nothing runs.
Canvas {
    id: sand

    // Bowl.build() for this size, in the parent's coordinates
    property var b
    property var scene
    readonly property var v: scene.view
    // "test lab" first while the mesh is made up, so it is never taken for yours
    readonly property string label: (scene.lab ? "test lab  ·  " : "") + _status
    readonly property string _status: v.state === "connected" ? v.online + "/" + v.total + " online  ·  ↓ " + Mesh.fmtRate(v.down) + "  ↑ " + Mesh.fmtRate(v.up) : ({
            "connecting": "connecting…",
            "needsLogin": "sign-in needed",
            "stopped": "NetBird is off"
        })[v.state] || "disconnected"
    readonly property color hue: Theme.primary

    // A band over the side of the bed (in the parent's coordinates)
    x: b.cx - b.rx
    y: b.gravelY - 4
    width: 2 * b.rx
    height: b.baseY - b.gravelY + 8
    // Dims with the water while a card is open
    opacity: 1 - 0.7 * scene.cardMix

    onLabelChanged: requestPaint()
    onHueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // The same grains on every repaint, so changing figures do not make
    // the whole line fizz
    function _rng(seed) {
        let s = seed;
        return () => {
            s = (s * 16807) % 2147483647;
            return (s - 1) / 2147483646;
        };
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        // Small, light and airy: a fine line in the bed, not a sign
        const size = 12, gap = 1.6;
        ctx.font = "500 " + size + "px \"" + Theme.fontFamily + "\"";
        // (Canvas ignores a family it does not know and falls back to 10 px)
        if (ctx.font.indexOf(Theme.fontFamily) !== 0)
            ctx.font = "500 " + size + "px sans-serif";
        ctx.textBaseline = "middle";
        const chars = label.split("");
        const widths = chars.map(c => ctx.measureText(c).width + gap);
        const run = widths.reduce((a, w) => a + w, 0);
        // The middle of the bed's side at x, in this canvas
        const mid = x => (Bowl.sandFront(b, x + sand.x) + b.baseY) / 2 - sand.y;
        const left = (width - run) / 2;
        let x = left;

        // The coloured sand, its edges a little loose
        ctx.fillStyle = hue;
        chars.forEach((c, i) => {
            if (c !== " ") {
                const cx = x + widths[i] / 2;
                ctx.save();
                ctx.translate(x, mid(cx));
                ctx.rotate(Math.atan((mid(cx + 4) - mid(cx - 4)) / 8));
                ctx.globalAlpha = 0.15;
                [[-0.5, 0], [0.5, 0], [0, -0.5], [0, 0.5]].forEach(d => ctx.fillText(c, d[0], d[1]));
                ctx.globalAlpha = 0.75;
                ctx.fillText(c, 0, 0);
                ctx.restore();
            }
            x += widths[i];
        });

        // Lighter and darker grains in it, and a few missing
        const r = _rng(97), top = mid(width / 2) - size, h = 2 * size;
        const count = Math.round(run * h / 6);
        const light = Qt.lighter(hue, 1.35), dark = Qt.darker(hue, 1.5);
        ctx.globalCompositeOperation = "source-atop";
        for (let i = 0; i < count; i++) {
            ctx.globalAlpha = 0.2 + 0.4 * r();
            ctx.fillStyle = r() < 0.5 ? light : dark;
            ctx.fillRect(left + r() * run, top + r() * h, 1, 1);
        }
        ctx.globalCompositeOperation = "destination-out";
        for (let i = 0; i < count / 8; i++) {
            ctx.globalAlpha = 0.3 + 0.4 * r();
            ctx.fillRect(left + r() * run, top + r() * h, 1, 1);
        }
    }
}
