import QtQuick
import qs.Common
import "Mesh.js" as Mesh

// Who is online and the live totals, scratched into the fishbowl's glass
// in front of the sand. The bowl has no bar over the water: the jellyfish
// connects on click, and its right-click menu holds the rest.
// A cut, not ink: lit from above, a groove shows its shadow on the upper
// edge and catches the light on the lower one, over a frosted (matte,
// milky) bed; a little askew as if cut by hand, among a few fine scratches. Painted only when the text
// changes; nothing runs.
Canvas {
    id: cut

    // Bowl.build() for this size, in the parent's coordinates
    property var b
    property var scene
    readonly property var v: scene.view
    readonly property string label: v.state === "connected" ? v.online + "/" + v.total + " online  ·  ↓ " + Mesh.fmtRate(v.down) + "  ↑ " + Mesh.fmtRate(v.up) : ({
            "connecting": "connecting…",
            "needsLogin": "sign-in needed",
            "stopped": "NetBird is off"
        })[v.state] || "disconnected"
    readonly property color ink: scene.ink

    width: Math.min(420, b.rx * 1.4)
    height: 38
    x: b.cx - width / 2
    y: (b.gravelY + b.baseY) / 2 - height / 2
    rotation: -1.5
    // Fades with the glass while a card is open
    opacity: 1 - 0.8 * scene.cardMix

    onLabelChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()

    // The same small wobble for the same letter slot on every repaint, so
    // changing figures do not make the whole line shiver
    function _wobble(i, k) {
        const s = Math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
        return (s - Math.floor(s)) * 2 - 1;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const size = 15, gap = 1.8;
        ctx.font = "600 " + size + "px \"" + Theme.fontFamily + "\"";
        const chars = label.split("");
        const widths = chars.map(c => ctx.measureText(c).width + gap);
        let x = (width - widths.reduce((a, w) => a + w, 0)) / 2;
        const base = height / 2 + size * 0.36;
        const lip = Qt.rgba(ink.r, ink.g, ink.b, 0.46);
        const frost = Qt.rgba(ink.r, ink.g, ink.b, 0.13);
        const groove = Qt.rgba(0, 0, 0, 0.8);

        // A few fine scratches the glass picked up around the lettering
        ctx.lineWidth = 0.6;
        for (let k = 0; k < 11; k++) {
            const sx = width * (0.5 + 0.5 * _wobble(k, 1)), sy = height * (0.5 + 0.45 * _wobble(k, 2));
            const len = 10 + 26 * Math.abs(_wobble(k, 3)), a = 0.25 * _wobble(k, 4);
            ctx.beginPath();
            ctx.moveTo(sx, sy);
            ctx.lineTo(sx + len * Math.cos(a), sy + len * Math.sin(a));
            ctx.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, 0.08 + 0.1 * Math.abs(_wobble(k, 5)));
            ctx.stroke();
        }

        chars.forEach((c, i) => {
            if (c !== " ") {
                ctx.save();
                ctx.translate(x, base + 0.8 * _wobble(i, 6));
                ctx.rotate(0.05 * _wobble(i, 7));
                // The lit lower edge, the shadowed upper edge, the frosted bed
                ctx.fillStyle = lip;
                ctx.fillText(c, 0, 1);
                ctx.fillStyle = groove;
                ctx.fillText(c, 0, -1);
                ctx.fillStyle = frost;
                ctx.fillText(c, 0, 0);
                ctx.restore();
            }
            x += widths[i];
        });
    }
}
