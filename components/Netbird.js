.pragma library

// What the NetBird source says to the `netbird` CLI, and how it reads the
// answers. Pure functions only (no QML, no process), tested with gjs in
// tests/; NetbirdSource.qml runs the commands.
//
// Read from the NetBird client's own code (client/cmd/status.go,
// networks.go, profile.go):
// - `netbird status --json` prints JSON in every daemon state, with the
//   state itself as "daemonStatus"; older clients print "Daemon status: X"
//   as text instead when a sign-in is needed. With no daemon running it
//   fails ("failed to connect to daemon").
// - `netbird networks list` has no JSON: blocks of "- ID:", "Network:" or
//   "Domains:", and "Status: Selected | Not Selected".
// - A peer's "networks" in the status only lists the routes that go through
//   it right now. So a peer that could lend Internet (an exit node) cannot
//   be told from the status alone: see exitMap.

// --- Commands --------------------------------------------------------------
// Each is an argv for a Process: never a shell line, so nothing in a name
// can run anything

const BIN = "netbird";
// `netbird up` may wait for the user to sign in in the browser, or for a
// slow management server: five minutes before it is given up on
const SIGN_IN_TIMEOUT = 300000;

function statusCmd() {
    return [BIN, "status", "--json"];
}
function networksCmd() {
    return [BIN, "networks", "list"];
}
function profilesCmd() {
    return [BIN, "profile", "list"];
}
function upCmd() {
    return [BIN, "up"];
}
// The same, for a sign-in: the user has time to finish it in the browser
function signInCmd() {
    return {
        "argv": upCmd(),
        "timeout": SIGN_IN_TIMEOUT
    };
}
function downCmd() {
    return [BIN, "down"];
}

// Joins this device to a mesh with a setup key (from the NetBird dashboard:
// Setup Keys), on NetBird Cloud or on a self-hosted management server.
// null for a key or an address that is not well formed. A key never starts
// with "-" (it would read as an option) and the address must be http(s)
// A self-hosted management server: https only, since the setup key travels
// to it (P109). No spaces, nothing before the host
function validServer(url) {
    return /^https:\/\/[^\s\/@][^\s@]*$/.test(url);
}
function joinCmd(key, url, hostname) {
    const k = String(key || "").trim(), u = String(url || "").trim(), h = String(hostname || "").trim();
    if (!/^[A-Za-z0-9][A-Za-z0-9_.=-]{7,}$/.test(k))
        return null;
    if (u && !validServer(u))
        return null;
    if (h && !/^[A-Za-z0-9][A-Za-z0-9-]{0,62}$/.test(h))
        return null;
    // The key goes in NB_SETUP_KEY (netbird reads every flag from NB_*),
    // never on the command line, which any local user can read in ps
    return {
        "argv": [BIN, "up"].concat(u ? ["--management-url", u] : [], h ? ["--hostname", h] : []),
        "env": {
            "NB_SETUP_KEY": k
        },
        "timeout": SIGN_IN_TIMEOUT
    };
}
// The same with the key read from a file by netbird itself: what the
// command line (`dms ipc call abyss join`) takes, so the key never lands in
// the shell history. null unless the path is absolute
function joinFileCmd(path, url, hostname) {
    const f = String(path || "").trim(), u = String(url || "").trim(), h = String(hostname || "").trim();
    if (!/^\/[^\0\n]+$/.test(f))
        return null;
    if (u && !validServer(u))
        return null;
    if (h && !/^[A-Za-z0-9][A-Za-z0-9-]{0,62}$/.test(h))
        return null;
    return {
        "argv": [BIN, "up", "--setup-key-file", f].concat(u ? ["--management-url", u] : [], h ? ["--hostname", h] : []),
        "timeout": SIGN_IN_TIMEOUT
    };
}
// Signs this device out of the mesh (it stays listed, offline)
function logoutCmd() {
    return [BIN, "logout"];
}
// Lets the other peers open an SSH session on this device (NetBird's own
// SSH server) or stops letting them
function shareSshCmd(on) {
    return [BIN, "up", "--allow-server-ssh=" + (on ? "true" : "false")];
}
function selectProfileCmd(name) {
    return [BIN, "profile", "select", String(name)];
}
// The service runs as root: polkit asks for the password
function startServiceCmd() {
    return ["pkexec", BIN, "service", "start"];
}
// Network ids are the admin's words: "--" keeps one starting with "-"
// from being read as an option
function selectNetworksCmd(ids, append) {
    return [BIN, "networks", "select"].concat(append ? ["-a"] : [], ["--"], ids);
}
function deselectNetworksCmd(ids) {
    return [BIN, "networks", "deselect", "--"].concat(ids);
}

