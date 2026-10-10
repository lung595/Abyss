// Mood.js tests. Run from anywhere: gjs tests/mood.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, eq, done } = imports.load;
const M = load("components/Mood.js");

const b = { "l": 40, "r": 560, "top": 60, "bottom": 360 };
const hides = [{ "x": 60, "y": 340 }, { "x": 300, "y": 350 }, { "x": 540, "y": 340 }];
const DT = 1 / 30;
const fresh = seed => M.create(b, hides, seed);
const run = (s, secs, env) => {
    for (let t = 0; t < secs; t += DT)
        M.step(s, DT, env);
    return s;
};
const maxMood = s => s.w.indexOf(Math.max(...s.w));

// Same seed, same run
const replay = seed => {
    const s = fresh(seed);
    M.event(s, "rush", 500, 100);
    return JSON.stringify(run(s, 10));
};
eq("deterministic", replay(5), replay(5));

// Calm by default, and it stays calm while nothing happens (short of boredom)
let s = run(fresh(3), 20);
eq("starts calm", s.state, M.S_CALM);
ok("calm weight dominates", maxMood(s) === M.CALM);

// Inertia: a fright never snaps, the weight climbs over several steps…
s = fresh(3);
M.event(s, "rush", 500, 100);
M.step(s, DT);
ok("fright does not snap", s.w[M.SCARED] > 0 && s.w[M.SCARED] < 0.5 && s.w[M.CALM] > 0.5);
// …and it fades gradually afterwards
// Reach the decay through the real chain: scared -> hiding -> cautious -> calm
run(s, 1.0);
while (s.state !== M.S_CALM)
    M.step(s, DT);
M.step(s, DT);
ok("fright fades, not snaps", s.w[M.SCARED] > 0 && s.w[M.SCARED] < 1);
run(s, 6);
ok("fright decays to nothing", s.w[M.SCARED] < 0.01);

// Chaining: scared -> hide -> cautious return -> calm
s = fresh(3);
M.event(s, "rush", 500, 100);
eq("rush scares him", s.state, M.S_SCARED);
const order = [];
for (let t = 0; t < 15; t += DT) {
    M.step(s, DT);
    if (order[order.length - 1] !== s.state)
        order.push(s.state);
}
eq("scared, hiding, cautious, calm", order, [M.S_SCARED, M.S_HIDING, M.S_CAUTIOUS, M.S_CALM]);

// Hide spot: the one farthest from the threat, released when he comes out
s = fresh(3);
M.event(s, "rush", 540, 340);
eq("hides far from the rush", s.hide, 0);
M.event(s, "rush", 50, 340);
eq("a new rush re-chooses", s.hide, 2);
run(s, 20);
eq("no hide spot once calm again", s.hide, -1);
eq("no spots, no choice", (() => { const n = M.create(b, [], 1); M.event(n, "rush", 1, 1); return n.hide; })(), -1);

// A device going down frightens him too; a second one while hiding changes nothing
s = fresh(3);
M.event(s, "deviceDown");
eq("device down scares", s.state, M.S_SCARED);

// While frightened the other events are ignored (no joy in a hole)
run(s, 2);
M.event(s, "success");
M.event(s, "click");
ok("hiding ignores good news", s.state === M.S_HIDING);

// A rush while cautious sends him back
run(s, 4.5);
eq("cautious", s.state, M.S_CAUTIOUS);
M.event(s, "rush", 100, 100);
eq("rush while cautious scares again", s.state, M.S_SCARED);

// Curious events
for (const kind of ["relay", "join", "file"]) {
    s = fresh(3);
    M.event(s, kind, 400, 120);
    eq(kind + " makes him curious", s.state, M.S_CURIOUS);
}
s = fresh(3);
M.event(s, "file", 400, 120);
run(s, 1);
ok("he looks at the file", Math.hypot(s.gx - 400, s.gy - 120) < Math.hypot(300 - 400, 210 - 120));
run(s, 10);
eq("curiosity passes", s.state, M.S_CALM);

