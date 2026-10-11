.pragma library

// Tags on peers: automatic ones worked out from what a peer is (its kind,
// its networks, the user's group), manual ones the user typed. Pure functions
// only, tested with gjs in tests/. Manual tags live in Abyss settings only:
// { peerId: ["nas", "backup"] }.

const MAX_PER_PEER = 8;
const MAX_PEERS = 200;
const MAX_LENGTH = 24;

// One tag: lower case letters, digits, "-" and "_" only, so it can be typed
// after "#" without quoting. Returns "" when nothing usable is left.
function clean(s) {
    return String(s === undefined || s === null ? "" : s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/^#/, "").replace(/[^a-z0-9_-]+/g, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "").slice(0, MAX_LENGTH);
}

// A list of tags: cleaned, without doubles, capped
function cleanList(list) {
    const out = [];
    (Array.isArray(list) ? list : []).forEach(t => {
        const c = clean(t);
        if (c && out.indexOf(c) < 0 && out.length < MAX_PER_PEER)
            out.push(c);
    });
    return out;
}

// A whole manual map: bad entries dropped, caps applied
function cleanMap(map) {
    const out = {};
    if (!map || typeof map !== "object" || Array.isArray(map))
        return out;
    Object.keys(map).slice(0, MAX_PEERS).forEach(id => {
        const list = cleanList(map[id]);
        if (list.length)
            out[id] = list;
    });
    return out;
}

// The map with a peer's tags replaced (a new map; an empty list removes it)
function setManual(map, peerId, list) {
    const next = cleanMap(map);
    const tags = cleanList(list);
    if (tags.length && (next[peerId] || Object.keys(next).length < MAX_PEERS))
        next[peerId] = tags;
    else
        delete next[peerId];
    return next;
}

// What a peer is, without anything typed: its kind, "exit" when it can lend
// Internet, "subnet" when it carries a network, and its group's name
// (a group called "Home" or "Work" gives #home or #work).
function auto(peer, groups) {
    const out = [];
    if (peer.kind)
        out.push(clean(peer.kind));
    if (peer.exit)
        out.push("exit");
    if ((peer.networks || []).some(n => n !== "0.0.0.0/0" && n !== "::/0"))
        out.push("subnet");
    const g = (groups || []).find(x => (x.members || []).indexOf(peer.id) >= 0);
    if (g && clean(g.name))
        out.push(clean(g.name));
    return out.filter((t, i) => t && out.indexOf(t) === i);
}

// Every tag of a peer: automatic first, then manual ones not already there
function of(peer, groups, manual) {
    const out = auto(peer, groups);
    cleanList((manual || {})[peer.id]).forEach(t => {
        if (out.indexOf(t) < 0)
            out.push(t);
    });
    return out;
}
