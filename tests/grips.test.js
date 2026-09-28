// Grips.js tests. Run from anywhere: gjs tests/grips.test.js
// How a tentacle holds a creature: it comes down on the flank the ribbon
// arrived on, sweeps under the belly and hooks back up on the other side,
// so the jellyfish seems to hold the device for real (D232).
//
// What has to hold: the hook never passes UNDER the body (P83 — an ellipse
// around these bodies did, on seven species out of eight, and the grip could
// not be seen at all), it stays on the species' own outline whatever its
// shape, it leaves the back open, and asleep it lets go.
//
// hold() answers in scene coordinates while the silhouette lives in its own
// frame, so every hook here is asked with the creature at (0, 0): the points
// then come back in the body's own units, the only frame the two can be
// compared in. Bodies are sampled at the scale they are drawn at, for the
// same reason.
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const G = load("components/Grips.js");
const S = load("components/Shapes.js");

const KINDS = ["server", "vps", "laptop", "phone", "pi", "nas", "desktop", "shoal"];
const ANIMALS = KINDS.filter(k => k !== "shoal");
const s = 0.8;  // a creature at rest, a little lit
const ABOVE = [0, -200];  // where the bell hangs, as it always does
const RING = 22;  // the circle School.qml draws around a shoal

// Every point of the silhouette as the canvas strokes it, densely sampled
// and at the scale the creature is drawn at
function _skin(kind, sc) {
    const k = sc === undefined ? s : sc;
    return S._paths(kind).body.reduce((a, d) => a.concat(S.sample(d)), []).map(q => [q[0] * k, q[1] * k]);
}

// The silhouette's outline as a closed convex walk. A point inside it is
// inside the animal, whatever its distance to the drawn line: the empty
// water between a ray's wings reads as "far from the body" but is not
// somewhere a ribbon may go.
function _hull(kind, sc) {
    return S.hullOf(_skin(kind, sc));
}

// Is a point inside a closed convex walk, by more than a hair? (one
// half-plane per edge, the walk first pulled in by TOUCH so that a tip resting
// against the outline counts as holding it, not as cutting through)
const TOUCH = 0.4;
function _shrink(poly, k) {
    const cx = poly.reduce((a, q) => a + q[0], 0) / poly.length, cy = poly.reduce((a, q) => a + q[1], 0) / poly.length;
    return poly.map(q => {
        const l = Math.hypot(q[0] - cx, q[1] - cy) || 1;
        return [q[0] - (q[0] - cx) / l * k, q[1] - (q[1] - cy) / l * k];
    });
}
function _inside(q, poly) {
    let sign = 0;
    for (let i = 0; i < poly.length; i++) {
        const a = poly[i], b = poly[(i + 1) % poly.length];
        const c = (b[0] - a[0]) * (q[1] - a[1]) - (b[1] - a[1]) * (q[0] - a[0]);
        if (c === 0)
            continue;
        const sgn = c > 0 ? 1 : -1;
        if (sign && sgn !== sign)
            return false;
        sign = sgn;
    }
    return true;
}

function _hook(kind, sc, wake, from) {
    return G.hold(kind, sc, 0, 0, from || ABOVE, wake === undefined ? 1 : wake);
}

function _gap(q, skin) {
    return Math.min.apply(null, skin.map(p => Math.hypot(q[0] - p[0], q[1] - p[1])));
}

// The angle of a point seen from a centre, in radians
function _angle(q, c) {
    return Math.atan2(q[1] - c[1], q[0] - c[0]);
}

// The middle a species' hook turns around: its own, not where it was drawn
function _mid(kind) {
    const b = S.outline(kind, G.CLEAR, 44);
    return [b.cx, b.cy];
}

// How far round its own body a hook reached, in degrees
function _sweep(kind, sc) {
    const pts = _hook(kind, sc), c = [G.print(kind, sc).hw * 0, _mid(kind)[1] * sc];
    const cx = _mid(kind)[0] * sc;
    let turn = 0, prev = _angle(pts[1], [cx, c[1]]);
    for (let i = 2; i < pts.length; i++) {
        let d = _angle(pts[i], [cx, c[1]]) - prev;
        while (d > Math.PI)
            d -= Math.PI * 2;
        while (d < -Math.PI)
            d += Math.PI * 2;
        turn += d;
        prev = _angle(pts[i], [cx, c[1]]);
    }
    return Math.abs(turn) * 180 / Math.PI;
}

