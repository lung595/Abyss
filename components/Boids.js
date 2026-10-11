.pragma library

// A school of fish for an open group: light boids that stay on their home
// slot. Each member feels cohesion and alignment with the neighbours it can
// see (real positions, so distant slots do not merge), separation from fish
// too close, a leash back to its own slot, its own slow wander and a gentle
// shared current. Pure maths: GroupPeek steps it on the scene's swim clock, so
// it only moves while the group is open and watched. The cost is fixed and
// small: at most MAX fish, one pass over the pairs per step (MAX squared checks).

// Never more fish than this (the bubble shows a dozen or so, the rest are
// found by search), so one step is at most MAX * MAX pair checks
const MAX = 24;
// Rules (px, px/s): how far a fish may stray from its slot, how close it lets
// a neighbour come, its cruise speed and how hard each rule pulls
const RULES = { "leash": 16, "gap": 26, "speed": 18, "cohesion": 0.9, "align": 1.6, "split": 38, "home": 1.4, "damp": 0.8, "current": 3, "wander": 14, "sight": 70 };
// Longest step the maths accepts (a stalled clock must not fling the fish)
const DT_MAX = 0.1;
// Tilt grows with the vertical speed (full tilt at cruise speed), never more
// than this (degrees), and is low-passed in the state
const TILT = 12;

// homes: [[x, y], ...] the slots in px. seed (0..1) sets where the school
// starts in its current, so two groups never swim in step. keep (optional)
// holds, per slot, the {dx, dy, vx, vy} of a fish that was already swimming,
// so a school that gains or loses a member does not snap back to its slots.
function create(homes, seed, keep) {
    const n = Math.min(MAX, homes.length), s = { "n": n, "x": [], "y": [], "vx": [], "vy": [], "ta": [], "hx": [], "hy": [], "t": 0, "seed": seed || 0 };
    for (let i = 0; i < n; i++) {
        s.hx.push(homes[i][0]);
        s.hy.push(homes[i][1]);
        const k = keep && keep[i];
        if (k) {
            s.x.push(k.dx);
            s.y.push(k.dy);
            s.vx.push(k.vx);
            s.vy.push(k.vy);
            s.ta.push(0);
            continue;
        }
        s.x.push(0);
        s.y.push(0);
        s.ta.push(0);
        // A tiny deterministic heading so nobody starts frozen
        const a = 2 * Math.PI * (((seed || 0) * 7 + i * 0.618) % 1);
        s.vx.push(Math.cos(a) * RULES.speed * 0.5);
        s.vy.push(Math.sin(a) * RULES.speed * 0.5);
    }
    return s;
}

// The slow shared current at time t (px/s): one gentle loop for everybody
function _current(s) {
    const w = 2 * Math.PI;
    return [RULES.current * Math.cos(w * (0.045 * s.t + s.seed)), RULES.current * 0.6 * Math.cos(w * (0.07 * s.t + s.seed + 0.25))];
}

