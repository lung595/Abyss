import QtQuick
import qs.Common
import "Mesh.js" as Mesh

// The still part of the deep: water from the surface to the floor, light
// rays, kelp, the sea floor and the latency gauge. Painted once per size or
// theme; nothing here moves.
Canvas {
    id: water

    property var scene
    property var frame
    property color shallow
    property color abyss
    property color ink
    property color kelp

    onFrameChanged: requestPaint()
    onShallowChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function _rgba(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    onPaint: {
        const ctx = getContext("2d");
        const f = frame;
        if (!f)
            return;
        const w = width, h = height, sy = f.surfaceY;
        ctx.reset();
        // Air above the surface (behind the top bar), then the water column
        const air = ctx.createLinearGradient(0, 0, 0, sy);
        air.addColorStop(0, Qt.lighter(shallow, 1.5));
        air.addColorStop(1, Qt.lighter(shallow, 1.15));
        ctx.fillStyle = air;
        ctx.fillRect(0, 0, w, sy);
        const sea = ctx.createLinearGradient(0, sy, 0, h);
        sea.addColorStop(0, shallow);
        sea.addColorStop(0.45, Qt.darker(shallow, 1.9));
        sea.addColorStop(1, abyss);
        ctx.fillStyle = sea;
        ctx.fillRect(0, sy, w, h - sy);
        // Light rays from the surface, fading before the floor
        for (let k = 0; k < 6; k++) {
            const x0 = w * (0.08 + k * 0.17);
            const g = ctx.createLinearGradient(0, sy, 0, f.floorY - 40);
            g.addColorStop(0, _rgba(ink, 0.09));
            g.addColorStop(1, _rgba(ink, 0));
            ctx.fillStyle = g;
            ctx.beginPath();
            ctx.moveTo(x0, sy);
            ctx.lineTo(x0 + w * 0.04, sy);
            ctx.lineTo(x0 + w * 0.14, f.floorY - 40);
            ctx.lineTo(x0 + w * 0.03, f.floorY - 40);
            ctx.closePath();
            ctx.fill();
        }
        // The surface itself
        ctx.strokeStyle = _rgba(ink, 0.4);
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        for (let x = 0; x <= w; x += 10)
            x ? ctx.lineTo(x, sy + Math.sin(x * 0.045) * 1.6) : ctx.moveTo(x, sy);
        ctx.stroke();
        // Kelp, then the floor in front of it
        for (let k = 0; k < Math.floor(w / 46); k++) {
            const kx = 18 + k * 46 + (k % 3) * 9, kh = 26 + (k * 37) % 52;
            ctx.beginPath();
            ctx.moveTo(kx, f.floorY + 8);
            ctx.quadraticCurveTo(kx + 7 - (k % 2) * 14, f.floorY - kh / 2, kx + 2, f.floorY - kh);
            ctx.strokeStyle = _rgba(kelp, 0.5);
            ctx.lineWidth = 2.5;
            ctx.stroke();
        }
        ctx.fillStyle = Qt.darker(abyss, 1.4);
        ctx.beginPath();
        ctx.moveTo(0, h);
        ctx.lineTo(0, f.floorY + 4);
        for (let x = 0; x <= w; x += 24)
            ctx.lineTo(x, f.floorY + 4 + Math.sin(x * 0.021) * 6 + Math.sin(x * 0.08) * 2);
        ctx.lineTo(w, h);
        ctx.closePath();
        ctx.fill();
        // Latency gauge: depth means milliseconds
        const gx = w - 16;
        ctx.strokeStyle = _rgba(ink, 0.2);
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(gx, f.bandTop);
        ctx.lineTo(gx, f.bandBottom);
        ctx.stroke();
        ctx.fillStyle = _rgba(ink, 0.42);
        ctx.font = "9px sans-serif";
        ctx.textAlign = "right";
        [1, 10, 100, 300].forEach(ms => {
            const y = f.bandTop + Mesh.depthOf(ms) * (f.bandBottom - f.bandTop);
            ctx.beginPath();
            ctx.moveTo(gx - 4, y);
            ctx.lineTo(gx + 4, y);
            ctx.stroke();
            ctx.fillText(ms + " ms", gx - 7, y + 3);
        });
    }
}