// --- Reading the answers ---------------------------------------------------

// The output of `netbird status --json` and its exit code ->
// { daemonStatus, json, error }. daemonStatus is "" when no daemon answers
// (Mesh.stateOf reads that as "stopped")
function readStatus(out, code) {
    const text = String(out || "").trim();
    if (text.charAt(0) === "{") {
        try {
            const json = JSON.parse(text);
            return {
                "daemonStatus": String(json.daemonStatus || "Connected"),
                "json": json,
                "error": ""
            };
        } catch (e) {
            return { "daemonStatus": "", "json": null, "error": "NetBird's status could not be read: " + e.message };
        }
    }
    const m = text.match(/Daemon status:\s*(\w+)/);
    if (m)
        return { "daemonStatus": m[1], "json": null, "error": "" };
    if (code === 0 && !text)
        return { "daemonStatus": "", "json": null, "error": "NetBird printed nothing" };
    return { "daemonStatus": "", "json": null, "error": firstLine(text) || "NetBird is not answering" };
}

// The first meaningful line of an error, to show in a note
function firstLine(text) {
    return String(text || "").split("\n").map(s => s.trim()).filter(s => s)[0] || "";
}

// `netbird networks list` -> [{ id, range, domains: [], selected }]
function readNetworks(out) {
    const list = [];
    let cur = null;
    String(out || "").split("\n").forEach(line => {
        let m = line.match(/^\s*-\s*ID:\s*(.+?)\s*$/);
        if (m) {
            cur = { "id": m[1], "range": "", "domains": [], "selected": false };
            list.push(cur);
            return;
        }
        if (!cur)
            return;
        if ((m = line.match(/^\s*Network:\s*(.+?)\s*$/)))
            cur.range = m[1];
        else if ((m = line.match(/^\s*Domains:\s*(.+?)\s*$/)))
            cur.domains = m[1].split(",").map(s => s.trim()).filter(s => s);
        else if ((m = line.match(/^\s*Status:\s*(.+?)\s*$/)))
            cur.selected = m[1] === "Selected";
    });
    return list;
}

// `netbird profile list` (a NAME / ACTIVE table, ✓ on the active one) ->
// { names: [], active }
function readProfiles(out) {
    const names = [];
    let active = "";
    String(out || "").split("\n").slice(1).forEach(line => {
        const l = line.replace(/\s+$/, "");
        if (!l.trim())
            return;
        const on = /\s✓$/.test(l);
        const name = (on ? l.replace(/\s+✓$/, "") : l).trim();
        if (!name)
            return;
        names.push(name);
        if (on)
            active = name;
    });
    return { "names": names, "active": active };
}

// --- Exit nodes ------------------------------------------------------------

function isExitRange(range) {
    return range === "0.0.0.0/0" || range === "::/0";
}

function exitRoutes(networks) {
    return (networks || []).filter(n => isExitRange(n.range));
}

// Which exit route goes out through which peer: { routeId: peerId }.
// `learned` keeps what was seen before: while only one exit route is
// selected, the peer that carries 0.0.0.0/0 is its peer. Otherwise a route
// named after a peer ("exit-atlas", "atlas-server") is taken as that
// peer's, the longest name winning. Routes no peer can be found for stay
// out (NetBird's CLI does not say which peer serves a route).
function exitMap(networks, peers, learned) {
    const routes = exitRoutes(networks), map = {};
    const ids = routes.map(r => r.id);
    Object.keys(learned || {}).forEach(id => {
        if (ids.indexOf(id) >= 0 && peers.some(p => p.id === learned[id]))
            map[id] = learned[id];
    });
    // Seen just now: one selected exit route, one peer carrying it
    const sel = routes.filter(r => r.selected), carrying = peers.filter(p => p.lending);
    if (sel.length === 1 && carrying.length === 1)
        map[sel[0].id] = carrying[0].id;
    routes.forEach(r => {
        if (!map[r.id]) {
            const p = _namedAfter(r.id, peers);
            if (p)
                map[r.id] = p.id;
        }
    });
    return map;
}

