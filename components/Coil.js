.pragma library
.import "Shapes.js" as Shapes

// How the jellyfish's tentacle coils round a device (option A, "tight coil",
// D407): a helix along the body's long axis, seen from the side. Pure
// geometry and motion: no QML, no timer, no state. The caller owns the clock
// and asks for a pose at a given moment; it stops its timer once settled().
//
// A point is [x, y, z]: x and y are scene coordinates, z = cos(theta) is the
// depth (z > 0 in front of the body, z < 0 behind it).

// --- The shape ---------------------------------------------------------

const TURNS = 3;
// The ring's tilt: x += TILT x radius x z. It is what makes each turn read as
// a loop and not as a bar
const TILT = 0.42;
// Points per held device: 40 per turn, plus the closing one
const POINTS = 121;
// How far the ring rides off the body, in pixels, at slack = 1
const CLEAR = 4;
// A coil tighter than the body would cut through it; below slack 1 (the
// tighten overshoots) the ring keeps this share of CLEAR so it never does
const MIN_CLEAR = CLEAR * 0.25;
// The span, as a share of the body length, centred. Wide bodies (a manta, a
// NAS: length over height from WIDE_FROM) get more room to show three turns;
// the share grows to SPAN_WIDE_MAX over WIDE_RANGE more of that ratio. The
// rule lives here only.
const SPAN = 0.44;
const SPAN_WIDE = 0.50;
const SPAN_WIDE_MAX = 0.55;
const WIDE_FROM = 1.5;
const WIDE_RANGE = 1.0;

// The body the coil rides on, in scene units around (cx, cy): its convex
// outline (Shapes.js, the one the canvas strokes), scaled by s. A shoal has
// no outline of its own: its real half-height (shoalR) makes a circle, so the
// ring follows the school and never a fixed size. Phones and Pis are taller
// than wide: their long axis is y, and the walk runs in a swapped frame.
function body(kind, s, shoalR) {
    let hull;
    if (kind === "shoal") {
        hull = [];
        for (let i = 0; i < 24; i++) {
            const a = i / 24 * Math.PI * 2;
            hull.push([Math.cos(a) * shoalR, Math.sin(a) * shoalR]);
        }
    } else {
        hull = Shapes.hull(kind).map(q => [q[0] * s, q[1] * s]);
    }
    const xs = hull.map(q => q[0]), ys = hull.map(q => q[1]);
    const x0 = Math.min.apply(null, xs), x1 = Math.max.apply(null, xs);
    const y0 = Math.min.apply(null, ys), y1 = Math.max.apply(null, ys);
    const tall = (y1 - y0) > (x1 - x0) * 1.0001;
    // In the long-axis frame: u runs along "a", rings stand in "b"
    const pts = tall ? hull.map(q => [q[1], q[0]]) : hull;
    const a0 = tall ? y0 : x0, a1 = tall ? y1 : x1, b0 = tall ? x0 : y0, b1 = tall ? x1 : y1;
    return { "pts": pts, "tall": tall, "a0": a0, "a1": a1, "mid": (b0 + b1) / 2, "len": a1 - a0, "hh": (b1 - b0) / 2 };
}

// The share of the body length the coil covers
function spanShare(b) {
    const ratio = b.len / (2 * b.hh);
    if (ratio < WIDE_FROM)
        return SPAN;
    return SPAN_WIDE + (SPAN_WIDE_MAX - SPAN_WIDE) * Math.min(1, (ratio - WIDE_FROM) / WIDE_RANGE);
}

// The body's reach from its centre line at position a: the larger of the two
// half-heights, so the ring clears the body whichever side is deeper
function halfHeight(b, a) {
    let lo = Infinity, hi = -Infinity;
    const p = b.pts, n = p.length;
    for (let i = 0; i < n; i++) {
        const q = p[i], r = p[(i + 1) % n];
        if ((q[0] - a) * (r[0] - a) > 0 || q[0] === r[0])
            continue;
        const y = q[1] + (r[1] - q[1]) * (a - q[0]) / (r[0] - q[0]);
        lo = Math.min(lo, y);
        hi = Math.max(hi, y);
    }
    return lo > hi ? 0 : Math.max(hi - b.mid, b.mid - lo);
}

// The coil's points, from the entry side toward the far one. opts:
//   side   +1 / -1: which end of the long axis the tentacle enters from
//   slack  ring radius factor (1 = tight)
//   frac   how much of the coil is out, 0..1 (the reach, the unwinding)
//   sag    pixels the tip hangs down, scaled by u squared
//   lag    [x, y] the coil trails the device by, weighted 0.3 + 0.7 u
//   clear  ring clearance in pixels (tests only; default CLEAR)
function build(b, cx, cy, opts) {
    const o = opts || {};
    const side = o.side < 0 ? -1 : 1, slack = o.slack === undefined ? 1 : o.slack;
    const frac = o.frac === undefined ? 1 : Math.max(0, Math.min(1, o.frac));
    const clear = o.clear === undefined ? CLEAR : o.clear;
    const lag = o.lag || [0, 0], sag = o.sag || 0;
    const half = spanShare(b) * b.len / 2, centre = (b.a0 + b.a1) / 2;
    // The tilt moves a point along the axis by up to TILT x radius: the body is
    // measured over that whole reach, or a tilted point meets a fatter part
    const reachMax = TILT * (b.hh + clear) * Math.max(1, slack);
    const n = Math.max(2, Math.ceil((POINTS - 1) * frac) + 1);
    const out = [];
    for (let i = 0; i < n; i++) {
        const u = i / (POINTS - 1);
        const theta = -Math.PI / 2 + 2 * Math.PI * TURNS * u;
        const z = Math.cos(theta);
        const a = centre + side * half * (1 - 2 * u);
        let h = 0;
        for (let k = -2; k <= 2; k++)
            h = Math.max(h, halfHeight(b, a + reachMax * k / 2));
        const r = Math.max((h + clear) * slack, h + Math.min(MIN_CLEAR, clear * 0.25));
        const w = 0.3 + 0.7 * u;
        const pa = a + TILT * r * z + lag[b.tall ? 1 : 0] * w;
        const pb = b.mid + r * Math.sin(theta) + sag * u * u + lag[b.tall ? 0 : 1] * w;
        out.push(b.tall ? [cx + pb, cy + pa, z] : [cx + pa, cy + pb, z]);
    }
    return out;
}

