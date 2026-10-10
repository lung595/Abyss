.pragma library
.import "Goldfish.js" as Goldfish

// Darwin's moods as a small automaton with inertia. Events push it between
// states; the weights it reports never snap, they rise and fade over time so
// the drawing can blend poses. Pure data, nothing allocated per step, the same
// run for the same seed. Not wired yet: Goldfish.qml reads it later (NAK-239).
// Tested with gjs in tests/mood.test.js.

// The blendable moods, in the order of the weights array
const CALM = 0, CURIOUS = 1, SCARED = 2, JOY = 3, SLEEPY = 4, HUNGRY = 5, CLEANING = 6, MOODS = 7;
// What the automaton is doing; hiding and cautious are phases of the fright
const S_CALM = 0, S_CURIOUS = 1, S_SCARED = 2, S_HIDING = 3, S_CAUTIOUS = 4, S_JOY = 5, S_SLEEPY = 6, S_HUNGRY = 7, S_CLEANING = 8;

// The weight each state aims for, per mood (rows follow the states above)
const TARGET = [
    [1, 0, 0, 0, 0, 0, 0],
    [0.35, 1, 0, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 0],
    [0.6, 0.15, 0.4, 0, 0, 0, 0],
    [0.3, 0.2, 0, 1, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 0],
    [0.3, 0, 0, 0, 0, 1, 0],
    [0.3, 0, 0, 0, 0, 0, 1]
];
// Seconds a weight takes to rise (quick on a fright) and to fade (slower, so
// a mood lingers), and how long each timed state lasts
const RISE = 0.3, RISE_SCARED = 0.1, FADE = 1.2;
const SCARED_T = 1.2, HIDE_MIN = 2.5, HIDE_SPAN = 1.5, CAUTIOUS_T = 3, JOY_T = 2.5, CURIOUS_T = 4;
// Idle seconds before he gets bored (drowsy) and falls asleep
const IDLE_SLEEP = 45;
// The pointer steers his gaze while it is fresh (seconds), then the lamp does
const POINTER_FRESH = 5, GAZE_EASE = 6;
// A needs level (0..1) that makes him look for food or glass to scrub
const NEED = 0.5, NEED_DONE = 0.1;
// Breath and fin rates (rad/s) for calm and for a fright, blended by weights
const BREATH_CALM = 1.6, BREATH_SCARED = 7, BREATH_SLEEP = 0.9, FIN_CALM = 3.2, FIN_SCARED = 14;
const TAU = Math.PI * 2;

// bounds: the water he may use { l, r, top, bottom }; hides: spots he may
// hide in [{ x, y }], chosen once and never rebuilt
function create(bounds, hides, seed) {
    const cx = (bounds.l + bounds.r) / 2, cy = (bounds.top + bounds.bottom) / 2;
    const s = {
        "seed": Math.max(1, seed || 7),
        "b": bounds,
        "hides": hides || [],
        "state": S_CALM,
        "t": 0,
        "hideFor": 0,
        "idle": 0,
        "pointerAge": 1e9,
        "px": cx, "py": cy,
        "lx": cx, "ly": cy,
        "hunger": 0,
        "dirt": 0,
        // Outputs, rewritten in place at every step
        "w": [1, 0, 0, 0, 0, 0, 0],
        "gx": cx, "gy": cy,
        "hide": -1,
        "finPhase": 0, "breathPhase": 0,
        "finRate": FIN_CALM, "breathRate": BREATH_CALM
    };
    return s;
}

function _enter(s, state) {
    s.state = state;
    s.t = 0;
}

// The spot farthest from where the threat came from (the first one on a tie)
function _chooseHide(s, fromX, fromY) {
    let best = -1, bestD = -1;
    for (let i = 0; i < s.hides.length; i++) {
        const d = Math.hypot(s.hides[i].x - fromX, s.hides[i].y - fromY);
        if (d > bestD) {
            bestD = d;
            best = i;
        }
    }
    return best;
}

function _scare(s, x, y) {
    if (s.state === S_HIDING)
        s.t = 0;
    else if (s.state !== S_SCARED)
        _enter(s, S_SCARED);
    s.hideFor = HIDE_MIN + HIDE_SPAN * Goldfish.random(s);
    s.hide = _chooseHide(s, x, y);
}

// Pointer position (the gaze) and lamp position: not events that disturb him
function pointer(s, x, y) {
    s.px = x;
    s.py = y;
    s.pointerAge = 0;
}

function lamp(s, x, y) {
    s.lx = x;
    s.ly = y;
}

