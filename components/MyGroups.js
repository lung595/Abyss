.pragma library

// Groups the user makes (right-click a creature: "New group", "Add to…"),
// as opposed to the automatic ones of Groups.js. They are saved in the
// plugin's settings as a list of { id, name, members: [peer ids] }; a peer
// belongs to one of them at most. Pure functions: every change returns a new
// list, so the settings can be written as they are.

// The next free name: "Group 1", "Group 2"…
function nextName(groups) {
    let n = 1;
    while (groups.some(g => g.name === "Group " + n))
        n++;
    return "Group " + n;
}

function _nextId(groups) {
    let n = 1;
    while (groups.some(g => g.id === "u" + n))
        n++;
    return "u" + n;
}

// The group a peer is in, or null
function groupOf(groups, peerId) {
    return groups.find(g => g.members.indexOf(peerId) >= 0) || null;
}

function byId(groups, id) {
    return groups.find(g => g.id === id) || null;
}

// Every list without these peers (a peer never sits in two groups)
function _without(groups, peerIds) {
    return groups.map(g => Object.assign({}, g, {
        "members": g.members.filter(m => peerIds.indexOf(m) < 0)
    }));
}

// A new group with these peers; returns { groups, id }
function create(groups, peerIds, name) {
    const id = _nextId(groups);
    const next = _without(groups, peerIds).filter(g => g.members.length > 0);
    next.push({
        "id": id,
        "name": name || nextName(groups),
        "members": peerIds.slice()
    });
    return {
        "groups": next,
        "id": id
    };
}

// Moves a peer into a group (out of any other one)
function join(groups, id, peerId) {
    return _without(groups, [peerId]).map(g => g.id !== id ? g : Object.assign({}, g, {
        "members": g.members.concat([peerId])
    })).filter(g => g.members.length > 0);
}

// Takes a peer out of its group; a group left empty disappears
function leave(groups, peerId) {
    return _without(groups, [peerId]).filter(g => g.members.length > 0);
}

// A blank name keeps the old one
function rename(groups, id, name) {
    const clean = String(name || "").trim().slice(0, 32);
    return groups.map(g => g.id !== id || !clean ? g : Object.assign({}, g, {
        "name": clean
    }));
}

function remove(groups, id) {
    return groups.filter(g => g.id !== id);
}

// Latency for choosing: the steady value, so jitter never flips the choice
function _ms(p) {
    return p.steadyMs !== undefined ? p.steadyMs : p.latencyMs;
}

// Internet through a whole group: NetBird sends it through one exit node at
// a time, so the group lends its best member — the current one while it is
// still online (no flapping), else a direct one before a relayed one, then
// the quickest. Returns the peer, or null when nobody in it is online.
function pickExit(peers, memberIds, currentName) {
    const live = peers.filter(p => p.online && p.exit && memberIds.indexOf(p.id) >= 0);
    const cur = live.find(p => p.name === currentName);
    if (cur)
        return cur;
    live.sort((a, b) => (a.relayed - b.relayed) || (_ms(a) - _ms(b)));
    return live[0] || null;
}
