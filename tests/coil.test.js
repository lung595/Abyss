// Coil.js tests. Run from anywhere: gjs tests/coil.test.js
// The jellyfish's tentacle coils round a device (option A). What has to hold:
// no coil point cuts into the body (checked in 3D, against the dense
// silhouette, on every species and on shoals of two sizes), the stretches are
// cut where the depth changes sign, the span rule holds, and the motion
// settles when promised and ends in exactly its final pose.
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const C = load("components/Coil.js");
const S = load("components/Shapes.js");

const ANIMALS = ["server", "vps", "laptop", "phone", "pi", "nas", "desktop"];
const s = 0.8;

// The body as the canvas strokes it, densely sampled, in the long-axis frame
function _dense(kind, sc, shoalR) {
    let pts;
    if (kind === "shoal") {
        pts = [];
        for (let i = 0; i < 360; i++)
            pts.push([Math.cos(i / 180 * Math.PI) * shoalR, Math.sin(i / 180 * Math.PI) * shoalR]);
    } else {
        pts = S._paths(kind).body.reduce((a, d) => a.concat(S.sample(d)), []).map(q => [q[0] * sc, q[1] * sc]);
    }
    return S.hullOf(pts);
}

// Reach of the dense silhouette from its centre line at scene position (x, y
// axis chosen by `tall`), by brute force over its edges
function _reach(hull, tall, a, mid) {
    let lo = Infinity, hi = -Infinity;
    hull.forEach((q0, i) => {
        const q1 = hull[(i + 1) % hull.length];
        const p = tall ? [q0[1], q0[0]] : q0, r = tall ? [q1[1], q1[0]] : q1;
        if ((p[0] - a) * (r[0] - a) > 0 || p[0] === r[0])
            return;
        const y = p[1] + (r[1] - p[1]) * (a - p[0]) / (r[0] - p[0]);
        lo = Math.min(lo, y);
        hi = Math.max(hi, y);
    });
    return lo > hi ? 0 : Math.max(hi - mid, mid - lo);
}

// Does the ring cut into the body? A coil point sits on a ring of radius r
// round the long axis (y = mid + r sin(theta), depth r cos(theta)); the body
// is round in depth, so the point is inside when its ring is smaller than the
// body's reach at the point's own position. Read where the ring is at its
// widest (|z| < 0.5), where r follows from y and z exactly.
function _cuts(kind, sc, shoalR, opts) {
    const b = C.body(kind, sc, shoalR), hull = _dense(kind, sc, shoalR);
    const pts = C.build(b, 0, 0, opts);
    return pts.filter(q => {
        if (Math.abs(q[2]) >= 0.5)
            return false;
        const a = b.tall ? q[1] : q[0], v = b.tall ? q[0] : q[1];
        const r = Math.abs(v - b.mid) / Math.sqrt(1 - q[2] * q[2]);
        return r < _reach(hull, b.tall, a, b.mid) - 1e-6;
    }).length;
}

const BODIES = ANIMALS.map(k => [k, s, 0]).concat([["shoal", 1, 25], ["shoal", 1, 42]]);
BODIES.forEach(([k, sc, r]) => {
    const name = k + (k === "shoal" ? " " + r : "");
    ok(name + ": 121 points", C.build(C.body(k, sc, r), 0, 0, {}).length === 121);
    ["tight", "loose", "dip"].forEach((m, i) => {
        const slack = [1, 1.55, 0.9][i];
        ok(name + ": no point cuts into the body, " + m, _cuts(k, sc, r, { "slack": slack }) === 0);
        ok(name + ": nor on the other side, " + m, _cuts(k, sc, r, { "slack": slack, "side": -1 }) === 0);
    });
    // Counter-test: with the clearance gone the same check has to fail
    ok(name + ": caught without clearance", _cuts(k, sc, r, { "clear": -C.body(k, sc, r).hh }) > 0);
});

// The shoal's ring follows its real size, never a fixed 25 px
{
    const rad = r => Math.max.apply(null, C.build(C.body("shoal", 1, r), 0, 0, {}).map(q => Math.abs(q[1])));
    ok("a bigger shoal gets a bigger ring", rad(42) > rad(25) + 10);
    ok("the ring clears the shoal", rad(25) > 25 && rad(42) > 42);
}

// Span: 44 % of the length, 50 to 55 % on wide bodies, centred
{
    const spanOf = (k) => {
        const b = C.body(k, s, 0), p = C.build(b, 0, 0, { "slack": 1 });
        const first = b.tall ? p[0][1] : p[0][0], last = b.tall ? p[120][1] : p[120][0];
        return { "b": b, "share": Math.abs(C.spanShare(b)), "first": first, "last": last };
    };
    eq("a compact body takes 44 %", C.spanShare(C.body("desktop", s, 0)), 0.44);
    ["server", "nas", "laptop", "vps"].forEach(k => {
        const sh = C.spanShare(C.body(k, s, 0));
        ok(k + ": a wide body takes 50 to 55 %", sh >= 0.5 && sh <= 0.55);
    });
    const e = spanOf("desktop");
    ok("the span is centred", Math.abs(e.first + e.last) < 1.5 * 0.42 * 40);
}
ok("a body as a shoal stays compact", C.spanShare(C.body("shoal", 1, 30)) === 0.44);