// Words of a route id that say nothing about the peer
const GENERIC = ["exit", "node", "internet", "default", "route", "out", "via", "gw", "v4", "v6", "ipv4", "ipv6", "all", "the"];

function _words(s) {
    return String(s || "").toLowerCase().split(/[^a-z0-9]+/).filter(w => w && GENERIC.indexOf(w) < 0);
}

// The peer a route is named after: its whole name inside the id (the
// longest such name wins), else the one peer sharing a word with it
// ("exit-harbor" for harbor-vps). Two peers sharing that word: nobody
function _namedAfter(routeId, peers) {
    const rid = routeId.toLowerCase();
    const whole = peers.filter(p => p.name.length >= 3 && rid.indexOf(p.name.toLowerCase()) >= 0).sort((a, b) => b.name.length - a.name.length);
    if (whole.length)
        return whole[0];
    const words = _words(routeId).filter(w => w.length >= 3);
    const some = peers.filter(p => _words(p.name).some(w => words.indexOf(w) >= 0));
    return some.length === 1 ? some[0] : null;
}

// The route ids that go out through a peer (an exit node pair often has a
// v4 and a v6 route)
function routesOf(map, peerId) {
    return Object.keys(map).filter(id => map[id] === peerId);
}

// Internet through the peer with this id ("" to go out directly): the
// commands to run, in order. Other selected exit routes are deselected
// first, so NetBird never has two to choose from.
// Returns { cmds, error }
function exitCommands(networks, map, peerId) {
    const routes = exitRoutes(networks);
    const want = peerId ? routesOf(map, peerId) : [];
    if (peerId && !want.length)
        return { "cmds": [], "error": "NetBird does not say which exit route goes through this peer. Name the route after the peer in NetBird's dashboard (Network Routes)." };
    const drop = routes.filter(r => r.selected && want.indexOf(r.id) < 0).map(r => r.id);
    const cmds = [];
    if (drop.length)
        cmds.push(deselectNetworksCmd(drop));
    if (want.length)
        cmds.push(selectNetworksCmd(want, true));
    return { "cmds": cmds, "error": "" };
}

// The exit routes no peer is known for yet: [{ id, selected }]. The light's
// menu lists them by name; once one is used, the peer seen carrying it is
// learned (and kept in the settings)
function looseRoutes(networks, map) {
    return exitRoutes(networks).filter(r => !map[r.id]).map(r => ({ "id": r.id, "selected": r.selected }));
}

// Internet through one exit route, by its id: the other selected exit
// routes are deselected first. Returns { cmds, error }
function routeCommands(networks, routeId) {
    const routes = exitRoutes(networks);
    if (!routes.some(r => r.id === routeId))
        return { "cmds": [], "error": "No exit route named " + routeId };
    const drop = routes.filter(r => r.selected && r.id !== routeId).map(r => r.id);
    const cmds = drop.length ? [deselectNetworksCmd(drop)] : [];
    cmds.push(selectNetworksCmd([routeId], true));
    return { "cmds": cmds, "error": "" };
}

// --- The view the scene draws ----------------------------------------------

// The caves on the floor: every network but the exit ones (the light at the
// surface is the Internet), as the scene knows them: { id, cidr, via, on }.
// `via` is the peer the route goes through right now, if any
function caves(networks, peers) {
    return (networks || []).filter(n => !isExitRange(n.range)).map(n => {
        const cidr = n.range || n.domains.join(", ");
        const p = (peers || []).find(q => (q.networks || []).indexOf(n.range) >= 0 || n.domains.some(d => (q.networks || []).indexOf(d) >= 0));
        return { "id": n.id, "cidr": cidr, "via": p ? p.name : "", "on": n.selected };
    });
}

// Marks the peers that can lend Internet (exit) and returns the one that
// lends it now ("" for none), so the scene and the light know both
function markExits(peers, map) {
    const lenders = {};
    Object.keys(map).forEach(id => lenders[map[id]] = true);
    let now = "";
    peers.forEach(p => {
        p.exit = !!p.exit || !!lenders[p.id];
        if (p.lending && p.online)
            now = p.name;
    });
    return now;
}
