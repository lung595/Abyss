.pragma library

// Darwin, the bowl's goldfish, as pure data: where he is, what he is doing
// and how he holds himself. He is the bowl's cleaner: traffic drops crumbs
// into the water and he eats them, a film of algae slowly clouds the glass
// and he scrubs it off, he sleeps on the bottom while the mesh is down and
// waves back when clicked. Moved by the scene clock only (it runs while
// someone watches), so nothing grows, falls or swims unseen.
// Drawn by Goldfish.qml; tested with gjs in tests/goldfish.test.js.

// Swimming speeds (px/s) for each mood
const SPEED = { "swim": 34, "eat": 62, "scrub": 48, "sleep": 22, "wave": 0 };
// A crumb for every this many bits of traffic… (about one every few seconds
// on a busy mesh), never more than a handful in the water at once
const CRUMB_BITS = 12e6, MAX_CRUMBS = 5, CRUMB_FALL = 14;
// Seconds of watching for a patch of glass to cloud over, and to scrub it
const DIRT_GROWS = 300, SCRUB_TAKES = 3.5, DIRTY = 0.5, CLEAN = 0.02;
const WAVE_TAKES = 1.8, EAT_TAKES = 0.45;

// A small repeatable random source (the same bowl for the same seed); Mood.js
// draws from it too, on its own state
function random(s) {
    s.seed = (s.seed * 16807) % 2147483647;
    return (s.seed - 1) / 2147483646;
}

// b: the water he may use { l, r, top, bottom } (bottom = the floor)
function create(b, seed) {
    const s = {
        "seed": Math.max(1, seed || 7),
        "x": (b.l + b.r) / 2 + (b.r - b.l) * 0.2,
        "y": (b.top + b.bottom) / 2,
        "vx": 0,
        "vy": 0,
        "dir": -1,
        "mood": "swim",
        "moodT": 0,
        "goal": null,
        "crumbs": [],
        "feed": 0,
        "spots": [],
        "munch": 0,
        "blinkAt": 3
    };
    // Where the glass clouds over: a few patches spread over the water,
    // each growing at its own pace
    for (let i = 0; i < 4; i++)
        s.spots.push({
            "x": b.l + (b.r - b.l) * (0.14 + 0.24 * i + 0.06 * random(s)),
            "y": b.top + (b.bottom - b.top) * (0.3 + 0.5 * random(s)),
            "r": 16 + 10 * random(s),
            "pace": 0.7 + 0.6 * random(s),
            "dirt": 0
        });
    return s;
}

function _setMood(s, mood) {
    if (s.mood !== mood) {
        s.mood = mood;
        s.moodT = 0;
        s.goal = null;
    }
}

function _clampTo(b, p) {
    return { "x": Math.max(b.l, Math.min(b.r, p.x)), "y": Math.max(b.top, Math.min(b.bottom, p.y)) };
}

// Clicked: he stops and waves (not while asleep)
function wave(s) {
    if (s.mood !== "sleep")
        _setMood(s, "wave");
    return s;
}