// Joy: a success or a click, then calm; it does not interrupt a fright
s = fresh(3);
M.event(s, "success");
eq("success is joy", s.state, M.S_JOY);
run(s, 8);
eq("joy passes", s.state, M.S_CALM);
s = fresh(3);
M.event(s, "click");
eq("click is joy", s.state, M.S_JOY);

// Boredom: idle time drowses him, any event wakes him (a click startles, not cheers)
s = run(fresh(3), 50);
eq("falls asleep when idle", s.state, M.S_SLEEPY);
run(s, 5);
ok("sleep weight rises", maxMood(s) === M.SLEEPY);
const gy = s.gy;
ok("asleep he looks down", gy > 300);
M.event(s, "click");
eq("click wakes him curious", s.state, M.S_CURIOUS);
// A wake-up by rush: frightened, not sleepy
s = run(fresh(3), 50);
M.event(s, "rush", 100, 100);
eq("rush wakes him scared", s.state, M.S_SCARED);

// Hunger and the glass
s = run(fresh(3), 1, { "hunger": 0.8 });
eq("hungry with crumbs", s.state, M.S_HUNGRY);
run(s, 1, { "hunger": 0 });
eq("fed, calm again", s.state, M.S_CALM);
s = run(fresh(3), 1, { "dirt": 0.7 });
eq("cleans the cloudy glass", s.state, M.S_CLEANING);
ok("cleaning weight rises", s.w[M.CLEANING] > 0.5);
run(s, 1, { "dirt": 0.01 });
eq("clean, calm again", s.state, M.S_CALM);

// After a fright with a need pending he goes straight to it
s = fresh(3);
M.event(s, "rush", 500, 100);
run(s, 15, { "hunger": 0.9 });
eq("back to the pending need", s.state, M.S_HUNGRY);

// A need wakes a sleeper; a blinking relay does not hold needs off
s = run(fresh(3), 50);
eq("asleep", s.state, M.S_SLEEPY);
run(s, 1, { "hunger": 0.9 });
eq("hunger wakes him", s.state, M.S_HUNGRY);
s = run(fresh(3), 50);
run(s, 1, { "dirt": 0.9 });
eq("dirt wakes him", s.state, M.S_CLEANING);
s = fresh(3);
for (let i = 0; i < 60; i++) {
    if (i % 2 === 0)
        M.event(s, "relay", 400, 120);
    run(s, 0.25, { "hunger": 0.9 });
}
eq("a blinking relay does not starve him", s.state, M.S_HUNGRY);

// Gaze: the fresh pointer wins, then the lamp takes over
s = fresh(3);
M.lamp(s, 100, 100);
M.pointer(s, 500, 300);
run(s, 1);
ok("gaze follows the pointer", Math.hypot(s.gx - 500, s.gy - 300) < 15);
run(s, 6);
ok("then the lamp", Math.hypot(s.gx - 100, s.gy - 100) < 15);

// A file catches his eye without moving the lamp: gaze returns to the lamp after
s = fresh(3);
M.lamp(s, 100, 100);
M.event(s, "file", 400, 120);
run(s, 1);
ok("looks at the file", Math.hypot(s.gx - 400, s.gy - 120) < 15);
run(s, 20);
eq("calm again", s.state, M.S_CALM);
ok("gaze back on the lamp", Math.hypot(s.gx - 100, s.gy - 100) < 15);

// Bad input is ignored
s = fresh(3);
M.pointer(s, NaN, 10);
M.lamp(s, 5, Infinity);
M.event(s, "relay", 200);
run(s, 2);
ok("gaze stays finite", Number.isFinite(s.gx) && Number.isFinite(s.gy) && Number.isFinite(s.px) && Number.isFinite(s.lx) && Number.isFinite(s.iy));
s = run(fresh(3), 44);
M.event(s, "bogus");
run(s, 2);
eq("unknown kind does not reset idle", s.state, M.S_SLEEPY);