// Entering on the bell's side: the first point is on that end
{
    const b = C.body("vps", s, 0);
    ok("enters on the right", C.build(b, 0, 0, { "side": 1 })[0][0] > 0);
    ok("enters on the left", C.build(b, 0, 0, { "side": -1 })[0][0] < 0);
}

// Split: stretches cut where z changes sign, one shared point, marked
{
    const pts = C.build(C.body("vps", s, 0), 0, 0, {}), st = C.split(pts);
    ok("six stretches for three turns", st.length >= 6 && st.length <= 7);
    ok("fronts and behinds alternate", st.every((q, i) => i === 0 || q.front !== st[i - 1].front));
    ok("each is marked by its z", st.every(q => q.points.slice(1).every(p => (p[2] > 0) === q.front)));
    ok("one point of overlap", st.every((q, i) => i === 0 || q.points[0] === st[i - 1].points[st[i - 1].points.length - 1]));
    eq("nothing is lost", st.reduce((a, q) => a + q.points.length, 0) - (st.length - 1), 121);
}

// Motion
ok("reach starts at 0, ends at 1", C.reach(0) === 0 && C.reach(0.75) === 1 && C.reach(2) === 1);
ok("reach eases out", C.reach(0.2) > 0.2 / 0.75);
eq("loose while it grows", C.slackAt(0.3), 1.55);
ok("slack starts the tighten loose", Math.abs(C.slackAt(0.55) - 1.55) < 1e-9);
ok("settles below 1 % by 0.58 s after the tighten starts", [0.58, 0.7, 1.0, 2.0].every(d => Math.abs(C.slackAt(0.55 + d) - 1) < 0.01));
ok("not settled 0.5 s after the tighten starts", Math.abs(C.slackAt(0.55 + 0.5) - 1) > 0.01);
ok("the sleep is a smoothstep, 0.9 s", C.sleepAmount(0, true) === 0 && C.sleepAmount(0.9, true) === 1 && Math.abs(C.sleepAmount(0.45, true) - 0.5) < 1e-9);
{
    const st = { "t": 5, "asleepFor": 0.9, "lag": C.rest() };
    const o = C.optsAt(st, 1, false);
    eq("asleep: slack x 1.5", o.slack, 1.5);
    eq("asleep: tip sags 16 px", o.sag, 16);
    eq("asleep: 30 % of its length", o.frac, 0.3);
    const mid = C.optsAt({ "t": 5, "asleepFor": 0.45, "lag": C.rest() }, 1, false);
    ok("asleep: unwinding in between", mid.frac < 1 && mid.frac > 0.3);
}

// The drag lag: a spring, settles under 0.5 px after release
{
    let lag = C.lagStep(C.rest(), [30, 0], 0.016);
    ok("the coil trails a moving device", lag.p[0] < -10);
    // The last moment the coil is still more than 0.5 px off, over 3 s
    let t = 0, last = 0;
    for (let i = 0; i < 190; i++) {
        lag = C.lagStep(lag, [0, 0], 0.016);
        t += 0.016;
        if (Math.hypot(lag.p[0], lag.p[1]) >= 0.5)
            last = t;
    }
    ok("the lag settles in about a second", last > 0.5 && last < 1.3);
    ok("and it overshoots (zeta 0.4)", (() => {
        let l = C.lagStep(C.rest(), [30, 0], 0.016), flipped = false;
        for (let i = 0; i < 100; i++) {
            l = C.lagStep(l, [0, 0], 0.016);
            if (l.p[0] > 0.5) flipped = true;
        }
        return flipped;
    })());
}

// Settled: time done and lag small; then the pose is exactly the final one
{
    const still = { "t": 0.3, "asleepFor": -1, "lag": C.rest() };
    ok("not settled mid-reach", !C.settled(still));
    ok("not settled while tightening", !C.settled({ "t": 1.0, "asleepFor": -1, "lag": C.rest() }));
    ok("not settled with lag", !C.settled({ "t": 3, "asleepFor": -1, "lag": { "p": [3, 0], "v": [0, 0] } }));
    ok("settled once done", C.settled({ "t": 3, "asleepFor": -1, "lag": { "p": [0.2, 0], "v": [0, 0] } }));
    ok("asleep: not settled while going", !C.settled({ "t": 3, "asleepFor": 0.3, "lag": C.rest() }));
    const b = C.body("vps", s, 0);
    const a = C.build(b, 5, 5, C.optsAt({ "t": 3, "asleepFor": -1, "lag": { "p": [0.1, 0.1], "v": [0, 0] } }, 1, false));
    const f = C.build(b, 5, 5, C.finalOpts(1, false));
    eq("settled pose is the final one", JSON.stringify(a), JSON.stringify(f));
    eq("reduce motion paints the final pose", JSON.stringify(C.build(b, 5, 5, C.optsAt(still, 1, true))), JSON.stringify(f));
    eq("the final pose is tight and whole", C.finalOpts(1, false).slack, 1);
}

done("coil");