// The points cut into stretches where z changes sign, each marked front
// (z > 0) or behind, and sharing one point with the next so no seam shows
function split(pts) {
    const out = [];
    let cur = null;
    for (let i = 0; i < pts.length; i++) {
        const front = pts[i][2] > 0;
        if (!cur || cur.front !== front) {
            const prev = cur ? cur.points[cur.points.length - 1] : null;
            cur = { "front": front, "points": prev ? [prev] : [] };
            out.push(cur);
        }
        cur.points.push(pts[i]);
    }
    return out;
}

// --- The motion --------------------------------------------------------

const REACH_TIME = 0.75;  // s, the coil grows from the bell's side
const SLACK_LOOSE = 1.55;  // while it grows
const TIGHTEN_AT = 0.55;  // s, when the coil starts to close
const TIGHTEN_AMP = 0.55, TIGHTEN_DECAY = 7, TIGHTEN_FREQ = 13;  // damped oscillation
const LAG_K = 90, LAG_ZETA = 0.40;  // the coil trails a dragged device
const SLEEP_TIME = 0.9;  // s, to let go
const SLEEP_SLACK = 1.5;  // factor on the ring when asleep
const SLEEP_SAG = 16;  // px the tip hangs
const SLEEP_KEEP = 0.30;  // share of its length the coil keeps asleep
// "Settled": the slack within this of 1, the lag under LAG_REST pixels
const SLACK_REST = 0.01, LAG_REST = 0.5;
const LAG_STEP = 0.004;  // s, the spring's internal step (stable at k = 90)

function _clamp01(v) {
    return Math.max(0, Math.min(1, v));
}

// How much of the coil is out, t seconds after the device appears
function reach(t) {
    const x = _clamp01(t / REACH_TIME);
    return 1 - Math.pow(1 - x, 3);
}

// The ring factor t seconds after the device appears: loose while it grows,
// then the damped tightening
function slackAt(t) {
    if (t < TIGHTEN_AT)
        return SLACK_LOOSE;
    const d = t - TIGHTEN_AT;
    return 1 + TIGHTEN_AMP * Math.exp(-TIGHTEN_DECAY * d) * Math.cos(TIGHTEN_FREQ * d);
}

// 0 awake .. 1 asleep, t seconds after the change (smoothstep)
function sleepAmount(t, asleep) {
    const x = _clamp01(t / SLEEP_TIME), s = x * x * (3 - 2 * x);
    return asleep ? s : 1 - s;
}

// One step of the drag lag. lag = {p: [x, y], v: [x, y]} is how far the coil
// trails the device; move is how far the device went in dt. Returns a new lag.
function lagStep(lag, move, dt) {
    const c = 2 * LAG_ZETA * Math.sqrt(LAG_K);
    const p = [lag.p[0] - move[0], lag.p[1] - move[1]], v = [lag.v[0], lag.v[1]];
    for (let t = 0; t < dt; t += LAG_STEP) {
        const h = Math.min(LAG_STEP, dt - t);
        for (let k = 0; k < 2; k++) {
            v[k] += (-LAG_K * p[k] - c * v[k]) * h;
            p[k] += v[k] * h;
        }
    }
    return { "p": p, "v": v };
}

// The state a coil starts in
function rest() {
    return { "p": [0, 0], "v": [0, 0] };
}

// Is the motion over? The caller stops its timer on true. st = {t (since the
// device appeared), asleepFor (since going to sleep, or -1 awake), lag}.
// Time alone settles the tightening: after it the slack is within 1 % of 1.
function settled(st) {
    const done = st.t >= TIGHTEN_AT + Math.log(TIGHTEN_AMP / SLACK_REST) / TIGHTEN_DECAY
        && st.t >= REACH_TIME && (st.asleepFor < 0 || st.asleepFor >= SLEEP_TIME);
    return done && Math.hypot(st.lag.p[0], st.lag.p[1]) < LAG_REST && Math.hypot(st.lag.v[0], st.lag.v[1]) < LAG_REST * 4;
}

// The pose that motion ends in: fully out, tight, no lag; asleep it is
// loose, short and sagging
function finalOpts(side, asleep) {
    return asleep
        ? { "side": side, "slack": SLEEP_SLACK, "frac": SLEEP_KEEP, "sag": SLEEP_SAG, "lag": [0, 0] }
        : { "side": side, "slack": 1, "frac": 1, "sag": 0, "lag": [0, 0] };
}

// The build options at a moment (see settled for st). Once settled the final
// pose is returned exactly, not a limit of the motion. reduceMotion skips
// every transition.
function optsAt(st, side, reduceMotion) {
    const asleep = st.asleepFor >= 0;
    if (reduceMotion || settled(st))
        return finalOpts(side, asleep);
    const sleep = asleep ? sleepAmount(st.asleepFor, true) : 0;
    return {
        "side": side,
        "slack": slackAt(st.t) * (1 + (SLEEP_SLACK - 1) * sleep),
        "frac": reach(st.t) * (1 - (1 - SLEEP_KEEP) * sleep),
        "sag": SLEEP_SAG * sleep,
        "lag": st.lag.p
    };
}
