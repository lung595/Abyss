// Swim.js tests. Run from anywhere: gjs tests/swim.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, done } = imports.load;
const S = load("components/Swim.js");

const close = (a, b, eps) => Math.abs(a - b) <= (eps || 0.5);

// Every animal leaves from where it was and lands exactly on its new place
for (const kind of ["laptop", "server", "vps", "nas", "phone", "pi", "desktop", "shoal", "unknown"]) {
    const p = S.plan([100, 300], [400, 180], kind, 10, 1, 1);
    const a = S.at(p, 10), z = S.at(p, 10 + p.dur);
    ok(kind + ": starts where it was", close(a.x, 100) && close(a.y, 300));
    ok(kind + ": lands on its place", z.done && z.x === 400 && z.y === 180 && z.b === 1 && z.a === 0);
    // No jump anywhere on the way (60 Hz steps)
    let prev = a, worst = 0;
    for (let t = 10; t <= 10 + p.dur; t += 1 / 60) {
        const q = S.at(p, t);
        worst = Math.max(worst, Math.hypot(q.x - prev.x, q.y - prev.y));
        prev = q;
    }
    ok(kind + ": glides without jumps (" + worst.toFixed(1) + " px per frame)", worst < 12);
}

// Gaits differ: the turtle takes longer than the fish over the same way
const fish = S.plan([0, 0], [300, 0], "laptop", 0, 1, 1), turtle = S.plan([0, 0], [300, 0], "nas", 0, 1, 1);
ok("the turtle is slower than the fish", turtle.dur > fish.dur + 1);
ok("a long trip never drags on", S.plan([0, 0], [5000, 0], "nas", 0, 1, 1).dur <= 4.5);

// Jet strokes: the squid pushes, then glides, stroke after stroke
const squid = S.plan([0, 0], [300, 0], "pi", 0, 1, 1), g = S.gait("pi");
const early = S.progress(g, 0.05) - S.progress(g, 0), late = S.progress(g, 0.33) - S.progress(g, 0.28);
ok("a jet stroke pushes hard, then glides", early > late * 3);
ok("the squid squeezes on the way", S.at(squid, squid.dur * 0.1).b < 1);

// Going left, a fish turns round; the manta never flips
const back = S.plan([300, 0], [0, 0], "laptop", 0, 1, 1);
ok("heading left, the fish ends facing left", S.at(back, back.dur).f === -1);
ok("it turns round through its thin side", Math.abs(S.at(back, back.dur * S.TURN / 2).f) < 0.5);
ok("the manta never flips", S.plan([300, 0], [0, 0], "server", 0, 1, 1).face1 === 1);
ok("a small step keeps its facing", S.plan([100, 0], [96, 40], "laptop", 0, 1, -1).face1 === -1);

// Neighbours bend opposite ways, so they never swim on one line
const up = S.at(S.plan([0, 0], [300, 0], "server", 0, 1, 1), 0.9), down = S.at(S.plan([0, 0], [300, 0], "server", 0, -1, 1), 0.9);
ok("the side picks the bend", up.y * down.y < 0);

// Nose toward where it goes: a fish rising tilts up (negative angle)
const rise = S.plan([0, 200], [300, 0], "laptop", 0, 1, 1);
ok("rising, the nose tilts up", S.at(rise, rise.dur / 2).a < -3);

// Life at rest: bounded, smooth, calmer asleep, and a look round now and then
const KINDS = ["laptop", "server", "vps", "nas", "phone", "pi", "desktop", "shoal"];
KINDS.forEach(kind => {
    const sd = S.seed("p:" + kind);
    let worst = 0, worstA = 0, big = 0, prev = S.idle(kind, 0, sd, 1);
    for (let s = 1 / 60; s < 60; s += 1 / 60) {
        const q = S.idle(kind, s, sd, 1);
        worst = Math.max(worst, Math.abs(q.dx - prev.dx), Math.abs(q.dy - prev.dy), Math.abs(q.f - prev.f) * 20);
        worstA = Math.max(worstA, Math.abs(q.a - prev.a));
        big = Math.max(big, Math.abs(q.dx), Math.abs(q.dy), Math.abs(q.sx - 1) * 40, Math.abs(q.sy - 1) * 40, Math.abs(q.a));
        prev = q;
    }
    ok(kind + ": idles without jumps", worst < 1.5 && worstA < 1.5);
    ok(kind + ": stays near its place (" + big.toFixed(1) + ")", big < 8);
    ok(kind + ": moves at all", big > 1);
});
const calm = (w) => {
    let m = 0;
    for (let s = 0; s < 20; s += 0.05)
        m = Math.max(m, Math.abs(S.idle("phone", s, 0.3, w).a));
    return m;
};
ok("asleep, it moves less", calm(0) < calm(1) * 0.5);
let flips = 0, f0 = S.idle("laptop", 0, 0.4, 1).f;
for (let s = 0; s < 120; s += 0.1) {
    const f = S.idle("laptop", s, 0.4, 1).f;
    if (Math.abs(f) === 1 && f !== f0) {
        flips++;
        f0 = f;
    }
}
ok("the fish looks round now and then (" + flips + " in 2 min)", flips >= 4 && flips <= 12);
ok("the manta never looks round", S.idle("server", 37.3, 0.4, 1).f === 1);
ok("neighbours move out of step", S.seed("p:a") !== S.seed("p:b"));
ok("REST is still", S.REST.dx === 0 && S.REST.f === 1);

done("swim");
