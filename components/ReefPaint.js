.pragma library

// Paints a reef plan (ReefPlan.js) on Canvas 2D contexts, plane by plane or
// one living thing at a time, in one of two moods: dark (silhouettes a shade
// darker than the water, barely there) or lit (the theme's colours, muted,
// as under a weak lamp). Both copies
// use the same shapes: every random pick comes from the item's own seed, so
// drawing never changes what is drawn.

.import "Layout.js" as Lay
.import "ReefPlan.js" as Plan

function _css(c, a) {
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")";
}

// p: { lit, ink, shadow, stone, sand, tints[4] }. Under the lamp things
// stay muted: the lamp hints at the reef, it does not expose it.
function _body(p, c, a) {
    return p.lit ? _css(c, a * 0.55) : _css(p.shadow, 0.9);
}
function _shine(p, a) {
    return _css(p.ink, p.lit ? a * 0.6 : a * 0.12);
}
function _rock(p, a) {
    return p.lit ? _css(p.stone, a * 0.4) : _css(p.shadow, a);
}

// One plane of the reef, in scene coordinates (the Canvas translates)
function paintPart(part, ctx, frame, plan, p) {
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    if (part === "far")
        _ridge(ctx, frame, plan.far, p.lit ? _css(p.stone, 0.1) : _css(p.shadow, 0.22));
    else if (part === "mid")
        _ridge(ctx, frame, plan.mid, p.lit ? _css(p.stone, 0.22) : _css(p.shadow, 0.4));
    else if (part === "cliffs") {
        plan.cliffs.forEach(c => _cliff(ctx, frame, c, p));
        plan.life.forEach(it => it.ledge && _ledge(ctx, it, p));
    } else if (part === "floor")
        _floor(ctx, frame, plan, p);
}

// How each kind of life is drawn, at the origin, growing upwards (negative y)
const _life = {
    // Branching coral: forks upwards, bright tips
    "coral": function (ctx, r, c, p) {
        const tips = [];
        function branch(x, y, ang, len, width, depth) {
            const x2 = x + Math.cos(ang) * len, y2 = y + Math.sin(ang) * len;
            ctx.lineWidth = width;
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.lineTo(x2, y2);
            ctx.stroke();
            if (depth <= 0)
                return tips.push([x2, y2]);
            branch(x2, y2, ang - 0.35 - r() * 0.3, len * 0.72, width * 0.7, depth - 1);
            branch(x2, y2, ang + 0.35 + r() * 0.3, len * 0.72, width * 0.7, depth - 1);
        }
        ctx.strokeStyle = _body(p, c, 0.8);
        branch(0, 0, -Math.PI / 2 + (r() - 0.5) * 0.4, 9 + r() * 4, 3.2, 2);
        if (p.lit) {
            ctx.fillStyle = _css(p.ink, 0.3);
            tips.forEach(t => ctx.fillRect(t[0] - 0.8, t[1] - 0.8, 1.6, 1.6));
        }
    },
    // Tube sponges: a few rounded tubes, dark mouths, a lit rim
    "sponge": function (ctx, r, c, p) {
        const n = 2 + Math.floor(r() * 3);
        for (let k = 0; k < n; k++) {
            const tw = 5 + r() * 3, th = 10 + r() * 16, x = (k - (n - 1) / 2) * (tw + 1.5);
            ctx.fillStyle = _body(p, c, 0.7);
            ctx.beginPath();
            ctx.roundedRect(x - tw / 2, -th, tw, th + 2, tw / 2, tw / 2);
            ctx.fill();
            ctx.fillStyle = _css(p.shadow, p.lit ? 0.8 : 0.9);
            ctx.beginPath();
            ctx.ellipse(x - tw * 0.32, -th + 0.6, tw * 0.64, 2.4);
            ctx.fill();
            ctx.strokeStyle = _shine(p, 0.35);
            ctx.lineWidth = 0.8;
            ctx.beginPath();
            ctx.moveTo(x - tw / 2 + 0.8, -th + 3);
            ctx.lineTo(x - tw / 2 + 0.8, -2);
            ctx.stroke();
        }
    },
    // Anemone: a squat foot and a crown of curling tentacles
    "anemone": function (ctx, r, c, p) {
        ctx.fillStyle = _body(p, c, 0.6);
        ctx.beginPath();
        ctx.roundedRect(-4, -7, 8, 8, 3, 3);
        ctx.fill();
        const n = 9 + Math.floor(r() * 6);
        ctx.strokeStyle = _body(p, c, 0.85);
        ctx.lineWidth = 1.4;
        for (let k = 0; k < n; k++) {
            const a = -Math.PI + (k + 0.5) * Math.PI / n, len = 8 + r() * 5;
            const ex = Math.cos(a) * len, ey = -7 + Math.sin(a) * len;
            ctx.beginPath();
            ctx.moveTo(0, -7);
            ctx.quadraticCurveTo(ex * 0.4, ey - 4, ex, ey);
            ctx.stroke();
            if (p.lit) {
                ctx.fillStyle = _css(p.ink, 0.28);
                ctx.fillRect(ex - 0.7, ey - 0.7, 1.4, 1.4);
            }
        }
    },
    // Sea fan (gorgonian): a flat lace of fine branches
    "fan": function (ctx, r, c, p) {
        ctx.strokeStyle = _body(p, c, 0.55);
        const n = 7 + Math.floor(r() * 5), height = 22 + r() * 12;
        for (let k = 0; k < n; k++) {
            const a = -Math.PI / 2 + (k / (n - 1) - 0.5) * 1.5;
            const ex = Math.cos(a) * height, ey = Math.sin(a) * height;
            ctx.lineWidth = 0.9;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.quadraticCurveTo(ex * 0.2, ey * 0.6, ex, ey);
            ctx.stroke();
        }
        // The lace across the branches
        ctx.lineWidth = 0.5;
        for (let ring = 0.45; ring < 1; ring += 0.18) {
            ctx.beginPath();
            ctx.arc(0, 0, height * ring, -Math.PI / 2 - 0.75, -Math.PI / 2 + 0.75, false);
            ctx.stroke();
        }
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(0, 2);
        ctx.lineTo(0, -5);
        ctx.stroke();
    },
    // Leafy algae: swaying stems with alternating leaves
    "algae": function (ctx, r, c, p) {
        const n = 2 + Math.floor(r() * 2);
        for (let k = 0; k < n; k++) {
            const x0 = (k - (n - 1) / 2) * 5, top = 20 + r() * 14, sway = (r() - 0.5) * 12;
            ctx.strokeStyle = _body(p, c, 0.75);
            ctx.lineWidth = 1.2;
            ctx.beginPath();
            ctx.moveTo(x0, 0);
            ctx.quadraticCurveTo(x0 + sway, -top * 0.5, x0 + sway * 0.4, -top);
            ctx.stroke();
            ctx.fillStyle = _body(p, c, 0.6);
            for (let y = 5; y < top - 2; y += 5) {
                const t = y / top, side = (y / 5) % 2 ? 1 : -1;
                const sx = x0 + sway * 2 * t * (1 - t) + sway * 0.4 * t * t;
                ctx.beginPath();
                ctx.ellipse(side > 0 ? sx : sx - 6, -y - 1.6, 6, 3.2);
                ctx.fill();
            }
        }
    }
};

