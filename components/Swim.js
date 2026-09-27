.pragma library

// How a creature swims to its new place when its place changes (its latency
// moved, a regroup, a peer leaving a shoal). Each animal keeps its own gait,
// so a move reads as the animal, not as a slide: the fish darts and sways,
// the manta glides on a wide arc, the squid jets in strokes, the turtle
// paddles slowly. Pure maths: AbyssScene steps it on its own clock and the
// clock stops once everyone has arrived.

// speed: cruise (px/s) · min: shortest trip (s) · arc: how much the path
// bends (share of the distance) · sway: side sway (px) · beats: tail beats,
// wing beats or hops per second · hop: up and down (px) · strokes: jet
// strokes per trip (0 = one smooth push) · flap: size pulse (wings, jet) ·
// turn: faces where it goes (the shapes are drawn facing right)
const GAITS = {
    "laptop": { "speed": 230, "min": 0.9, "arc": 0.1, "sway": 4, "beats": 2.4, "hop": 0, "strokes": 0, "flap": 0, "turn": true }, // fish
    "server": { "speed": 140, "min": 1.6, "arc": 0.28, "sway": 0, "beats": 0.9, "hop": 0, "strokes": 0, "flap": 0.05, "turn": false }, // manta
    "vps": { "speed": 120, "min": 1.9, "arc": 0.16, "sway": 0, "beats": 0.5, "hop": 4, "strokes": 0, "flap": 0, "turn": true }, // whale
    "nas": { "speed": 85, "min": 2.1, "arc": 0.06, "sway": 0, "beats": 1.2, "hop": 1.5, "strokes": 0, "flap": 0.03, "turn": true }, // turtle
    "phone": { "speed": 120, "min": 1.5, "arc": 0.04, "sway": 0, "beats": 1.6, "hop": 5, "strokes": 0, "flap": 0, "turn": true }, // seahorse
    "pi": { "speed": 190, "min": 1.2, "arc": 0.08, "sway": 0, "beats": 0, "hop": 0, "strokes": 3, "flap": 0.07, "turn": false }, // squid
    "desktop": { "speed": 110, "min": 1.5, "arc": 0.1, "sway": 0, "beats": 0, "hop": 0, "strokes": 2, "flap": 0.04, "turn": false }, // nautilus
    "shoal": { "speed": 160, "min": 1.4, "arc": 0.18, "sway": 2, "beats": 0.8, "hop": 0, "strokes": 0, "flap": 0, "turn": false }
};
// Even across the whole deep, a trip never drags on
const LONGEST = 4.5;
// Leaving and landing: the first and last part of a trip where it turns round
const TURN = 0.25;

function gait(kind) {
    return GAITS[kind] || GAITS.shoal;
}

// A trip from `from` to `to` ([x, y]) starting at t0 (scene seconds). side
// (+1 or -1) picks which way the path bends, so neighbours do not all swim
// on one line; face is where it looked before (+1 right, -1 left).
function plan(from, to, kind, t0, side, face) {
    const g = gait(kind), dx = to[0] - from[0], dy = to[1] - from[1], d = Math.hypot(dx, dy);
    const bend = g.arc * d * (side < 0 ? -1 : 1);
    const mid = [(from[0] + to[0]) / 2, (from[1] + to[1]) / 2];
    // Control point: off the middle, square to the way it goes
    const c = d > 0 ? [mid[0] - dy / d * bend, mid[1] + dx / d * bend] : mid;
    const was = face < 0 ? -1 : 1;
    return {
        "from": from,
        "to": to,
        "c": c,
        "d": d,
        "t0": t0,
        "dur": Math.min(LONGEST, g.min + d / g.speed),
        "kind": kind,
        "face0": was,
        "face1": g.turn && Math.abs(dx) > 8 ? (dx < 0 ? -1 : 1) : was
    };
}

function _inOut(u) {
    return (1 - Math.cos(Math.PI * u)) / 2;
}
function _out(u) {
    return 1 - Math.pow(1 - u, 3);
}

// Share of the way covered at u (share of the trip's time): one smooth push,
// or jet strokes (a quick push, then a glide, again)
function progress(g, u) {
    if (!g.strokes)
        return _inOut(u);
    const n = g.strokes, k = Math.min(n - 1, Math.floor(u * n));
    return (k + _out(u * n - k)) / n;
}

function _point(p, e) {
    const v = 1 - e;
    return [v * v * p.from[0] + 2 * v * e * p.c[0] + e * e * p.to[0], v * v * p.from[1] + 2 * v * e * p.c[1] + e * e * p.to[1]];
}

// Where the trip is at time t: {x, y} on the way, b the body's size pulse,
// f its facing (-1..1, through 0 while it turns round), a its tilt (degrees,
// nose toward where it goes), done once it has arrived
function at(p, t) {
    if (t >= p.t0 + p.dur)
        return { "x": p.to[0], "y": p.to[1], "b": 1, "f": p.face1, "a": 0, "done": true };
    const u = Math.max(0, (t - p.t0) / p.dur), g = gait(p.kind), e = progress(g, u), q = _point(p, e);
    // Life on the way, faded in and out so it leaves and lands gently
    const env = Math.sin(Math.PI * u), secs = u * p.dur;
    if (g.sway && p.d > 0) {
        const w = Math.sin(2 * Math.PI * g.beats * secs) * g.sway * env;
        q[0] += -(p.to[1] - p.from[1]) / p.d * w;
        q[1] += (p.to[0] - p.from[0]) / p.d * w;
    }
    if (g.hop)
        q[1] -= Math.abs(Math.sin(Math.PI * g.beats * secs)) * g.hop * env;
    let b = 1;
    if (g.strokes)
        // The squid squeezes while it pushes, then relaxes into the glide
        b -= g.flap * Math.sin(Math.PI * Math.sqrt((u * g.strokes) % 1));
    else if (g.flap)
        b += g.flap * Math.sin(2 * Math.PI * g.beats * secs) * env;
    // Turns round as it leaves (a flip through its thin side)
    const f = p.face0 + (p.face1 - p.face0) * _inOut(Math.min(1, u / TURN));
    let a = 0;
    if (g.turn) {
        const ahead = _point(p, Math.min(1, e + 0.02));
        const vx = ahead[0] - q[0], vy = ahead[1] - q[1];
        a = Math.max(-22, Math.min(22, Math.atan2(vy, Math.abs(vx) + 1e-6) * 180 / Math.PI)) * env * (f < 0 ? -1 : 1);
    }
    return { "x": q[0], "y": q[1], "b": b, "f": f, "a": a, "done": false };
}
