.pragma library

// Mesh health for the bar jellyfish: "ok", "warn" or "bad" and one short
// reason, as a pure function tested with gjs in tests/. Nothing here
// measures anything; the caller passes what the NetBird refresh already
// knows. Missing or unknown fields never raise an alarm: an unknown is "ok".

// Round trip times (ms) above which a link is slow, then unusable (Q97)
const LATENCY_WARN_MS = 150;
const LATENCY_BAD_MS = 500;

const _RANK = { "ok": 0, "warn": 1, "bad": 2 };

// input: {
//   relays: { up, total }            relay servers reachable / known
//   peers: [{ connected, latencyMs }]
//   exit: { active, up }             Internet exit chosen / carrying traffic
// }
// opts: { warnMs, badMs } to override the latency thresholds; unusable
// values, or a warn threshold above the bad one, fall back to the defaults.
// Returns { state, reason }; the worst state wins and its reason is the
// one given. On a tie the order is relay, Internet exit, latency.
function evaluate(input, opts) {
    const i = input || {}, o = opts || {};
    let warnMs = _num(o.warnMs, LATENCY_WARN_MS), badMs = _num(o.badMs, LATENCY_BAD_MS);
    if (warnMs > badMs) {
        warnMs = LATENCY_WARN_MS;
        badMs = LATENCY_BAD_MS;
    }
    const found = [_relay(i.relays), _exit(i.exit), _latency(i.peers, warnMs, badMs)];
    let best = { "state": "ok", "reason": "Everything is connected." };
    found.forEach(f => {
        if (f && _RANK[f.state] > _RANK[best.state])
            best = f;
    });
    return best;
}

function _num(v, fallback) {
    const n = Number(v);
    return v !== undefined && v !== null && isFinite(n) && n > 0 ? n : fallback;
}

function _count(v) {
    return typeof v === "number" && isFinite(v) && v >= 0 ? v : -1;
}

function _relay(r) {
    if (!r)
        return null;
    const up = _count(r.up), total = _count(r.total);
    if (total <= 0 || up < 0)
        return null;
    if (up === 0)
        return { "state": "bad", "reason": "No relay server is reachable." };
    if (up < total)
        return { "state": "warn", "reason": "Some relay servers are unreachable." };
    return null;
}

function _exit(e) {
    // Only an exit the user chose can be "down"; having none is normal
    if (e && e.active === true && e.up === false)
        return { "state": "bad", "reason": "The Internet exit is down." };
    return null;
}

function _latency(peers, warnMs, badMs) {
    if (!Array.isArray(peers))
        return null;
    let worst = -1;
    peers.forEach(p => {
        // A device that is offline has no meaningful latency
        if (p && p.connected === true && typeof p.latencyMs === "number" && isFinite(p.latencyMs))
            worst = Math.max(worst, p.latencyMs);
    });
    if (worst >= badMs)
        return { "state": "bad", "reason": "A device answers very slowly (" + Math.round(worst) + " ms)." };
    if (worst >= warnMs)
        return { "state": "warn", "reason": "A device answers slowly (" + Math.round(worst) + " ms)." };
    return null;
}

// A QML "var" can hand lists over as array-like wrappers that fail
// Array.isArray; copy them into real arrays
function _list(v) {
    return v && typeof v.length === "number" ? Array.from(v) : [];
}

// What evaluate() needs, read from a NetBird view ({ relays: [{ available }],
// peers: [{ name, online, latencyMs }] }) and the name of the peer carrying
// Internet ("" for none). An exit peer the view does not list is not
// reported down: only a known, offline one is.
function inputOf(view, exitNode) {
    const v = view || {}, relays = _list(v.relays), peers = _list(v.peers);
    const carrier = exitNode ? peers.find(p => p && p.name === exitNode) : null;
    return {
        "relays": { "up": relays.filter(r => r && r.available).length, "total": relays.length },
        // The smoothed latency when the view has one, so a single spike does not flip the colour
        "peers": peers.map(p => ({ "connected": !!(p && p.online), "latencyMs": p ? (typeof p.steadyMs === "number" ? p.steadyMs : p.latencyMs) : undefined })),
        "exit": { "active": !!carrier, "up": carrier ? !!carrier.online : true }
    };
}

// The DMS Theme colour a state is drawn with, by property name: the one
// place the mapping lives, shared by the widget and the preview.
function colorRole(state) {
    return state === "bad" ? "error" : state === "warn" ? "warning" : "primary";
}
