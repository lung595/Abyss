// ReefPlan.js tests. Run from anywhere: gjs tests/reef.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const L = load("components/Layout.js");
const R = load("components/ReefPlan.js");

const f = L.frame(580, 480, 54);
const a = R.build(f, 2, 7), b = R.build(f, 2, 7);

// The dark and the lit copies must line up: same seed, same reef
eq("same seed, same reef", a, b);
ok("another seed, another reef", JSON.stringify(R.build(f, 2, 8)) !== JSON.stringify(a));
ok("the random numbers stay in [0, 1)", (() => {
    const r = R.rng(3);
    for (let i = 0; i < 1000; i++) {
        const v = r();
        if (v < 0 || v >= 1)
            return false;
    }
    return true;
})());

// Diversity and depth
ok("the floor carries life", a.life.filter(it => !it.ledge).length >= 8);
ok("at least four kinds of life", new Set(a.life.map(it => it.kind)).size >= 4);
ok("two cliffs, one per side", a.cliffs.length === 2 && a.cliffs[0].side === 0 && a.cliffs[1].side === 1);
ok("the far range stands above the nearer hills", Math.min(...a.far.map(q => q[1])) < Math.min(...a.mid.map(q => q[1])));
// The planes are painted in bands that start at floorY - 30% / 20% of h
ok("the far range fits its band", a.far.every(q => q[1] >= f.floorY - f.h * 0.3));
ok("the hills and spires fit theirs", a.mid.every(q => q[1] >= f.floorY - f.h * 0.2) && a.spires.every(s => f.floorY - f.h * 0.02 - s.h >= f.floorY - f.h * 0.2));
ok("one arch among the spires", a.spires.filter(s => s.arch).length === 1);
ok("small life far away, smaller than in front", a.farLife.length >= 6 && Math.max(...a.farLife.map(it => it.s)) < Math.min(...a.life.filter(it => !it.ledge).map(it => it.s)));
ok("ripples open up as they come near", a.ripples.filter(r => r.near === 1).every(r => r.dy > Math.max(...a.ripples.filter(q => q.near === 0).map(q => q.dy))));

// Caves keep their floor
const span = R.caveSpan(f, 2);
ok("no life over a cave", a.life.filter(it => !it.ledge).every(it => it.x + 18 < span[0] || it.x - 18 > span[1]));
ok("no pebble over a cave", a.pebbles.every(p => p.x + 6 < span[0] || p.x - 6 > span[1]));
eq("no caves, nothing kept clear", R.caveSpan(f, 0), null);
ok("without caves, life grows there too", R.build(f, 0, 7).life.some(it => it.x > span[0] && it.x < span[1]));

// Everything inside the scene
ok("life inside the scene", a.life.every(it => it.x > 0 && it.x < f.w && it.y <= f.h));
ok("cliffs stay at the edges", a.cliffs.every(c => c.edge.every(q => c.side ? q[0] > f.w * 0.9 : q[0] < f.w * 0.1)));

// The current
ok("stony sponges never sway", a.life.filter(it => it.kind === "sponge").every(it => R.swayAt(it, 3.3) === 0));
ok("sway stays within the kind's reach", a.life.every(it => [0, 1.1, 2.7, 9.4].every(t => Math.abs(R.swayAt(it, t)) <= R.SWAY[it.kind] * 1.3 + 1e-9)));
ok("algae sway more than coral", R.SWAY.algae > R.SWAY.coral);
const alga = a.life.find(it => it.kind === "algae");
ok("the current moves over time", !alga || R.swayAt(alga, 0) !== R.swayAt(alga, 1));
ok("slow: under 1 degree per 30 Hz frame", a.life.every(it => Math.abs(R.swayAt(it, 1.0) - R.swayAt(it, 1.0 + 1 / 30)) < 1));

done("reef");
