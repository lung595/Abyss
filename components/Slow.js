.pragma library

// "Why is it slow?" as one pure verdict, tested with gjs in tests/. It only
// reads what Abyss already knows about a link (direct or relayed, the reason
// NetBird gives for a relay, the latency) and, when the person asked for it,
// a measured throughput. Nothing here measures anything.

// The levels, best first. "unknown" is for a link with nothing to judge.
const LEVELS = ["good", "fair", "slow", "unknown"];

// The thresholds, all overridable by the caller. Latency in ms, throughput
// in Mbit/s. A link at or beyond "slow" is slow; at or beyond "fair" it is
// only fair. For throughput the test runs the other way (lower is worse).
const DEFAULTS = {
    fairLatencyMs: 50,
    slowLatencyMs: 150,
    fairMbps: 50,
    slowMbps: 10
};

function _num(v) {
    if (v === undefined || v === null || v === "")
        return NaN;
    const n = Number(v);
    return isFinite(n) && n >= 0 ? n : NaN;
}

// A pair where "fair" lies beyond "slow" would skip the fair level, so that
// pair falls back to the defaults (latency: higher is worse, speed: lower is).
function _limits(t) {
    const o = Object.assign({}, DEFAULTS);
    for (const k of Object.keys(DEFAULTS)) {
        const n = _num(t && t[k]);
        if (!isNaN(n))
            o[k] = n;
    }
    if (o.fairLatencyMs > o.slowLatencyMs) {
        o.fairLatencyMs = DEFAULTS.fairLatencyMs;
        o.slowLatencyMs = DEFAULTS.slowLatencyMs;
    }
    if (o.fairMbps < o.slowMbps) {
        o.fairMbps = DEFAULTS.fairMbps;
        o.slowMbps = DEFAULTS.slowMbps;
    }
    return o;
}

// link: { direct, relayReason, latencyMs, mbps }
//   direct       true (direct), false (relayed); anything else is not known
//   relayReason  why NetBird relays, as text ("" or missing when not said)
//   latencyMs    round trip in ms, or missing
//   mbps         measured throughput in Mbit/s, or missing (never measured)
// Returns { level, text }: exactly one plain sentence for the card, no em
// dash. The relay reason is data from outside: any dash, newline, control
// character or sentence mark in it is flattened and its length capped.
function verdict(link, thresholds) {
    const l = link || {};
    const t = _limits(thresholds);
    const lat = _num(l.latencyMs);
    const mbps = _num(l.mbps);
    const known = l.direct === true || l.direct === false;
    const relayed = l.direct === false;
    const why = _clean(l.relayReason);

    if (isNaN(lat) && isNaN(mbps) && !known)
        return { level: "unknown", text: "Not enough information about this link yet." };

    let rank = 0;
    if (!isNaN(lat))
        rank = Math.max(rank, lat >= t.slowLatencyMs ? 2 : lat >= t.fairLatencyMs ? 1 : 0);
    if (!isNaN(mbps))
        rank = Math.max(rank, mbps <= t.slowMbps ? 2 : mbps <= t.fairMbps ? 1 : 0);
    // A relay adds a detour whatever the numbers say, so it is never "good"
    if (relayed)
        rank = Math.max(rank, 1);

    const level = LEVELS[rank];
    const facts = [];
    if (relayed)
        facts.push("Relayed link" + (why ? " (" + why + ")" : ""));
    else if (known)
        facts.push("Direct link");
    if (!isNaN(lat))
        facts.push(Math.round(lat) + " ms");
    if (!isNaN(mbps))
        facts.push((mbps >= 10 ? Math.round(mbps) : Math.round(mbps * 10) / 10) + " Mbit/s");
    const verdictText = level === "good" ? "this looks healthy" : level === "fair" ? "it works but may feel slower than usual" : "this is slow";
    return { level: level, text: facts.join(", ") + ": " + verdictText + "." };
}

// A short, single-line, dash-free copy of an outside text
function _clean(text) {
    return String(text === undefined || text === null ? "" : text)
        .replace(/[\u0000-\u001f\u007f]+/g, " ")
        .replace(/[\u2013\u2014]/g, "-")
        .replace(/[.!?]+/g, " ")
        .replace(/\s+/g, " ")
        .slice(0, 80)
        .trim();
}
