.pragma library

// The silhouette of every creature, in one place. The canvas strokes it
// (CreatureShape.qml) and the tentacle that holds it walks around it
// (Grips.js): the same paths, so a grip can never be drawn inside a body it
// is supposed to hold.
//
// Everything is around the centre of a 96x96 box, like CreatureShape drew it,
// and every species is turned the way it swims: the shapes face right.

// Each species: the outlines of its body (filled and stroked), the lines drawn
// on top of it (feelers, a snout, the shell's spiral) and what else it shows
// (a dot, the squid's arms, the turtle's plates).
// A path is a flat list of commands: "M" x y, "L" x y, "Q" cx cy x y,
// "A" cx cy rx ry (a whole ellipse), "Z" to close. Kept as data, not as
// drawing calls, so a body can also be walked without a canvas.
const PATHS = {
    // Manta ray: wide wings, a tail, two feelers
    "server": {
        "body": [
            ["M", 0, -12, "Q", 16, -8, 34, 5, "Q", 14, 6, 4, 14, "L", 0, 30, "L", -4, 14, "Q", -14, 6, -34, 5, "Q", -16, -8, 0, -12, "Z"]
        ],
        "lines": [
            ["M", -5, -10, "L", -7, -17],
            ["M", 5, -10, "L", 7, -17]
        ]
    },
    // Lantern whale: a long body, a tail fin, a lantern on a stalk
    "vps": {
        "body": [
            ["M", -30, 0, "Q", -26, -15, 0, -14, "Q", 24, -12, 30, 0, "Q", 24, 12, 0, 12, "Q", -24, 12, -30, 0, "Z"],
            ["M", -30, 0, "L", -40, -9, "L", -38, 0, "L", -40, 9, "Z"]
        ],
        "lines": [
            ["M", 20, -12, "Q", 30, -26, 37, -19]
        ],
        "dot": [37, -19]
    },
    // Fish: an oval body, a tail, a dorsal fin, an eye
    "laptop": {
        "body": [
            ["M", -18, -9, "A", -18, -9, 36, 18, "Z"],
            ["M", -16, 0, "L", -28, -9, "L", -28, 9, "Z"]
        ],
        "lines": [
            ["M", -2, -8, "Q", 4, -16, 10, -8]
        ],
        "dot": [9, -2]
    },
    // Seahorse: an upright curve, a head, a snout
    "phone": {
        "body": [
            ["M", 4, -18, "Q", 12, -14, 8, -8, "Q", 0, 0, 6, 8, "Q", 10, 16, 2, 20, "Q", -6, 22, -4, 14],
            ["M", -2, -20, "A", -2, -20, 10, 8, "Z"]
        ],
        "lines": [
            ["M", 7, -17, "L", 15, -19]
        ],
        "heavy": true
    },
    // Little squid: a bell, and arms that reach past it
    "pi": {
        "body": [
            ["M", 0, -20, "Q", 10, -8, 7, 4, "L", -7, 4, "Q", -10, -8, 0, -20, "Z"]
        ],
        "arms": true
    },
    // Turtle: a shell, its plates, a head, four flippers
    "nas": {
        "body": [
            ["M", -20, -14, "A", -20, -14, 40, 28, "Z"],
            ["M", 18, -4.5, "A", 18, -4.5, 12, 9, "Z"],
            ["M", 9, -15, "A", 9, -15, 10, 6, "Z"],
            ["M", 9, 9, "A", 9, 9, 10, 6, "Z"],
            ["M", -22, -15, "A", -22, -15, 10, 6, "Z"],
            ["M", -22, 9, "A", -22, 9, 10, 6, "Z"]
        ],
        "plates": true
    },
    // Nautilus: a round shell, its spiral, and the tentacles it swims with
    "desktop": {
        "body": [
            ["M", 0, 0, "A", 0, 0, 16, 16, "Z"]
        ],
        "lines": [
            ["M", 14, 4, "Q", 24, 6, 28, 10, "Q", 24, 9, 28, 13, "Q", 24, 12, 28, 16]
        ],
        "spiral": true
    }
};
// The name under a creature (Creature.qml)
const LABEL_DY = 26, LABEL_H = 46, LABEL_W = 120;

function _paths(kind) {
    return PATHS[kind] || PATHS.desktop;
}