// Advances the school by dt seconds (mutates s and returns it)
function step(s, dt) {
    dt = Math.min(DT_MAX, Math.max(0, dt));
    if (dt === 0 || s.n === 0)
        return s;
    s.t += dt;
    const n = s.n, R = RULES, cur = _current(s), w = 2 * Math.PI;
    const ax = [], ay = [];
    for (let i = 0; i < n; i++) {
        // Own wander (phase from index and seed) so no two fish share a path,
        // plus the current and the leash home
        const ph = s.seed + i * 0.382;
        let fx = cur[0] + R.wander * Math.cos(w * ((0.05 + 0.013 * (i % 5)) * s.t + ph)) - s.x[i] * R.home;
        let fy = cur[1] + R.wander * Math.sin(w * ((0.06 + 0.011 * (i % 7)) * s.t + ph)) - s.y[i] * R.home;
        const px = s.hx[i] + s.x[i], py = s.hy[i] + s.y[i];
        let nx = 0, ny = 0, nvx = 0, nvy = 0, m = 0;
        for (let j = 0; j < n; j++) {
            if (j === i)
                continue;
            const qx = s.hx[j] + s.x[j], qy = s.hy[j] + s.y[j], dx = px - qx, dy = py - qy, d = Math.hypot(dx, dy);
            if (d < R.sight) {
                // A neighbour in sight: counted for cohesion and alignment. Cohesion works on
                // offsets, so the spacing of the slots is not part of the force
                nx += s.x[j];
                ny += s.y[j];
                nvx += s.vx[j];
                nvy += s.vy[j];
                m++;
            }
            if (d < R.gap) {
                if (d > 1e-6) {
                    // Separation: push away from fish nearer than the gap
                    const k = R.split * (1 - d / R.gap) / d;
                    fx += dx * k;
                    fy += dy * k;
                } else {
                    // Exactly on top of each other: split along a fixed axis, the lower index one way, the other the opposite
                    fx += i < j ? R.split : -R.split;
                }
            }
        }
        if (m > 0) {
            fx += (nx / m - s.x[i]) * R.cohesion + (nvx / m - s.vx[i]) * R.align;
            fy += (ny / m - s.y[i]) * R.cohesion + (nvy / m - s.vy[i]) * R.align;
        }
        ax.push(fx);
        ay.push(fy);
    }
    const ease = 1 - Math.exp(-4 * dt), damp = Math.exp(-R.damp * dt), top = R.speed * 2;
    for (let i = 0; i < n; i++) {
        let vx = (s.vx[i] + ax[i] * dt) * damp, vy = (s.vy[i] + ay[i] * dt) * damp;
        const v = Math.hypot(vx, vy);
        if (v > top) {
            vx *= top / v;
            vy *= top / v;
        }
        s.vx[i] = vx;
        s.vy[i] = vy;
        let x = s.x[i] + vx * dt, y = s.y[i] + vy * dt;
        // Hard leash: never out of its slot's patch
        const r = Math.hypot(x, y);
        if (r > R.leash) {
            x *= R.leash / r;
            y *= R.leash / r;
            // Lose the part of the speed that pushed outward
            const dot = (vx * x + vy * y) / (R.leash * R.leash);
            if (dot > 0) {
                s.vx[i] = vx - x * dot;
                s.vy[i] = vy - y * dot;
            }
        }
        s.x[i] = x;
        s.y[i] = y;
        // Tilt eases toward the vertical speed so a bump (leash, separation) never snaps the nose
        s.ta[i] += (Math.max(-TILT, Math.min(TILT, TILT * s.vy[i] / R.speed)) - s.ta[i]) * ease;
    }
    return s;
}

// Fish i now: {dx, dy} offset from its slot (px), a tilt (degrees, nose
// toward where it goes). Out of range gives a still pose.
function pose(s, i) {
    if (!s || i < 0 || i >= s.n)
        return { "dx": 0, "dy": 0, "a": 0 };
    return { "dx": s.x[i], "dy": s.y[i], "a": s.ta[i] };
}

// The state of fish i for create()'s keep list (null when out of range)
function snapshot(s, i) {
    return s && i >= 0 && i < s.n ? { "dx": s.x[i], "dy": s.y[i], "vx": s.vx[i], "vy": s.vy[i] } : null;
}

// A school for the awake entries ({id, awake, x, y}, the slots in px), keeping
// the offsets of the fish already in prev ({ids, school}, or null). Returns
// {ids, school}; asleep entries are left out so they never push the others.
function rebuild(entries, prev, seed) {
    const ids = [], homes = [], keep = [];
    for (const e of entries) {
        if (!e.awake)
            continue;
        ids.push(e.id);
        homes.push([e.x, e.y]);
        keep.push(prev ? snapshot(prev.school, prev.ids.indexOf(e.id)) : null);
    }
    return { "ids": ids, "school": create(homes, seed, keep) };
}

// True when prev no longer matches the awake entries' ids (same order), so
// GroupPeek rebuilds only when a member came, left or fell asleep
function stale(entries, prev) {
    if (!prev)
        return true;
    let k = 0;
    for (const e of entries) {
        if (!e.awake)
            continue;
        if (k >= prev.ids.length || prev.ids[k] !== e.id)
            return true;
        k++;
    }
    return k !== prev.ids.length;
}
