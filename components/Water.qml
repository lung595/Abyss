import QtQuick
import qs.Common
import "Layout.js" as Lay

// The still part of the deep: dark water from the surface to the floor (no
// sunlight reaches the abyss: only the creatures and the pointer's lamp
// light it), kelp on the floor and the sonar rings (how far a peer is, in ms).
// Painted once per size or theme; nothing here moves.
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
        // Above the surface (behind the top bar) and the water column: both
        // dark, the deep going to black
        ctx.fillStyle = shallow;
        ctx.fillRect(0, 0, w, sy);
        const sea = ctx.createLinearGradient(0, sy, 0, h);
        sea.addColorStop(0, shallow);
        sea.addColorStop(0.35, abyss);
        sea.addColorStop(1, Qt.darker(abyss, 1.5));
        ctx.fillStyle = sea;
        ctx.fillRect(0, sy, w, h - sy);
        // The surface itself, barely there
        ctx.strokeStyle = _rgba(ink, 0.12);
        ctx.lineWidth = 1;
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
        ctx.fillStyle = Qt.darker(abyss, 2.2);
        ctx.beginPath();
        ctx.moveTo(0, h);
        ctx.lineTo(0, f.floorY + 4);
        for (let x = 0; x <= w; x += 24)
            ctx.lineTo(x, f.floorY + 4 + Math.sin(x * 0.021) * 6 + Math.sin(x * 0.08) * 2);
        ctx.lineTo(w, h);
        ctx.closePath();
        ctx.fill();
        // A faint ridge line: the floor still reads against the black water
        ctx.strokeStyle = _rgba(ink, 0.07);
        ctx.beginPath();
        for (let x = 0; x <= w; x += 24)
            x ? ctx.lineTo(x, f.floorY + 4 + Math.sin(x * 0.021) * 6 + Math.sin(x * 0.08) * 2) : ctx.moveTo(x, f.floorY + 4);
        ctx.stroke();
        // Sonar rings: faint arcs under you, each labelled with its latency
        // band at its right end
        const labels = ["< " + Lay.RING_MS[0] + " ms", "< " + Lay.RING_MS[1] + " ms", Lay.RING_MS[1] + " ms +"];
        ctx.lineWidth = 1;
        ctx.font = "9px sans-serif";
        ctx.textAlign = "left";
        f.fan.rings.forEach((rho, k) => {
            ctx.strokeStyle = _rgba(ink, 0.09);
            ctx.beginPath();
            for (let d = 90 + Lay.HALF_SPAN + 8; d >= 90 - Lay.HALF_SPAN - 8; d -= 3) {
                const q = Lay.fanPoint(f, d, rho);
                d === 90 + Lay.HALF_SPAN + 8 ? ctx.moveTo(q.x, q.y) : ctx.lineTo(q.x, q.y);
            }
            ctx.stroke();
            const end = Lay.fanPoint(f, 90 - Lay.HALF_SPAN - 8, rho);
            ctx.fillStyle = _rgba(ink, 0.3);
            ctx.fillText(labels[k], Math.min(w - 44, end.x + 6), end.y + 3);
        });
    }
}
