.pragma library

// Turns what really happens on the mesh into Darwin's mood events (Mood.js
// kinds). Pure: no clock, no timer; the caller passes the time in seconds.
// Every kind has a minimum gap, and one data change yields at most one event
// per kind, so thirty devices dropping at once scare him once, not thirty
// times. "Nothing moving for a while" needs no mapping: Mood.step counts idle
// time itself and every event resets it. Not wired yet (NAK-239).
// Tested with gjs in tests/moodEvents.test.js.

// Shortest time between two events of the same kind (seconds)
const GAP = { "deviceDown": 1.5, "join": 1.5, "relay": 0.6, "file": 0.5, "success": 0.5, "click": 0.2 };

function create() {
    // known: device id -> online, null until the first list is seen (no
    // event for devices that were already there); last: kind -> time
    return { "known": null, "last": {} };
}

// The event for kind at time now, or null while that kind is still cooling down
function _gate(st, kind, now, x, y) {
    const last = st.last[kind];
    if (last !== undefined && now - last < GAP[kind])
        return null;
    st.last[kind] = now;
    return { "kind": kind, "x": x, "y": y };
}

// peers: [{ id, online }]. A device going offline is a deviceDown, a new
// online one a join; the first list only seeds what is known.
function devices(st, peers, now) {
    const out = [];
    if (!Array.isArray(peers))
        return out;
    const next = {};
    let down = false, joined = false;
    for (let i = 0; i < peers.length; i++) {
        const p = peers[i];
        if (!p || p.id === undefined)
            continue;
        const on = !!p.online;
        next[p.id] = on;
        if (!st.known)
            continue;
        const was = st.known[p.id];
        if (was === true && !on)
            down = true;
        else if (on && was === undefined)
            joined = true;
    }
    st.known = next;
    const ev = [];
    if (down)
        ev.push(_gate(st, "deviceDown", now));
    if (joined)
        ev.push(_gate(st, "join", now));
    return ev.filter(e => e);
}

// A relay blinked (x, y: where, if known)
function relay(st, now, x, y) {
    return _gate(st, "relay", now, x, y);
}

// phase: "started" (a file passes), "succeeded", "failed". A failure startles
// him like a device going away; any other phase is ignored.
function send(st, phase, now, x, y) {
    const kind = phase === "started" ? "file" : phase === "succeeded" ? "success" : phase === "failed" ? "deviceDown" : "";
    return kind ? _gate(st, kind, now, x, y) : null;
}

function click(st, now, x, y) {
    return _gate(st, "click", now, x, y);
}
