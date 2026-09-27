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

done("swim");
