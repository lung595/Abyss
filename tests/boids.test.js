// Boids.js tests. Run from anywhere: gjs tests/boids.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, done } = imports.load;
const B = load("components/Boids.js");
const Lay = load("components/Layout.js");

const ring = n => Array.from({ length: n }, (_, i) => [Math.cos(i * 2.4) * (20 + i * 4), Math.sin(i * 2.4) * (20 + i * 4)]);

// Deterministic: same input, same school
{
    const a = B.create(ring(8), 0.3), b = B.create(ring(8), 0.3);
    for (let k = 0; k < 300; k++) {
        B.step(a, 1 / 30);
        B.step(b, 1 / 30);
    }
    ok("same seed, same school", JSON.stringify(a.x) === JSON.stringify(b.x));
    const c = B.create(ring(8), 0.7);
    for (let k = 0; k < 300; k++)
        B.step(c, 1 / 30);
    ok("another seed, another school", JSON.stringify(a.x) !== JSON.stringify(c.x));
}

// Bounded, finite and alive over a long swim, for the sizes of the bench
for (const n of [1, 3, 8, 20, 40]) {
    const s = B.create(ring(n), 0.1);
    ok(n + ": capped at " + B.MAX, s.n === Math.min(n, B.MAX));
    let worst = 0, moved = 0;
    for (let k = 0; k < 3600; k++) {
        B.step(s, 1 / 30);
        for (let i = 0; i < s.n; i++) {
            const p = B.pose(s, i);
            if (!isFinite(p.dx + p.dy + p.a))
                worst = Infinity;
            worst = Math.max(worst, Math.hypot(p.dx, p.dy));
            if (k > 1800)
                moved += Math.hypot(s.vx[i], s.vy[i]);
        }
    }
    ok(n + ": stays on its slot's patch (" + worst.toFixed(1) + " px)", worst <= B.RULES.leash + 1e-6);
    ok(n + ": keeps swimming", moved / (1800 * s.n) > 1);
}

// Separation: two fish on the same spot are pushed apart
{
    const s = B.create([[0, 0], [0, 0]], 0);
    for (let k = 0; k < 120; k++)
        B.step(s, 1 / 30);
    ok("stacked fish split", Math.hypot(s.x[0] - s.x[1], s.y[0] - s.y[1]) > 2);
}

// A stalled clock does not fling anyone; no time, no move
{
    const s = B.create(ring(5), 0.2), before = JSON.stringify(s.x);
    B.step(s, 0);
    ok("dt 0 changes nothing", JSON.stringify(s.x) === before);
    B.step(s, 50);
    ok("huge dt is clamped", Math.abs(s.t - B.DT_MAX) < 1e-9);
}

// Tilt is bounded; bad index and empty school are still poses
{
    const s = B.create(ring(6), 0.4);
    let tilt = 0;
    for (let k = 0; k < 600; k++) {
        B.step(s, 1 / 30);
        for (let i = 0; i < s.n; i++)
            tilt = Math.max(tilt, Math.abs(B.pose(s, i).a));
    }
    ok("tilt bounded", tilt <= B.TILT + 1e-9);
    ok("bad index is still", B.pose(s, 99).dx === 0 && B.pose(null, 0).a === 0);
    ok("empty school steps", B.step(B.create([], 0), 0.03).n === 0);
}

// Fixed cost: a step touches at most MAX squared pairs, whatever the input
ok("school size is capped", B.create(ring(B.MAX + 10), 0.5).n === B.MAX);

// Stacked fish with the very same speed still split (the fixed axis)
{
    const s = B.create([[0, 0], [0, 0]], 0);
    s.vx = [3, 3];
    s.vy = [-2, -2];
    for (let k = 0; k < 300; k++)
        B.step(s, 1 / 30);
    ok("stacked equal-speed fish split", Math.hypot(s.x[0] - s.x[1], s.y[0] - s.y[1]) > 2);
}

// Cohesion and alignment each change the outcome (compare with the rule at 0)
{
    const run = (rule, setup) => {
        const keepRule = B.RULES[rule], keepWander = B.RULES.wander, keepCur = B.RULES.current;
        B.RULES.wander = 0;
        B.RULES.current = 0;
        const s = B.create([[0, 0], [0, 0], [0, 0]], 0);
        setup(s);
        B.RULES[rule] = keepRule === undefined ? 0 : keepRule;
        const on = B.step(s, 0.05).vx[2];
        const t = B.create([[0, 0], [0, 0], [0, 0]], 0);
        setup(t);
        B.RULES[rule] = 0;
        const off = B.step(t, 0.05).vx[2];
        B.RULES[rule] = keepRule;
        B.RULES.wander = keepWander;
        B.RULES.current = keepCur;
        return [on, off];
    };
    // Fish 2 sits at the origin with its slot there, so the leash adds nothing
    const [c1, c0] = run("cohesion", s => {
        s.x = [40, 30, 0];
        s.y = [0, 0, 0];
        s.vx = [0, 0, 0];
        s.vy = [0, 0, 0];
    });
    ok("cohesion pulls toward the neighbours", c1 > c0 + 0.1);
    const [a1, a0] = run("align", s => {
        s.x = [50, 55, 0];
        s.y = [0, 0, 0];
        s.vx = [20, 20, 0];
        s.vy = [0, 0, 0];
    });
    ok("alignment picks up the heading", a1 > a0 + 0.1);
}

