// Spring.js tests. Run from anywhere: gjs tests/spring.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, done } = imports.load;
const S = load("components/Spring.js");

// Let go 80 px away: it comes home, overshooting a little on the way
const s = { x: 80, y: -40, vx: 0, vy: 0 };
let t = 0, crossed = false, frames = 0;
while (!S.settled(s, 0, 0) && t < 5) {
    S.step(s, 0, 0, S.HOME, 1 / 60);
    t += 1 / 60;
    frames++;
    crossed = crossed || s.x < -1;
}
ok("let go, it swims home", S.settled(s, 0, 0));
ok("with a little bounce past home", crossed);
ok("and stops within about a second and a half", t < 1.6);

// Held: follows the hand closely, without wobbling past it
const h = { x: 0, y: 0, vx: 0, vy: 0 };
let past = false;
for (let i = 0; i < 30; i++) {
    S.step(h, 100, 0, S.HELD, 1 / 60);
    past = past || h.x > 101;
}
ok("held, it catches up with the hand in half a second", Math.abs(h.x - 100) < 1);
ok("barely overshooting the hand", !past);

// Same motion whatever the tick rate (sub-steps)
const a = { x: 50, y: 0, vx: 0, vy: 0 }, b = { x: 50, y: 0, vx: 0, vy: 0 };
for (let i = 0; i < 6; i++)
    S.step(a, 0, 0, S.HOME, 1 / 60);
for (let i = 0; i < 3; i++)
    S.step(b, 0, 0, S.HOME, 1 / 30);
ok("same path at 30 and 60 Hz", Math.abs(a.x - b.x) < 0.5);

// The lens: pushed 30 px aside and magnified, it swings there with a small
// overshoot, then settles quickly enough for the lens to feel direct
const q = { x: 0, y: 0, s: 1, vx: 0, vy: 0, vs: 0 };
let tq = 0, over = false;
while (!S.poseSettled(q, 30, 0, 1.8) && tq < 3) {
    S.stepPose(q, 30, 0, 1.8, S.LENS, 1 / 60);
    tq += 1 / 60;
    over = over || q.s > 1.82;
}
ok("lens: a thing swings to its place and size", S.poseSettled(q, 30, 0, 1.8));
ok("lens: with a little pop past its size", over);
ok("lens: and settles within half a second", tq < 0.5);
// Back home when the lens leaves
while (!S.poseSettled(q, 0, 0, 1) && tq < 6) {
    S.stepPose(q, 0, 0, 1, S.LENS, 1 / 30);
    tq += 1 / 30;
}
ok("lens: back at rest when it leaves", S.poseSettled(q, 0, 0, 1));

done("spring");
