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
// opts: { warnMs, badMs } to override the latency thresholds.
// Returns { state, reason }; the worst state wins and its reason is the
// one given. On a tie the order is relay, Internet exit, latency.
function evaluate(input, opts) {
    const i = input || {}, o = opts || {};
    const warnMs = _num(o.warnMs, LATENCY_WARN_MS), badMs = _num(o.badMs, LATENCY_BAD_MS);
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
