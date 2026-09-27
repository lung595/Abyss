// Goldfish.js tests. Run from anywhere: gjs tests/goldfish.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, done } = imports.load;
const G = load("components/Goldfish.js");

const b = { "l": 40, "r": 560, "top": 60, "bottom": 360 };
const run = (s, secs, env) => {
    for (let t = 0; t < secs; t += 1 / 30)
        G.step(s, 1 / 30, env);
    return s;
};
const inside = s => s.x >= b.l && s.x <= b.r && s.y >= b.top && s.y <= b.bottom;

// The same bowl for the same seed
ok("repeatable", JSON.stringify(G.create(b, 5)) === JSON.stringify(G.create(b, 5)));

// A quiet mesh: he swims about, never out of the water, no crumbs
let s = run(G.create(b, 3), 60, { "b": b, "bits": 0 });
ok("stays in the water", inside(s));
ok("no traffic, no crumbs", s.crumbs.length === 0);
ok("he moved", Math.hypot(s.x - 380, s.y - 210) > 5 || s.mood !== "swim");

// Traffic drops crumbs, and he eats them all once it stops
s = run(G.create(b, 3), 20, { "b": b, "bits": 30e6 });
ok("traffic drops crumbs (" + s.crumbs.length + " in the water)", s.crumbs.length > 0 && s.crumbs.length <= 5);
ok("he goes for them", s.mood === "eat");
run(s, 90, { "b": b, "bits": 0 });
ok("he eats every crumb", s.crumbs.length === 0);
ok("crumbs never leave the water", s.crumbs.every(c => c.y <= b.bottom + 4));

// The glass clouds over while watched, then he scrubs it clean
s = G.create(b, 9);
run(s, 400, { "b": b, "bits": 0 });
ok("the glass got dirty, and he went to scrub", s.spots.some(p => p.dirt < 1) && s.spots.every(p => p.dirt <= 1));
s = G.create(b, 9);
s.spots.forEach(p => p.dirt = 0.9);
run(s, 60, { "b": b, "bits": 0 });
ok("he scrubbed the glass clean", s.spots.every(p => p.dirt < 0.5));
ok("scrubbing back in the water", inside(s));

// The mesh is down: he sinks to the bottom and sleeps
s = run(G.create(b, 3), 40, { "b": b, "asleep": true, "bits": 50e6 });
ok("asleep on the bottom", s.mood === "sleep" && Math.abs(s.y - b.bottom) < 3);
ok("no crumbs while asleep", s.crumbs.length === 0);
ok("eyes shut", G.pose(s, 10).lid === 1 && G.pose(s, 10).asleep);

// A click: he stops and waves, then goes back to his day
s = run(G.create(b, 3), 5, { "b": b, "bits": 0 });
G.wave(s);
run(s, 1, { "b": b, "bits": 0 });
ok("waving", s.mood === "wave" && G.pose(s, 1).fin < -30);
ok("he stops to wave", Math.hypot(s.vx, s.vy) < 12);
run(s, 2, { "b": b, "bits": 0 });
ok("then carries on", s.mood !== "wave");
ok("no waving in his sleep", G.wave(run(G.create(b, 3), 30, { "b": b, "asleep": true })).mood === "sleep");

// No jumps: at 30 Hz he never moves more than a few pixels a frame
s = G.create(b, 4);
let worst = 0;
for (let t = 0; t < 120; t += 1 / 30) {
    const x = s.x, y = s.y;
    G.step(s, 1 / 30, { "b": b, "bits": t < 60 ? 40e6 : 0 });
    worst = Math.max(worst, Math.hypot(s.x - x, s.y - y));
}
ok("glides (" + worst.toFixed(1) + " px per frame at most)", worst < 3);

done("goldfish");