// One living thing, drawn at the origin growing upwards (negative y)
function paintLife(ctx, it, p) {
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.scale(it.s, it.s);
    _life[it.kind](ctx, Plan.rng(it.seed), p.tints[it.tint % p.tints.length], p);
}

function _ridge(ctx, frame, pts, fill) {
    ctx.beginPath();
    ctx.moveTo(pts[0][0], frame.h);
    pts.forEach(q => ctx.lineTo(q[0], q[1]));
    ctx.lineTo(pts[pts.length - 1][0], frame.h);
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
}

function _cliff(ctx, frame, c, p) {
    const outer = c.side ? frame.w + 30 : -30;
    ctx.beginPath();
    ctx.moveTo(outer, c.edge[0][1]);
    c.edge.forEach(q => ctx.lineTo(q[0], q[1]));
    ctx.lineTo(outer, frame.h);
    ctx.closePath();
    ctx.fillStyle = _rock(p, 0.85);
    ctx.fill();
    // The lit rim along the edge, then the strata
    ctx.strokeStyle = _shine(p, 0.3);
    ctx.lineWidth = 1;
    ctx.beginPath();
    c.edge.forEach((q, i) => i ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1]));
    ctx.stroke();
    ctx.strokeStyle = _shine(p, 0.14);
    c.strata.forEach(s => {
        const i = Math.min(c.edge.length - 1, Math.max(0, Math.round((s.y - c.edge[0][1]) / 14)));
        const x = c.edge[i][0], len = Math.abs(x - outer) * s.len;
        ctx.beginPath();
        ctx.moveTo(x + (c.side ? 3 : -3), s.y);
        ctx.lineTo(x + (c.side ? len : -len), s.y + 3);
        ctx.stroke();
    });
}

function _ledge(ctx, it, p) {
    ctx.fillStyle = _rock(p, 0.85);
    ctx.beginPath();
    ctx.moveTo(it.ledge.from, it.y - 2);
    ctx.lineTo(it.ledge.to, it.y);
    ctx.lineTo(it.ledge.from, it.y + 7);
    ctx.closePath();
    ctx.fill();
}

function _floor(ctx, frame, plan, p) {
    if (p.lit) {
        const g = ctx.createLinearGradient(0, frame.floorY, 0, frame.h);
        g.addColorStop(0, _css(p.sand, 0.2));
        g.addColorStop(1, _css(p.sand, 0.06));
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.moveTo(0, frame.h);
        for (let x = 0; x <= frame.w; x += 24)
            ctx.lineTo(x, Lay.floorAt(frame, x));
        ctx.lineTo(frame.w, frame.h);
        ctx.closePath();
        ctx.fill();
    }
    ctx.strokeStyle = _shine(p, 0.2);
    ctx.lineWidth = 1;
    plan.ripples.forEach(r => {
        const y = Lay.floorAt(frame, r.x) + r.dy;
        ctx.beginPath();
        ctx.moveTo(r.x, y);
        ctx.bezierCurveTo(r.x + r.len * 0.3, y - 2.5, r.x + r.len * 0.6, y + 2.5, r.x + r.len, y);
        ctx.stroke();
    });
    plan.pebbles.forEach(b => {
        const y = Lay.floorAt(frame, b.x) + b.dy;
        ctx.fillStyle = _rock(p, 0.9);
        ctx.beginPath();
        ctx.ellipse(b.x - b.rx, y - b.ry, b.rx * 2, b.ry * 2);
        ctx.fill();
        if (p.lit) {
            ctx.fillStyle = _css(p.ink, 0.18);
            ctx.beginPath();
            ctx.ellipse(b.x - b.rx * 0.6, y - b.ry * 0.9, b.rx * 0.8, b.ry * 0.6);
            ctx.fill();
        }
    });
}
