import QtQuick
import "Bowl.js" as Bowl
import "ReefPlan.js" as Plan

// The desktop fishbowl around the deep, in two layers: "back" (its shadow on
// the desk, the far glass, the water and its bed of sand) under the
// scene, "front" (the near edge of the surface, the glass and its rim, the
// reflections) over it. All colours come from the theme. Painted once per
// size or theme; nothing here moves.
Canvas {
    id: bowl

    // "back", "shade" (the water in the deep's darkest colour: faded in over
    // the back while a group is open, only its opacity changes) or "front"
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
        else if (part === "shade") {
            _path(ctx, b.water);
            ctx.fillStyle = Qt.darker(abyss, 1.4);
            ctx.fill();
        } else
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

    // Mixes two colours (t = 0: a, 1: b)
    function _mix(a, c, t) {
        return Qt.rgba(a.r + (c.r - a.r) * t, a.g + (c.g - a.g) * t, a.b + (c.b - a.b) * t, 1);
    }

    // A bed of deep sand, heaped a little in the middle, in the deep's own
    // tones: seen through the glass as a layer with faint strata and a fine
    // grain, its lit top rippled, a few smooth stones half sunk in it (barely
    // tinted with the theme's accents). Quiet, so the scene above stays the
    // subject; the same bed every time.
    function _gravel(ctx) {
        ctx.save();
        _path(ctx, b.water);
        ctx.clip();
        const r = Plan.rng(11), left = b.cx - b.rx, right = b.cx + b.rx;
        // The back and the front edge of the sand's top, seen from a little above
        const back = x => Bowl.sandBack(b, x), front = x => Bowl.sandFront(b, x);
        const sand = _mix(abyss, shallow, 0.5), lit = _mix(sand, ink, 0.1);
        const edge = (f, from, to) => {
            for (let x = from; to > from ? x <= to : x >= to; x += to > from ? 6 : -6)
                ctx.lineTo(x, f(x));
        };
        // The layer through the glass: lighter at the top, dark at the base
        ctx.beginPath();
        ctx.moveTo(left, b.baseY + 2);
        edge(front, left, right);
        ctx.lineTo(right, b.baseY + 2);
        ctx.closePath();
        const layer = ctx.createLinearGradient(0, b.gravelY, 0, b.baseY);
        layer.addColorStop(0, sand);
        layer.addColorStop(1, Qt.darker(abyss, 1.6));
        ctx.fillStyle = layer;
        ctx.fill();
        // Faint strata following the bowl's curve
        [0.3, 0.55, 0.78].forEach((k, i) => {
            ctx.beginPath();
            for (let x = left; x <= right; x += 6) {
                const y = front(x) + (b.baseY - front(x)) * k + Math.sin(x * 0.03 + i * 2) * 2;
                x === left ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
            }
            ctx.strokeStyle = _rgba(ink, 0.05 - i * 0.012);
            ctx.lineWidth = 1;
            ctx.stroke();
        });
        // The lit top of the bed
        ctx.beginPath();
        ctx.moveTo(left, back(left));
        edge(back, left, right);
        edge(front, right, left);
        ctx.closePath();
        const top = ctx.createLinearGradient(0, b.gravelY - 12, 0, b.gravelY);
        top.addColorStop(0, _mix(lit, abyss, 0.35));
        top.addColorStop(1, lit);
        ctx.fillStyle = top;
        ctx.fill();
        // Soft ripples on it
        for (let i = 1; i <= 3; i++) {
            const k = i / 4;
            ctx.beginPath();
            for (let x = left; x <= right; x += 5) {
                const y = back(x) + (front(x) - back(x)) * k + Math.sin(x * 0.09 + i) * 0.8;
                x === left ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
            }
            ctx.strokeStyle = _rgba(ink, 0.06);
            ctx.lineWidth = 1;
            ctx.stroke();
        }
        // Its front edge catches the light
        ctx.beginPath();
        edge(front, left, right);
        ctx.strokeStyle = _rgba(ink, 0.14);
        ctx.lineWidth = 1;
        ctx.stroke();
        // A fine grain, only a texture
        const grains = Math.round(b.rx * (b.baseY - b.gravelY) / 18);
        for (let i = 0; i < grains; i++) {
            const x = left + r() * 2 * b.rx, y = front(x) + r() * (b.baseY - front(x));
            ctx.fillStyle = _rgba(ink, 0.03 + r() * 0.06);
            ctx.fillRect(x, y, 1.2, 1.2);
        }
        // A few smooth stones half sunk in the top, spread along it
        const colours = tints.length ? tints : [ink], n = Math.max(4, Math.round(b.rx / 38));
        for (let i = 0; i < n; i++) {
            const x = b.cx + ((i + 0.2 + r() * 0.6) / n * 2 - 1) * b.rx * 0.86;
            const y = (back(x) + front(x)) / 2 + r() * 3, s = 3.5 + r() * 4.5;
            const c = _mix(sand, colours[i % colours.length], 0.28);
            ctx.save();
            ctx.translate(x, y);
            ctx.scale(1, 0.6);
            ctx.beginPath();
            ctx.arc(0, 0, s, 0, 2 * Math.PI);
            const g = ctx.createRadialGradient(-s * 0.35, -s * 0.45, 0, 0, 0, s);
            g.addColorStop(0, Qt.lighter(c, 1.35));
            g.addColorStop(1, Qt.darker(c, 1.3));
            ctx.fillStyle = g;
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
