.pragma library

// Favourite alerts (a favourite goes down, comes back), as a pure state
// machine tested with gjs in tests/. Nothing here reads a clock, a file or
// the network: the caller passes the time and the peers of each NetBird
// refresh, and gets back the new state and the events to notify.
//
// A snapshot is { now, peers: [{ id, favourite, connected }] } with now in
// milliseconds. The state is a plain object to hand back on the next call
// (start with {}). Only favourites are tracked, so nothing about the other
// devices is kept.

// How long a favourite must stay down before it is worth a notification;
// a Wi-Fi blink or a daemon restart should stay silent (Q97)
const DEBOUNCE_MS = 30000;

// opts: { enabled (default true), debounceMs (default DEBOUNCE_MS) }.
// Returns { state, events }; an event is { kind: "down" | "back", id,
// since, duration } where since is when the outage was first seen and
// duration is 0 for "down" and the outage length in ms for "back".
function step(state, snapshot, opts) {
    const o = opts || {};
    // Switched off: forget everything, so that switching on again does not
    // announce an outage that happened while alerts were off
    if (o.enabled === false)
        return { "state": {}, "events": [] };
    const wait = _ms(o.debounceMs, DEBOUNCE_MS);
    const snap = snapshot || {};
    const now = Number(snap.now);
    const prev = state || {};
    const next = {}, events = [];
    if (!isFinite(now) || !Array.isArray(snap.peers))
        // No usable information (failed refresh): change nothing, say nothing
        return { "state": prev, "events": events };
    snap.peers.forEach(p => {
        if (!p || typeof p.id !== "string" || p.id === "" || p.favourite !== true || typeof p.connected !== "boolean")
            // Not a favourite (any more) or unknown link state: no tracking, no event
            return;
        const old = prev[p.id];
        if (p.connected) {
            if (old && old.notified)
                events.push({ "kind": "back", "id": p.id, "since": old.since, "duration": Math.max(0, now - old.since) });
            return;
        }
        // First sight of the outage starts the clock; a device already down
        // when Abyss starts is counted from then, as its real start is unknown
        const cur = old ? { "since": old.since, "notified": old.notified } : { "since": now, "notified": false };
        if (!cur.notified && now - cur.since >= wait) {
            cur.notified = true;
            events.push({ "kind": "down", "id": p.id, "since": cur.since, "duration": 0 });
        }
        next[p.id] = cur;
    });
    return { "state": next, "events": events };
}

function _ms(v, fallback) {
    const n = Number(v);
    return v !== undefined && v !== null && isFinite(n) && n >= 0 ? n : fallback;
}

// "45 s", "3 min", "2 h 5 min", "1 d 4 h" from a length in milliseconds
// (rounded down; anything unusable reads "0 s")
function formatDuration(ms) {
    const n = Number(ms);
    const s = isFinite(n) && n > 0 ? Math.floor(n / 1000) : 0;
    if (s < 60)
        return s + " s";
    const m = Math.floor(s / 60);
    if (m < 60)
        return m + " min";
    const h = Math.floor(m / 60);
    if (h < 24)
        return h + " h" + (m % 60 ? " " + (m % 60) + " min" : "");
    const d = Math.floor(h / 24);
    return d + " d" + (h % 24 ? " " + (h % 24) + " h" : "");
}

// The notification sentence for an event; name is the device's name, kept
// out of every log by the caller
function message(event, name) {
    const who = String(name === undefined || name === null || name === "" ? "A favourite" : name);
    if (!event)
        return "";
    if (event.kind === "down")
        return who + " is offline.";
    if (event.kind === "back")
        return who + " is back after " + formatDuration(event.duration) + ".";
    return "";
}