// Needs from the bowl (Goldfish.js): crumbs in the water, glass cloudy
function needs(s, hunger, dirt) {
    s.hunger = hunger;
    s.dirt = dirt;
}

// kind: "rush" (the pointer dashes at him, from x, y), "deviceDown", "relay"
// (a relay blinks), "join" (a new device), "file" (a file passes in a
// tentacle at x, y), "success" (a connection or a send worked), "click"
function event(s, kind, x, y) {
    const st = s.state;
    s.idle = 0;
    if (kind === "rush") {
        _scare(s, x === undefined ? s.px : x, y === undefined ? s.py : y);
    } else if (kind === "deviceDown") {
        if (st !== S_SCARED && st !== S_HIDING)
            _scare(s, s.px, s.py);
    } else if (st === S_SCARED || st === S_HIDING) {
        // Too frightened to care about anything else
    } else if (kind === "click") {
        _enter(s, st === S_SLEEPY ? S_CURIOUS : S_JOY);
    } else if (kind === "success") {
        _enter(s, S_JOY);
    } else if (kind === "relay" || kind === "join" || kind === "file") {
        if (st !== S_JOY)
            _enter(s, S_CURIOUS);
        if (x !== undefined) {
            s.lx = x;
            s.ly = y;
            s.pointerAge = 1e9;
        }
    }
    return s;
}

// What he does next once the current state has run its course
function _settle(s) {
    if (s.idle >= IDLE_SLEEP)
        _enter(s, S_SLEEPY);
    else if (s.hunger >= NEED)
        _enter(s, S_HUNGRY);
    else if (s.dirt >= NEED)
        _enter(s, S_CLEANING);
    else
        _enter(s, S_CALM);
}

function _advance(s) {
    const st = s.state, t = s.t;
    if (st === S_SCARED && t >= SCARED_T) {
        _enter(s, S_HIDING);
    } else if (st === S_HIDING && t >= s.hideFor) {
        _enter(s, S_CAUTIOUS);
        s.hide = -1;
    } else if (st === S_CAUTIOUS && t >= CAUTIOUS_T) {
        _settle(s);
    } else if (st === S_JOY && t >= JOY_T || st === S_CURIOUS && t >= CURIOUS_T) {
        _settle(s);
    } else if (st === S_CALM) {
        // Calm is the resting state: needs and boredom take it from here
        if (s.idle >= IDLE_SLEEP || s.hunger >= NEED || s.dirt >= NEED)
            _settle(s);
    } else if (st === S_HUNGRY && s.hunger < NEED_DONE || st === S_CLEANING && s.dirt < NEED_DONE) {
        _enter(s, S_CALM);
    } else if (st === S_SLEEPY && s.idle < IDLE_SLEEP) {
        _enter(s, S_CALM);
    }
}

function _ease(from, to, dt, tau) {
    return from + (to - from) * (1 - Math.exp(-dt / tau));
}

// Advances the automaton, the weights, the gaze and the phases by dt seconds
function step(s, dt, env) {
    s.t += dt;
    s.idle += dt;
    s.pointerAge += dt;
    if (env) {
        if (env.hunger !== undefined)
            s.hunger = env.hunger;
        if (env.dirt !== undefined)
            s.dirt = env.dirt;
    }
    _advance(s);

    const target = TARGET[s.state], w = s.w;
    for (let i = 0; i < MOODS; i++) {
        const rise = i === SCARED ? RISE_SCARED : RISE;
        w[i] = _ease(w[i], target[i], dt, target[i] > w[i] ? rise : FADE);
    }

    // Gaze: the fresh pointer, else the lamp; asleep he looks down
    const fresh = s.pointerAge < POINTER_FRESH;
    const tx = s.state === S_SLEEPY ? s.b.l + (s.b.r - s.b.l) / 2 : fresh ? s.px : s.lx;
    const ty = s.state === S_SLEEPY ? s.b.bottom : fresh ? s.py : s.ly;
    const k = Math.min(1, dt * GAZE_EASE);
    s.gx += (tx - s.gx) * k;
    s.gy += (ty - s.gy) * k;

    // Breath and fins speed up with fright and slow down asleep
    const fright = w[SCARED], sleepy = w[SLEEPY];
    s.breathRate = (BREATH_CALM + (BREATH_SCARED - BREATH_CALM) * fright) * (1 - sleepy) + BREATH_SLEEP * sleepy;
    s.finRate = (FIN_CALM + (FIN_SCARED - FIN_CALM) * fright) * (1 - 0.6 * sleepy);
    s.finPhase = (s.finPhase + s.finRate * dt) % TAU;
    s.breathPhase = (s.breathPhase + s.breathRate * dt) % TAU;
    return s;
}
