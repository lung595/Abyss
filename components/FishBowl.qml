import QtQuick
import "Bowl.js" as Bowl
import "ReefPlan.js" as Plan

// The desktop fishbowl around the deep, in two layers: "back" (its shadow on
// the desk, the far glass, the water and the colourful gravel) under the
// scene, "front" (the near edge of the surface, the glass and its rim, the
// reflections) over it. All colours come from the theme. Painted once per
// size or theme; nothing here moves.
Canvas {
    id: bowl

    // "back" or "front"
    property string part: "back"
    // Bowl.build() for this size
    property var b
    property color ink
    property color shallow
    property color abyss
    property var tints: []

    onBChanged: requestPaint()
    onInkChanged: requestPaint()
    onAbyssChanged: requestPaint()
    onTintsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function _rgba(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function _path(ctx, pts) {
        ctx.beginPath();
        pts.forEach((q, i) => i ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1]));
        ctx.closePath();
    }
    function _ellipse(ctx, x, y, rx, ry, from, to) {
        ctx.save();
        ctx.translate(x, y);
        ctx.scale(1, ry / rx);
        ctx.beginPath();
        ctx.arc(0, 0, rx, from, to, false);
        ctx.restore();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (!b)
            return;
        ctx.lineCap = "round";
        if (part === "back")
            _back(ctx);
        else
            _front(ctx);
    }

    function _back(ctx) {
        // A soft shadow on the desk
        ctx.save();
        ctx.translate(b.cx, b.baseY + 4);
        ctx.scale(1, 0.12);
        const sh = ctx.createRadialGradient(0, 0, 0, 0, 0, b.rx * 0.8);
        sh.addColorStop(0, "rgba(0,0,0,0.35)");
        sh.addColorStop(1, "rgba(0,0,0,0)");
        ctx.fillStyle = sh;
        ctx.fillRect(-b.rx, -b.rx, 2 * b.rx, 2 * b.rx);
        ctx.restore();
        // The far glass: barely tinted, the wallpaper shows through
        _path(ctx, b.outline);
        ctx.fillStyle = _rgba(ink, 0.05);
        ctx.fill();
        // The far half of the rim
        _ellipse(ctx, b.cx, b.rimY, b.rim.rx, b.rim.ry, Math.PI, 2 * Math.PI);
        ctx.strokeStyle = _rgba(ink, 0.22);
        ctx.lineWidth = 2;
        ctx.stroke();
        // The water: the deep's colours, darker towards the bottom
        _path(ctx, b.water);
        const sea = ctx.createLinearGradient(0, b.surfaceY, 0, b.baseY);
        sea.addColorStop(0, _rgba(shallow, 0.94));
        sea.addColorStop(0.35, _rgba(abyss, 0.96));
        sea.addColorStop(1, Qt.darker(abyss, 1.5));
        ctx.fillStyle = sea;
        ctx.fill();
        // The surface seen from a little above: a lighter oval
        _ellipse(ctx, b.cx, b.surfaceY, b.surface.rx, b.surface.ry, 0, 2 * Math.PI);
        ctx.fillStyle = _rgba(ink, 0.07);
        ctx.fill();
        _gravel(ctx);
    }

    // Colourful gravel heaped a little in the middle, pebbles in the theme's
    // accents, darker towards the back; the same pebbles every time
    function _gravel(ctx) {
        ctx.save();
        _path(ctx, b.water);
        ctx.clip();
        const r = Plan.rng(11), top = x => b.gravelY - 10 * Math.cos((x - b.cx) / b.rx * Math.PI / 2);
        ctx.fillStyle = Qt.darker(abyss, 1.8);
        ctx.beginPath();
        ctx.moveTo(b.cx - b.rx, b.baseY);
        for (let x = b.cx - b.rx; x <= b.cx + b.rx; x += 8)
            ctx.lineTo(x, top(x));
        ctx.lineTo(b.cx + b.rx, b.baseY + 2);
        ctx.closePath();
        ctx.fill();
        const n = Math.round(b.rx * (b.baseY - b.gravelY) / 14);
        const colours = tints.length ? tints : [ink];
        for (let i = 0; i < n; i++) {
            const x = b.cx - b.rx + r() * 2 * b.rx, y0 = top(x);
            const y = y0 + Math.pow(r(), 0.8) * (b.baseY - y0), s = 2.6 + r() * 2.6;
            const back = 1 - (y - y0) / Math.max(1, b.baseY - y0);
            const c = colours[Math.floor(r() * colours.length)];
            ctx.save();
            ctx.translate(x, y);
            ctx.rotate(r() * Math.PI);
            ctx.scale(1, 0.62);
            ctx.beginPath();
            ctx.arc(0, 0, s, 0, 2 * Math.PI);
            ctx.fillStyle = _rgba(Qt.darker(c, 1 + back * 0.9), 0.95);
            ctx.fill();
            ctx.restore();
        }
        ctx.restore();
    }

    function _front(ctx) {
        // The near edge of the surface
        _ellipse(ctx, b.cx, b.surfaceY, b.surface.rx, b.surface.ry, 0, Math.PI);
        ctx.strokeStyle = _rgba(ink, 0.3);
        ctx.lineWidth = 1.2;
        ctx.stroke();
        // The glass itself
        ctx.beginPath();
        b.outline.forEach((q, i) => i ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1]));
        ctx.strokeStyle = _rgba(ink, 0.28);
        ctx.lineWidth = 2;
        ctx.stroke();
        // The near half of the rim, thicker: the lip of the bowl
        _ellipse(ctx, b.cx, b.rimY, b.rim.rx, b.rim.ry, 0, Math.PI);
        ctx.strokeStyle = _rgba(ink, 0.5);
        ctx.lineWidth = 3;
        ctx.stroke();
        // Reflections: a long curved one on the left, a short one on the right
        const shine = (from, to, k, a, wdt) => {
            _ellipse(ctx, b.cx, b.cy, b.rx * k, b.ry * k, from, to);
            ctx.strokeStyle = _rgba(ink, a);
            ctx.lineWidth = wdt;
            ctx.stroke();
        };
        shine(Math.PI * 1.02, Math.PI * 1.26, 0.88, 0.22, Math.max(6, b.rx * 0.05));
        shine(Math.PI * 1.3, Math.PI * 1.34, 0.88, 0.16, Math.max(6, b.rx * 0.05));
        shine(Math.PI * 1.8, Math.PI * 1.9, 0.9, 0.12, Math.max(3, b.rx * 0.022));
    }
}
