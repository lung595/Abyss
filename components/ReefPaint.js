.pragma library

// Paints a reef plan (ReefPlan.js) on Canvas 2D contexts, plane by plane or
// one living thing at a time, in one of two moods: dark (silhouettes a shade
// darker than the water, barely there) or lit (the theme's colours, deep and
// dark, as under a weak lamp). The farther a thing is, the more it melts
// into the water (fog), in both moods: that is what gives the deep its
// depth. Coral and anemone tips glow a little (bioluminescence). Both copies
// use the same shapes: every random pick comes from the item's own seed, so
// drawing never changes what is drawn.

.import "Layout.js" as Lay
.import "ReefPlan.js" as Plan

function _css(c, a) {
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")";
}

function _mix(a, b, k) {
    return { "r": a.r + (b.r - a.r) * k, "g": a.g + (b.g - a.g) * k, "b": a.b + (b.b - a.b) * k };
}
// The same palette seen from farther away (fog 0 = in front, 1 = lost)
function _far(p, fog) {
    return Object.assign({}, p, { "fog": fog });
}

// p: { lit, ink, shadow, stone, sand, water, tints[4], fog }. Under the
// lamp things stay deep and dark: the lamp hints at the reef, it does not
// expose it.
function _body(p, c, a) {
    const fog = p.fog || 0;
    return p.lit ? _css(_mix(c, p.water, 0.4 + 0.55 * fog), a * 0.8) : _css(_mix(p.shadow, p.water, fog), 0.9);
}
function _shine(p, a) {
    const near = 1 - (p.fog || 0);
    return _css(p.ink, (p.lit ? a * 0.45 : a * 0.08) * near);
}
function _rock(p, a) {
    const fog = p.fog || 0;
    return p.lit ? _css(_mix(p.stone, p.water, 0.84 + 0.14 * fog), a) : _css(_mix(p.shadow, p.water, fog), a);
}
// Living light: faint in the dark, a little brighter under the lamp
function _glow(p, c, a) {
    return _css(c, (p.lit ? a : a * 0.5) * (1 - 0.7 * (p.fog || 0)));
}

// One plane of the reef, in scene coordinates (the Canvas translates)
function paintPart(part, ctx, frame, plan, p) {
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    if (part === "far")
        _ridge(ctx, frame, plan.far, _far(p, 0.7));
    else if (part === "mid") {
        const q = _far(p, 0.35);
        plan.spires.forEach(sp => _spire(ctx, frame, sp, q));
        _ridge(ctx, frame, plan.mid, q);
        const tiny = _far(p, 0.4);
        plan.farLife.forEach(it => {
            ctx.save();
            ctx.translate(it.x, it.y);
            paintLife(ctx, it, tiny);
            ctx.restore();
        });
    } else if (part === "cliffs") {
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
        ctx.fillStyle = _glow(p, c, 0.7);
        tips.forEach(t => {
            ctx.beginPath();
            ctx.ellipse(t[0] - 1, t[1] - 1, 2, 2);
            ctx.fill();
        });
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
            ctx.fillStyle = _glow(p, c, 0.55);
            ctx.fillRect(ex - 0.7, ey - 0.7, 1.4, 1.4);
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
    // Thin lines stay visible once scaled down far away
    ctx.lineWidth = 1;
    _life[it.kind](ctx, Plan.rng(it.seed), p.tints[it.tint % p.tints.length], p);
}

// A range of hills: smooth crests, darker towards its foot, and a faint
// rim of light along the top
function _ridge(ctx, frame, pts, p) {
    const top = Math.min(...pts.map(q => q[1]));
    ctx.beginPath();
    ctx.moveTo(pts[0][0], frame.h);
    ctx.lineTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < pts.length; i++) {
        const a = pts[i - 1], b = pts[i];
        ctx.quadraticCurveTo(a[0] + (b[0] - a[0]) * 0.5, Math.min(a[1], b[1]) - 4, b[0], b[1]);
    }
    ctx.lineTo(pts[pts.length - 1][0], frame.h);
    ctx.closePath();
    const g = ctx.createLinearGradient(0, top, 0, frame.floorY);
    g.addColorStop(0, _rock(p, 0.55));
    g.addColorStop(1, _rock(_far(p, Math.max(0, p.fog - 0.2)), 0.95));
    ctx.fillStyle = g;
    ctx.fill();
    ctx.strokeStyle = _shine(p, 0.18);
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < pts.length; i++) {
        const a = pts[i - 1], b = pts[i];
        ctx.quadraticCurveTo(a[0] + (b[0] - a[0]) * 0.5, Math.min(a[1], b[1]) - 4, b[0], b[1]);
    }
    ctx.stroke();
}

// A rock spire (leaning, tapering) or an arch, standing on the hills
function _spire(ctx, frame, sp, p) {
    const base = frame.floorY - frame.h * 0.02;
    ctx.fillStyle = _rock(p, 0.9);
    ctx.strokeStyle = _rock(p, 0.9);
    if (sp.arch) {
        const r = sp.w / 2, top = base - sp.h + r;
        ctx.lineWidth = sp.w * 0.3;
        ctx.lineCap = "butt";
        ctx.beginPath();
        ctx.moveTo(sp.x - r, base);
        ctx.lineTo(sp.x - r, top);
        ctx.arc(sp.x, top, r, Math.PI, 0, false);
        ctx.lineTo(sp.x + r, base);
        ctx.stroke();
        ctx.lineCap = "round";
        return;
    }
    const lean = sp.w * 0.4;
    ctx.beginPath();
    ctx.moveTo(sp.x - sp.w / 2, base);
    ctx.quadraticCurveTo(sp.x - sp.w * 0.3, base - sp.h * 0.5, sp.x + lean, base - sp.h);
    ctx.quadraticCurveTo(sp.x + sp.w * 0.35, base - sp.h * 0.45, sp.x + sp.w / 2, base);
    ctx.closePath();
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
    // Under the lamp the sand is not a lighter slab: only its ripples and
    // pebbles catch the light
    plan.ripples.forEach(r => {
        const y = Lay.floorAt(frame, r.x) + r.dy;
        ctx.strokeStyle = _shine(_far(p, 0.6 * (1 - r.near)), 0.2);
        ctx.lineWidth = 0.6 + r.near * 0.8;
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
