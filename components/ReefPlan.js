.pragma library

// What grows in the deep and where: cliffs on both sides, a far range and
// nearer hills, a rippled sandy floor with pebbles, and life on it (corals,
// sponges, anemones, sea fans, leafy algae). Pure data, drawn by
// ReefPaint.js. The same seed always gives the same reef, so the dark copy
// (always shown) and the lit copy (shown only under the pointer's lamp) line
// up exactly. Tested with gjs in tests/reef.test.js.

.import "Layout.js" as Lay

const KINDS = ["coral", "sponge", "anemone", "fan", "algae"];

// A small seeded random generator (mulberry32): same seed, same numbers
function rng(seed) {
    let a = seed >>> 0;
    return function () {
        a = (a + 0x6D2B79F5) >>> 0;
        let t = a;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

// The floor span kept clear for the caves (a cave's rock is 112 px wide)
function caveSpan(frame, caves) {
    if (!caves)
        return null;
    return [Lay.caveX(frame, 0) - 62, Lay.caveX(frame, caves - 1) + 62];
}

function _clearOfCaves(span, x, half) {
    return !span || x + half < span[0] || x - half > span[1];
}

// A cliff down one side: a jagged edge leaning out towards the floor, with
// strata across it and a few ledges carrying a small plant
function _cliff(frame, r, side, life) {
    const w = frame.w, top = frame.surfaceY + 6, bottom = frame.h;
    const reach = Math.max(16, w * 0.04);
    const edge = [], strata = [];
    for (let y = top; y <= bottom + 14; y += 14) {
        // Born as a point near the surface, full width towards the floor
        const grow = Math.pow(Math.min(1, (y - top) / (frame.floorY - top)), 0.6);
        const x = reach * grow * (0.55 + 0.45 * r());
        edge.push([side ? w - x : x, Math.min(y, bottom)]);
    }
    for (let k = 0; k < 7; k++)
        strata.push({ "y": top + 30 + r() * (frame.floorY - top - 40), "len": 0.4 + r() * 0.5 });
    for (let k = 0; k < 2; k++) {
        const y = top + 60 + r() * (frame.floorY - top - 110);
        const out = 6 + r() * 5;
        const x = edge[Math.min(edge.length - 1, Math.round((y - top) / 14))][0];
        const at = side ? x - out : x + out;
        life.push(_living(r, r() < 0.5 ? "algae" : "anemone", at, y, 0.55, { "ledge": { "from": x, "to": at } }));
    }
    return { "side": side, "edge": edge, "strata": strata };
}

// How much each kind sways in the current (degrees): soft algae a lot,
// stony coral barely
const SWAY = { "coral": 0.8, "sponge": 0, "anemone": 2.5, "fan": 2, "algae": 7 };

function _living(r, kind, x, y, s, extra) {
    const it = { "kind": kind, "x": x, "y": y, "s": s, "tint": Math.floor(r() * 4), "seed": Math.floor(r() * 1e9), "sway": SWAY[kind] * (0.7 + r() * 0.6) };
    return Object.assign(it, extra || {});
}

// The reef in three planes, far to near, so the floor reads as a seabed
// stretching away behind the peers: a far mountain range lost in the haze,
// nearer hills with spires and an arch and a row of small far life, then
// the floor coming towards you (ripples and pebbles grow as they come near)
// with the life that sways. Each plane slides a little with the lens
// (parallax), the far one least.
function build(frame, caves, seed) {
    const r = rng(seed || 7), w = frame.w, h = frame.h;
    const span = caveSpan(frame, caves);
    const plan = { "far": [], "mid": [], "spires": [], "farLife": [], "cliffs": [], "ripples": [], "pebbles": [], "life": [] };
    // Far range: broad peaks and valleys, well above the floor
    for (let x = -40; x <= w + 60; x += 46 + r() * 40)
        plan.far.push([x, frame.floorY - h * (0.14 + r() * 0.14)]);
    // Nearer hills: lower, rounder
    for (let x = -30; x <= w + 40; x += 30 + r() * 24)
        plan.mid.push([x, frame.floorY - h * (0.04 + r() * 0.07)]);
    // A few rock spires rising from the hills, and one arch
    for (let k = 0; k < 3; k++)
        plan.spires.push({ "x": w * (0.12 + 0.3 * k + r() * 0.16), "w": 8 + r() * 10, "h": h * (0.08 + r() * 0.08), "arch": false });
    plan.spires.push({ "x": w * (0.55 + r() * 0.3), "w": 46 + r() * 30, "h": h * (0.07 + r() * 0.04), "arch": true });
    // Small life far away, on the hills' foot: it does not sway (too far to see)
    for (let x = 10 + r() * 20; x < w - 10; x += 26 + r() * 40)
        plan.farLife.push(_living(r, KINDS[Math.floor(r() * KINDS.length)], x, frame.floorY - h * (0.02 + r() * 0.02), 0.35 + r() * 0.15));
    [0, 1].forEach(side => plan.cliffs.push(_cliff(frame, r, side, plan.life)));
    // Ripples in the sand, in rows that open up as they come near
    for (let row = 0; row < 5; row++) {
        const near = row / 4;
        for (let x = r() * 30; x < w; x += (26 + r() * 20) * (1 + near))
            plan.ripples.push({ "x": x, "dy": 5 + Math.pow(row, 1.5) * 5 + r() * 2, "len": (12 + r() * 14) * (1 + near), "near": near });
    }
    // Pebbles, bigger in front
    for (let x = 8 + r() * 20; x < w; x += 14 + r() * 30)
        if (_clearOfCaves(span, x, 6)) {
            const near = r();
            plan.pebbles.push({ "x": x, "dy": 1 + near * 16, "rx": (1.2 + r() * 2) * (1 + near * 1.5), "ry": (0.9 + r() * 1.2) * (1 + near) });
        }
    // Life along the floor, every 22 to 48 px, never over a cave
    for (let x = 14 + r() * 16; x < w - 10; x += 22 + r() * 26) {
        const it = _living(r, KINDS[Math.floor(r() * KINDS.length)], x, Lay.floorAt(frame, x) + 2, 0.7 + r() * 0.6);
        if (_clearOfCaves(span, x, 18))
            plan.life.push(it);
    }
    return plan;
}

// The current: one slow wave crossing the deep from left to right, so
// neighbours lean one after the other. Angle in degrees at time t (s).
function swayAt(it, t) {
    return it.sway * Math.sin(t * 0.9 - it.x * 0.018 + (it.seed % 7) * 0.2);
}
