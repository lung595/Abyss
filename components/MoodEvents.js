.pragma library

// Turns what really happens on the mesh into Darwin's mood events (Mood.js
// kinds). Pure: no clock, no timer; the caller passes the time in seconds.
// Every kind has a minimum gap, and one data change yields at most one event
// per kind, so thirty devices dropping at once scare him once, not thirty
// times. "Nothing moving for a while" needs no mapping: Mood.step counts idle
// time itself and every event resets it. Not wired yet (NAK-239).
// Tested with gjs in tests/moodEvents.test.js.

// Shortest time between two events of the same kind (seconds)
const GAP = { "deviceDown": 1.5, "join": 1.5, "relay": 0.6, "file": 0.5, "success": 0.5, "click": 0.2, "rush": 0.3 };

function create() {
    // known: device id -> online, null until the first list is seen (no
    // event for devices that were already there); last: kind -> time. Both
    // have no prototype, so an id like "__proto__" is just an id
    return { "known": null, "last": Object.create(null) };
}

// The event for kind at time now, or null while that kind is still cooling down
function _gate(st, kind, now, x, y) {
    const last = st.last[kind];
    // A negative gap (the wall clock stepped back) counts as expired, so the
    // cooldown cannot freeze until the clock catches up
    if (last !== undefined && now >= last && now - last < GAP[kind])
        return null;
    st.last[kind] = now;
    return { "kind": kind, "x": x, "y": y };
}

// peers: [{ id, online }]. A device going offline is a deviceDown, a new
// online one a join; the first list only seeds what is known. A device missing
// from a list keeps its last known state, so an empty or partial list followed
// by the full one (a daemon restarting) does not make everything rejoin.
function devices(st, peers, now) {
    // An empty list before any device was seen carries nothing to seed with
    // (the mesh is still loading): the first real list must stay silent
    if (!Array.isArray(peers) || (!st.known && peers.length === 0))
        return [];
    const next = Object.create(null);
    if (st.known)
        Object.assign(next, st.known);
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

// The pointer dashes at him
function rush(st, now, x, y) {
    return _gate(st, "rush", now, x, y);
}