// Draws a species on a canvas 2d context already translated so that (0, 0)
// is the creature's centre. col: its colour · n: 0..1 how bright (traffic) ·
// asleep: whether it is out of the light.
function draw(c, kind, col, n, asleep) {
    const p = _paths(kind);
    const stroke = Qt.rgba(col.r, col.g, col.b, asleep ? 0.35 : 0.6 + 0.4 * n);
    const fill = Qt.rgba(col.r, col.g, col.b, asleep ? 0.06 : 0.12 + 0.22 * n);
    c.lineJoin = "round";
    c.lineWidth = 1.7;
    c.strokeStyle = stroke;
    c.fillStyle = fill;
    c.beginPath();
    p.body.forEach(d => _path(c, d));
    c.fill();
    c.stroke();
    if (p.lines) {
        c.beginPath();
        p.lines.forEach(d => _path(c, d));
        c.stroke();
    }
    if (p.arms) {
        // The squid's arms, one stroke each
        c.beginPath();
        for (let k = -3; k <= 3; k++) {
            c.moveTo(k * 2, 4);
            c.quadraticCurveTo(k * 3, 12, k * 2.5, 20 + Math.abs(k));
        }
        c.stroke();
    }
    if (p.heavy) {
        // The seahorse's back is drawn a little thicker than the rest
        c.lineWidth = 2.4;
        c.beginPath();
        _path(c, p.body[0]);
        c.stroke();
    }
    if (p.plates) {
        c.beginPath();
        [[0, 0], [-10, -5], [10, -5], [-10, 5], [10, 5]].forEach(h => {
            for (let k = 0; k <= 6; k++) {
                const a = k / 6 * Math.PI * 2;
                k ? c.lineTo(h[0] + Math.cos(a) * 4.5, h[1] + Math.sin(a) * 4.5) : c.moveTo(h[0] + Math.cos(a) * 4.5, h[1] + Math.sin(a) * 4.5);
            }
        });
        c.stroke();
    }
    if (p.spiral) {
        c.beginPath();
        for (let a = 0; a < 11; a += 0.2) {
            const r = 1.3 * Math.exp(a * 0.22);
            a ? c.lineTo(Math.cos(a) * r, Math.sin(a) * r) : c.moveTo(Math.cos(a) * r, Math.sin(a) * r);
        }
        c.stroke();
    }
    if (p.dot) {
        c.fillStyle = kind === "vps" ? Qt.rgba(col.r, col.g, col.b, asleep ? 0.3 : 0.95) : stroke;
        c.beginPath();
        c.arc(p.dot[0], p.dot[1], kind === "vps" ? 3 : 1.8, 0, Math.PI * 2);
        c.fill();
    }
}

function _path(c, p) {
    for (let i = 0; i < p.length;) {
        const cmd = p[i++];
        if (cmd === "M")
            c.moveTo(p[i++], p[i++]);
        else if (cmd === "L")
            c.lineTo(p[i++], p[i++]);
        else if (cmd === "Q")
            c.quadraticCurveTo(p[i++], p[i++], p[i++], p[i++]);
        else if (cmd === "A")
            c.ellipse(p[i++], p[i++], p[i++], p[i++], 0, 0, Math.PI * 2);
        else if (cmd === "Z")
            c.closePath();
    }
}

// What a tentacle rides on: the outside of the animal. An outline dives into
// every crevice (between a turtle's flippers, between a whale's body and its
// tail fin) and the ribbon would follow it into the water. So the walk is the
// outline's outer envelope, pushed off the body by `clear`: the result hugs
// each animal and cannot be inside one. Returns {points, cx, cy}.
function outline(kind, clear, n) {
    const body = resample(hull(kind), n || 44);
    const cx = body.reduce((a, q) => a + q[0], 0) / body.length;
    const cy = body.reduce((a, q) => a + q[1], 0) / body.length;
    const k = clear === undefined ? 4 : clear;
    return { "points": k > 0 ? _offset(body, k) : body, "cx": cx, "cy": cy };
}

// The points of a closed walk pushed out by k, along the bisector of the two
// sides that meet at each point, so a corner stays a corner and the gap to
// the body is k everywhere: a blunt corner moves further than k, a square one
// k * 1.41, which is exactly what keeps the distance right
function _offset(pts, k) {
    const n = pts.length, mid = _middle(pts);
    const normals = pts.map((q, i) => {
        const a = pts[i], b = pts[(i + 1) % n];
        return _normal(a, b, mid);
    });
    return pts.map((q, i) => {
        const p = normals[(i - 1 + n) % n], r = normals[i];
        let bx = p[0] + r[0], by = p[1] + r[1];
        const l = Math.hypot(bx, by);
        if (l < 1e-6)
            return [q[0] + p[0] * k, q[1] + p[1] * k];
        bx /= l;
        by /= l;
        // How far along the bisector it takes to be k off both sides, with a
        // limit on the spike a very sharp corner (a fish's tail tip) would
        // otherwise grow: past that the corner is cut, not pointed
        const reach = Math.max(0.2, (bx * p[0] + by * p[1] + bx * r[0] + by * r[1]) / 2);
        const d = Math.min(k / reach, 3 * k);
        return [q[0] + bx * d, q[1] + by * d];
    });
}

// The outside normal of the side a -> b, whichever way the walk turns
function _normal(a, b, mid) {
    let nx = -(b[1] - a[1]), ny = b[0] - a[0];
    const l = Math.hypot(nx, ny) || 1;
    nx /= l;
    ny /= l;
    const mx = (a[0] + b[0]) / 2 - mid[0], my = (a[1] + b[1]) / 2 - mid[1];
    return nx * mx + ny * my < 0 ? [-nx, -ny] : [nx, ny];
}