// Different seeds give different first frights
const hideFor = seed => { const n = fresh(seed); M.event(n, "rush", 1, 1); return n.hideFor; };
ok("seeds 1, 2 and 7 differ", hideFor(1) !== hideFor(2) && hideFor(2) !== hideFor(7));

// Remaining transitions
s = fresh(3);
M.event(s, "rush", 500, 100);
run(s, 2);
eq("hiding", s.state, M.S_HIDING);
run(s, 1);
M.event(s, "deviceDown");
eq("deviceDown while hiding changes nothing", s.state, M.S_HIDING);
M.event(s, "rush", 100, 100);
ok("rush while hiding restarts the hide", s.state === M.S_HIDING && s.t === 0);
s = fresh(3);
M.event(s, "success");
M.event(s, "relay", 1, 1);
eq("relay while joy stays joy", s.state, M.S_JOY);
run(s, 2.4);
M.event(s, "join", 1, 1);
eq("join near the end of joy stays joy", s.state, M.S_JOY);
for (const kind of ["relay", "success"]) {
    s = run(fresh(3), 50);
    M.event(s, kind, 1, 1);
    ok(kind + " wakes a sleeper", s.state === M.S_CURIOUS || s.state === M.S_JOY);
}
s = fresh(3);
M.event(s, "success");
run(s, 2.4);
run(s, 0.2, {});
s.idle = 50;
run(s, 1);
eq("joy ends on sleep when bored", s.state, M.S_SLEEPY);
s = fresh(3);
M.event(s, "rush", 1, 1);
run(s, 6.5);
s.idle = 50;
run(s, 2);
ok("cautious ends on sleep when bored", s.state === M.S_SLEEPY || s.state === M.S_CALM);

// Phase hints: faster fins and breath when scared, slower asleep, wrapped
const calm = run(fresh(3), 5), scared = fresh(3);
M.event(scared, "rush", 1, 1);
run(scared, 1);
const sleepy = run(fresh(3), 60);
ok("fright quickens fins", scared.finRate > calm.finRate * 2);
ok("fright quickens breath", scared.breathRate > calm.breathRate * 2);
ok("sleep slows breath", sleepy.breathRate < calm.breathRate);
ok("phases stay in one turn", [calm, scared, sleepy].every(x => x.finPhase >= 0 && x.finPhase < 6.2832 && x.breathPhase >= 0 && x.breathPhase < 6.2832));

// Weights stay in 0..1 through everything, and nothing is allocated per step
s = fresh(9);
let bad = false;
const ev = ["rush", "deviceDown", "relay", "join", "file", "success", "click"];
for (let i = 0; i < 3000; i++) {
    if (i % 40 === 0)
        M.event(s, ev[(i / 40) % ev.length], 100 + i % 400, 100);
    M.step(s, DT);
    if (s.w.some(v => !(v >= 0 && v <= 1.0001)))
        bad = true;
}
ok("weights stay within 0..1", !bad);
const wRef = s.w;
run(s, 5);
ok("weights array is reused", s.w === wRef && s.w.length === 7);

// Fixed small cost per step
const t0 = Date.now();
for (let i = 0; i < 200000; i++)
    M.step(s, DT);
const us = (Date.now() - t0) * 1000 / 200000;
ok("step is cheap (" + us.toFixed(2) + " µs)", us < 20);

// A resize keeps the mood and moves only the limits
{
    const r = M.create({ "l": 0, "r": 100, "top": 0, "bottom": 100 }, [{ "x": 1, "y": 1 }], 3);
    M.event(r, "deviceDown", 10, 10);
    M.step(r, 0.1);
    const st = r.state, w = r.w.slice();
    M.resize(r, { "l": 0, "r": 300, "top": 0, "bottom": 200 }, []);
    eq("resize keeps the state", r.state, st);
    eq("resize keeps the weights", r.w, w);
    eq("resize moves the limits", r.b.r, 300);
    eq("resize forgets a vanished hiding spot", r.hide, -1);
}

done("mood");
