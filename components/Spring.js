.pragma library

// A damped spring, as in Orbit: an item held by the hand follows it on a
// stiff spring, and once let go it swims home on a soft, slightly bouncy one.
// k = stiffness, zeta = damping ratio (1 = no bounce, below 1 = overshoot).

// Hand and home springs (Orbit's drag values; home bounces a little)
const HELD = { "k": 700, "zeta": 0.85 };
const HOME = { "k": 170, "zeta": 0.5 };
// The lens: things it pushes aside and magnifies swing there, and back when
// it leaves, a little livelier than the way home
const LENS = { "k": 300, "zeta": 0.62 };

// Moves s = {x, y, vx, vy} toward (tx, ty) for dt seconds. Returns s.
function step(s, tx, ty, spring, dt) {
    return _run(s, tx, ty, null, spring, dt);
}

// Same for a pose p = {x, y, s, vx, vy, vs}: an offset and a scale, all
// three on one spring (ts: the target scale). Returns p.
function stepPose(p, tx, ty, ts, spring, dt) {
    return _run(p, tx, ty, ts, spring, dt);
}

// Semi-implicit Euler in 8 ms sub-steps: stable whatever the tick rate
function _run(s, tx, ty, ts, spring, dt) {
    const c = 2 * spring.zeta * Math.sqrt(spring.k);
    const n = Math.max(1, Math.ceil(dt / 0.008)), h = dt / n;
    for (let i = 0; i < n; i++) {
        s.vx += (-(s.x - tx) * spring.k - c * s.vx) * h;
        s.vy += (-(s.y - ty) * spring.k - c * s.vy) * h;
        s.x += s.vx * h;
        s.y += s.vy * h;
        if (ts !== null) {
            s.vs += (-(s.s - ts) * spring.k - c * s.vs) * h;
            s.s += s.vs * h;
        }
    }
    return s;
}

// At rest on its target: close enough, slow enough to stop the clock
function settled(s, tx, ty) {
    return Math.hypot(s.x - tx, s.y - ty) < 0.3 && Math.hypot(s.vx, s.vy) < 3;
}

function poseSettled(p, tx, ty, ts) {
    return settled(p, tx, ty) && Math.abs(p.s - ts) < 0.004 && Math.abs(p.vs) < 0.05;
}