function _middle(pts) {
    return [pts.reduce((a, q) => a + q[0], 0) / pts.length, pts.reduce((a, q) => a + q[1], 0) / pts.length];
}

// The outside of a species' body: every part of it (a fish and its tail, a
// turtle and its flippers) wrapped in one convex shape
function hull(kind) {
    return hullOf(_paths(kind).body.reduce((a, d) => a.concat(sample(d)), []));
}

// The convex hull of a cloud of points (monotone chain), without the last
// point repeated
function hullOf(pts) {
    const p = pts.slice().sort((a, b) => a[0] - b[0] || a[1] - b[1]);
    if (p.length < 3)
        return p;
    const cross = (o, a, b) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
    const lower = [];
    p.forEach(q => {
        while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], q) <= 0)
            lower.pop();
        lower.push(q);
    });
    const upper = [];
    p.slice().reverse().forEach(q => {
        while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], q) <= 0)
            upper.pop();
        upper.push(q);
    });
    lower.pop();
    upper.pop();
    return lower.concat(upper);
}

// The box a species' body covers around its centre: half width, half height
// and where the middle of that box sits. The layout test keeps other things
// out of it, so it is read from the real outline, never guessed.
function bounds(kind) {
    const pts = _paths(kind).body.reduce((a, d) => a.concat(sample(d)), []);
    const xs = pts.map(q => q[0]), ys = pts.map(q => q[1]);
    const x0 = Math.min.apply(null, xs), x1 = Math.max.apply(null, xs);
    const y0 = Math.min.apply(null, ys), y1 = Math.max.apply(null, ys);
    return { "hw": (x1 - x0) / 2, "hh": (y1 - y0) / 2, "cy": (y0 + y1) / 2 };
}

// The points of one path, flattened: fine enough for a 96 px animal
function sample(p) {
    const out = [];
    let cur = null;
    for (let i = 0; i < p.length;) {
        const cmd = p[i++];
        if (cmd === "M") {
            cur = [p[i++], p[i++]];
            out.push(cur);
        } else if (cmd === "L") {
            const to = [p[i++], p[i++]];
            _line(cur, to, out);
            cur = to;
        } else if (cmd === "Q") {
            const c1 = [p[i++], p[i++]], to = [p[i++], p[i++]];
            _quad(cur, c1, to, out);
            cur = to;
        } else if (cmd === "A") {
            const cx = p[i++], cy = p[i++], rx = p[i++], ry = p[i++];
            const steps = Math.max(24, Math.round((rx + ry) * 2));
            for (let k = 0; k <= steps; k++) {
                const a = k / steps * Math.PI * 2;
                out.push([cx + Math.cos(a) * rx, cy + Math.sin(a) * ry]);
            }
            cur = [cx + rx, cy];
        } else if (cmd === "Z") {
            if (cur && out.length)
                _line(cur, out[0], out);
            cur = out[0] || cur;
        }
    }
    return out;
}

function _line(a, b, out) {
    if (!a)
        return;
    const d = Math.hypot(b[0] - a[0], b[1] - a[1]), n = Math.max(1, Math.round(d / 1.5));
    for (let k = 1; k <= n; k++)
        out.push([a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n]);
}

function _quad(a, c1, b, out) {
    const n = 12;
    for (let k = 1; k <= n; k++) {
        const t = k / n, u = 1 - t;
        out.push([u * u * a[0] + 2 * u * t * c1[0] + t * t * b[0], u * u * a[1] + 2 * u * t * c1[1] + t * t * b[1]]);
    }
}

// Even steps around a closed walk: the same number of points whatever the
// animal's shape, so a grip can be walked in time
function resample(pts, n) {
    if (pts.length < 3)
        return pts;
    const closed = pts.concat([pts[0]]);
    const cum = [0];
    for (let i = 1; i < closed.length; i++)
        cum.push(cum[i - 1] + Math.hypot(closed[i][0] - closed[i - 1][0], closed[i][1] - closed[i - 1][1]));
    const total = cum[cum.length - 1] || 1, out = [];
    for (let k = 0; k < n; k++) {
        const d = total * k / n;
        let i = 1;
        while (i < cum.length - 1 && cum[i] < d)
            i++;
        const t = (d - cum[i - 1]) / Math.max(1e-9, cum[i] - cum[i - 1]);
        out.push([closed[i - 1][0] + (closed[i][0] - closed[i - 1][0]) * t, closed[i - 1][1] + (closed[i][1] - closed[i - 1][1]) * t]);
    }
    return out;
}

// Points on top of each other (a closing point, a flipper meeting the shell)
// would make the walk stop
function dedupe(pts) {
    const out = [];
    pts.forEach(q => {
        const last = out[out.length - 1];
        if (!last || Math.hypot(q[0] - last[0], q[1] - last[1]) > 0.8)
            out.push(q);
    });
    return out;
}