// dt in seconds; env: { b, asleep (the mesh is down), bits (traffic in bits/s) }
function step(s, dt, env) {
    const b = env.b;
    s.moodT += dt;

    // Crumbs: traffic drops them from the surface, they sink and settle
    if (!env.asleep) {
        s.feed += dt * Math.max(0, env.bits || 0) / CRUMB_BITS;
        if (s.feed >= 1) {
            s.feed = 0;
            if (s.crumbs.length < MAX_CRUMBS)
                s.crumbs.push({ "x": b.l + (b.r - b.l) * (0.1 + 0.8 * random(s)), "y": b.top, "k": random(s) * 6 });
        }
    }
    s.crumbs.forEach(c => c.y = Math.min(b.bottom + 4, c.y + CRUMB_FALL * dt));
    // The glass clouds over while someone watches
    // (not the patch he is scrubbing)
    const rubbed = s.mood === "scrub" && s.goal ? s.goal.spot : null;
    s.spots.forEach(p => {
        if (p !== rubbed)
            p.dirt = Math.min(1, p.dirt + dt * p.pace / DIRT_GROWS);
    });

    // A patch scrubbed clean: look for the next one
    if (s.mood === "scrub" && s.goal && s.goal.spot.dirt <= CLEAN)
        s.goal = null;
    // What to do next: sleep with the mesh, finish a wave, then crumbs,
    // then the dirtiest glass, else swim about
    if (env.asleep)
        _setMood(s, "sleep");
    else if (s.mood === "wave" && s.moodT < WAVE_TAKES)
        ;
    else if (s.crumbs.length)
        _setMood(s, "eat");
    else if (s.mood === "scrub" && s.goal)
        ;
    else if (s.spots.some(p => p.dirt >= DIRTY))
        _setMood(s, "scrub");
    else
        _setMood(s, "swim");

    // Where to go
    if (s.mood === "sleep") {
        s.goal = s.goal || _clampTo(b, { "x": b.l + (b.r - b.l) * 0.3, "y": b.bottom });
    } else if (s.mood === "eat") {
        let best = null;
        s.crumbs.forEach(c => {
            if (!best || Math.hypot(c.x - s.x, c.y - s.y) < Math.hypot(best.x - s.x, best.y - s.y))
                best = c;
        });
        s.goal = { "x": best.x, "y": best.y, "crumb": best };
    } else if (s.mood === "scrub") {
        if (!s.goal) {
            const p = s.spots.reduce((a, q) => q.dirt > a.dirt ? q : a);
            s.goal = { "x": p.x, "y": p.y, "spot": p };
        }
    } else if (s.mood === "swim") {
        if (!s.goal || s.moodT > 9 || Math.hypot(s.goal.x - s.x, s.goal.y - s.y) < 8) {
            s.goal = _clampTo(b, { "x": b.l + (b.r - b.l) * random(s), "y": b.top + (b.bottom - 10 - b.top) * random(s) });
            s.moodT = 0;
        }
    }

    // Arrived: eat, scrub, rest
    const g = s.goal, far = g ? Math.hypot(g.x - s.x, g.y - s.y) : 0;
    if (s.mood === "eat" && far < 7) {
        s.crumbs = s.crumbs.filter(c => c !== g.crumb);
        s.munch = EAT_TAKES;
    }
    const scrubbing = s.mood === "scrub" && far < 10;
    if (scrubbing)
        g.spot.dirt = Math.max(0, g.spot.dirt - dt / SCRUB_TAKES);
    s.munch = Math.max(0, s.munch - dt);

    // Swim there: steer, ease the speed, slow down on arrival
    let tx = 0, ty = 0;
    if (g && s.mood !== "wave" && !scrubbing) {
        const v = SPEED[s.mood] * Math.min(1, far / 30);
        tx = far > 0.5 ? (g.x - s.x) / far * v : 0;
        ty = far > 0.5 ? (g.y - s.y) / far * v : 0;
    }
    const k = Math.min(1, dt * 2.5);
    s.vx += (tx - s.vx) * k;
    s.vy += (ty - s.vy) * k;
    const p = _clampTo(b, { "x": s.x + s.vx * dt, "y": s.y + s.vy * dt });
    s.x = p.x;
    s.y = p.y;
    // Turn round only for a clear move, so he does not flicker
    if (Math.abs(s.vx) > 6)
        s.dir = s.vx > 0 ? 1 : -1;
    s.scrubbing = scrubbing;
    return s;
}

// How he holds himself at time t (s): angles in degrees, lid and mouth 0..1
function pose(s, t) {
    const speed = Math.hypot(s.vx, s.vy), busy = Math.min(1, speed / 40);
    const asleep = s.mood === "sleep" && speed < 4;
    // Blink every few seconds (a short, fixed rhythm; no randomness to store)
    const blink = asleep ? 1 : ((t % 4.3) < 0.14 ? 1 : 0);
    return {
        "tail": Math.sin(t * (asleep ? 1.5 : 5 + 7 * busy)) * (asleep ? 6 : 12 + 14 * busy),
        // No legs, two little arms: the far one swings as he swims, the near
        // one waves hello, rubs the glass, paddles otherwise ("fin")
        "arms": asleep ? 10 : Math.sin(t * (4 + 8 * busy)) * (8 + 22 * busy),
        "fin": s.mood === "wave" ? -70 + Math.sin(t * 12) * 30 : s.scrubbing ? -30 + Math.sin(t * 16) * 35 : Math.sin(t * 3.2) * 14,
        "lid": blink,
        "mouth": s.munch > 0 ? Math.abs(Math.sin(s.munch * 14)) : asleep ? 0.2 : 0,
        "bob": asleep ? Math.sin(t * 1.2) * 0.8 : Math.sin(t * 2) * 1.5,
        "tilt": asleep ? 8 : Math.max(-15, Math.min(15, s.vy / 3)),
        "asleep": asleep
    };
}