KINDS.forEach(kind => {
    const pts = _hook(kind, s), skin = _skin(kind, s), hull = _hull(kind, s);
    const gaps = pts.map(q => _gap(q, skin)).sort((a, b) => a - b);
    const med = gaps[gaps.length >> 1];

    // --- P83: the hook rides outside the body, never through it -----------
    ok(kind + ": no point of the hook is inside the body", !pts.some(q => _inside(q, _shrink(hull, TOUCH))));
    ok(kind + ": no point of the hook is on the body", gaps[0] >= -TOUCH);
    // Ridden at the clearance it asks for, measured on the middle of the hook:
    // a sharp corner (a fish's tail, the squid's arms) pulls one point in, and
    // that outlier says more about the species than about the clearance.
    if (kind !== "shoal")
        ok(kind + ": the hook rides at the clearance it asks for", med >= G.CLEAR * s * 0.8);

    // --- It goes under the belly and back up ------------------------------
    ok(kind + ": the hook goes most of the way round", _sweep(kind, s) > 200);
    ok(kind + ": the back is left open", _sweep(kind, s) < 330);
    // The hook's mouth faces the tentacle: it lands on the flank the ribbon
    // came down on, so it starts on the upper side of the body. Measured as
    // "above the middle" rather than as an angle: on a long animal the outline
    // is not round and the angles are not the same distance apart.
    const midY = _mid(kind)[1] * s;
    ok(kind + ": it lands on the flank the ribbon came down on", pts[0][1] < midY);
});

// A shoal is a group: one hook around the school, on its drawn ring
ok("a shoal is held as one loop", G.print("shoal", 1).hw > 20);
ok("a shoal's hook rides outside its ring", _hook("shoal", 1).every(q => Math.hypot(q[0], q[1]) > RING));

// The species are told apart: a seahorse is held on its height, a turtle on
// its width, so the hook fits the animal instead of a circle
ok("a tall animal is held tall", S.bounds("phone").hh > S.bounds("phone").hw);
ok("a wide animal is held wide", S.bounds("nas").hw > S.bounds("nas").hh);
ok("a long animal is held long", S.bounds("vps").hw > 30);

// Scale: the lens grows the creature, the hook grows with it
ok("the hook follows the lens", _hook("laptop", 1.4).every((q, i) => {
    const small = _hook("laptop", 0.7)[i];
    return Math.hypot(q[0], q[1]) >= Math.hypot(small[0], small[1]) - 1e-6;
}));

// Asleep it lets go: the hook slackens off the body and stops short, so its
// tip hangs open under the belly instead of coming back up
KINDS.forEach(kind => {
    const skin = _skin(kind, s);
    const awake = _hook(kind, s, 1), asleep = _hook(kind, s, 0);
    const near = p => Math.min.apply(null, p.map(q => _gap(q, skin)));
    ok(kind + ": a sleeping body is let go", near(asleep) > near(awake) + 1);
    ok(kind + ": a sleeping hook stops short", asleep.length < awake.length);
});

// The tip that comes back up is drawn in front of the body (Grip.qml): it is
// the part that crosses the animal, and without it the hook reads as a "C"
// floating beside it (P85)
ok("a hook has a tip to draw in front", G.tailCount(_hook("laptop", s).length) >= 3);
ok("and that tip is a real share of it", G.tailCount(_hook("laptop", s).length) > _hook("laptop", s).length * 0.3);

// Counter-test: the promise at the top can actually fail, or the whole suite
// would be theatre. Shrinking a real hook towards its middle is what an
// ellipse too small does — the ring of P83 — and every point lands inside the
// animal, where the test has to catch it.
const hull = _shrink(_hull("server", s), TOUCH);
const shrunk = _hook("server", s).map(q => [q[0] * 0.5, q[1] * 0.5]);
ok("a hook shrunk into the body is caught", shrunk.filter(q => _inside(q, hull)).length / shrunk.length > 0.5);
ok("and the real one is not", !_hook("server", s).some(q => _inside(q, hull)));

// The boxes the layout guard reserves are real numbers, and hold what it
// thinks they hold: a guard reading NaN guards nothing
ok("the reserved boxes are real numbers", [G.print("server", s).hw, G.print("server", s).hh, G.hubPrint().hw].every(v => typeof v === "number" && v > 0));

done("grips");