// A school that loses a member keeps the others where they swim
{
    const s = B.create(ring(4), 0.3);
    for (let k = 0; k < 90; k++)
        B.step(s, 1 / 30);
    const t = B.create(ring(3), 0.3, [1, 2, 3].map(i => B.snapshot(s, i)));
    ok("kept fish do not snap home", Math.abs(B.pose(t, 0).dx - s.x[1]) < 1e-9 && B.snapshot(s, 9) === null);
}

// The real open layout: every fish keeps its own path, not one shared drift
for (const n of [3, 8, 20]) {
    const homes = Lay.ringSpots(n, 170).map(p => [p.x, p.y]);
    const s = B.create(homes, 0.1);
    for (let k = 0; k < 900; k++)
        B.step(s, 1 / 30);
    const mx = s.x.reduce((a, b) => a + b, 0) / n, my = s.y.reduce((a, b) => a + b, 0) / n;
    let spread = 0, worst = 0;
    const tilts = [];
    for (let i = 0; i < n; i++) {
        spread = Math.max(spread, Math.hypot(s.x[i] - mx, s.y[i] - my));
        worst = Math.max(worst, Math.hypot(s.x[i], s.y[i]));
        tilts.push(B.pose(s, i).a);
    }
    ok(n + ": real slots, fish differ (" + spread.toFixed(1) + " px)", spread > 2);
    ok(n + ": real slots, tilts differ", Math.max(...tilts) - Math.min(...tilts) > 1);
    ok(n + ": real slots, inside the leash", worst <= B.RULES.leash + 1e-6);
}

// Real slots over time: the tilt eases and the fish do not ride the leash wall
for (const [n, R] of [[3, 170], [8, 170], [20, 170], [8, 90]]) {
    const homes = Lay.ringSpots(n, R).map(p => [p.x, p.y]);
    const s = B.create(homes, 0.1);
    for (let k = 0; k < 600; k++)
        B.step(s, 1 / 30);
    let samples = 0, clamped = 0, wall = 0, jump = 0, sx = 0, sy = 0;
    const prev = [];
    for (let k = 0; k < 3000; k++) {
        B.step(s, 1 / 30);
        for (let i = 0; i < n; i++) {
            const a = B.pose(s, i).a;
            if (prev[i] !== undefined)
                jump = Math.max(jump, Math.abs(a - prev[i]));
            prev[i] = a;
            samples++;
            if (Math.abs(a) >= B.TILT - 1e-9) clamped++;
            if (Math.hypot(s.x[i], s.y[i]) > B.RULES.leash - 0.01) wall++;
            sx += s.x[i];
            sy += s.y[i];
        }
    }
    ok(n + "@" + R + ": tilt change per tick " + jump.toFixed(2) + " deg", jump < 2);
    ok(n + "@" + R + ": tilt at its stop " + (100 * clamped / samples).toFixed(1) + "%", clamped / samples < 0.2);
    ok(n + "@" + R + ": on the leash " + (100 * wall / samples).toFixed(1) + "%", wall / samples < 0.1);
    ok(n + "@" + R + ": mean offset " + Math.hypot(sx, sy).toFixed(1) + " px", Math.hypot(sx, sy) / samples < 4);
}

// stale: only a change in who is awake asks for a rebuild
{
    const e = (id, awake) => ({ id, awake, x: 0, y: 0 });
    const prev = B.rebuild([e(1, true), e(2, false), e(3, true)], null, 0);
    ok("stale: same awake set", !B.stale([e(1, true), e(2, false), e(3, true)], prev));
    ok("stale: a member wakes", B.stale([e(1, true), e(2, true), e(3, true)], prev));
    ok("stale: a member sleeps", B.stale([e(1, true), e(2, false), e(3, false)], prev));
    ok("stale: nothing built yet", B.stale([e(1, true)], null));
}

// rebuild: asleep fish are left out, the others keep their offsets
{
    const e = (id, awake) => ({ id, awake, x: id * 60, y: 0 });
    const first = B.rebuild([e(1, true), e(2, false), e(3, true)], null, 0.2);
    ok("asleep left out", first.ids.join() === "1,3" && first.school.n === 2);
    for (let k = 0; k < 60; k++)
        B.step(first.school, 1 / 30);
    const next = B.rebuild([e(1, true), e(2, true), e(3, true)], first, 0.2);
    ok("fish that stay keep their offset", next.ids.join() === "1,2,3" && next.school.x[0] === first.school.x[0] && next.school.x[2] === first.school.x[1]);
    ok("more than MAX awake is capped", B.rebuild(Array.from({ length: 40 }, (_, i) => e(i, true)), null, 0).school.n === B.MAX);
}

done("boids");
