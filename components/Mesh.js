.pragma library

// Turns what the NetBird daemon reports into the small view model the scene
// draws. Pure functions only (no QML), tested with gjs in tests/.
//
// Input: the daemon status word ("Connected", "NeedsLogin", ...) and the
// object printed by `netbird status --json`. Both are optional: a stopped
// daemon gives neither. Live rates come from the difference between two
// reads, so parse() takes the previous view and the time of this read.

// Daemon status words -> the five states the scene knows
const STATES = {
    "Connected": "connected",
    "Connecting": "connecting",
    "Idle": "disconnected",
    "NeedsLogin": "needsLogin",
    "LoginFailed": "needsLogin",
    "SessionExpired": "needsLogin"
};

function stateOf(daemonStatus) {
    if (!daemonStatus)
        return "stopped";
    return STATES[daemonStatus] || "disconnected";
}

// "kestrel.netbird.cloud" -> "kestrel"
function shortName(fqdn) {
    const s = String(fqdn || "");
    const dot = s.indexOf(".");
    return dot > 0 ? s.slice(0, dot) : s;
}

// "100.92.14.3/16" -> "100.92.14.3"
function bareIp(ip) {
    const s = String(ip || "");
    const slash = s.indexOf("/");
    return slash > 0 ? s.slice(0, slash) : s;
}

// NetBird prints Go durations as nanoseconds
function latencyMs(ns) {
    const n = Number(ns);
    return isFinite(n) && n > 0 ? n / 1e6 : 0;
}

// "rels://relay-eu.mesh.example:443" -> "relay-eu"
function relayName(uri) {
    const s = String(uri || "").replace(/^[a-z]+:\/\//, "");
    const host = s.split(/[:/]/)[0];
    return shortName(host) || "relay";
}

// Guess what a peer is from its name, so the scene can pick a creature.
// Only a hint: anything unknown is a desktop.
const KINDS = [
    ["phone", /phone|pixel|iphone|android|galaxy|mobile|tablet|ipad/],
    ["pi", /(^|[-_.])pi($|[-_.\d])|raspberry|rpi/],
    ["nas", /nas|synology|truenas|qnap|storage|backup/],
    ["vps", /vps|cloud|droplet|ec2|hetzner|ovh|linode|vultr|gcp|aws|azure/],
    ["server", /server|srv|proxmox|docker|k8s|nuc|homelab|gw|gateway|router|host|node/],
    ["laptop", /laptop|book|thinkpad|xps|air|latitude|zenbook|notebook/]
];

function kindOf(name) {
    const n = String(name || "").toLowerCase();
    for (let i = 0; i < KINDS.length; i++)
        if (KINDS[i][1].test(n))
            return KINDS[i][0];
    return "desktop";
}

function _time(s) {
    const t = Date.parse(s || "");
    // Go's zero time ("0001-01-01...") means "never"
    return isFinite(t) && t > 0 ? t : 0;
}

function peerOf(d) {
    const online = d.status === "Connected";
    const relayed = String(d.connectionType || "").toLowerCase() === "relayed";
    const name = shortName(d.fqdn) || bareIp(d.netbirdIp);
    return {
        "id": d.publicKey || d.fqdn || d.netbirdIp || "",
        "name": name,
        "fqdn": d.fqdn || "",
        "ip": bareIp(d.netbirdIp),
        "kind": kindOf(name),
        "online": online,
        "relayed": online && relayed,
        "relay": online && relayed ? relayName(d.relayAddress) : "",
        "latencyMs": online ? latencyMs(d.latency) : 0,
        "rx": Number(d.transferReceived) || 0,
        "tx": Number(d.transferSent) || 0,
        "down": 0,
        "up": 0,
        "since": _time(d.statusSince),
        "handshake": _time(d.lastWireguardHandshake)
    };
}

// Online first, then by latency (closest first), then by name, so the order
// (and every layout built from it) is stable from one read to the next
function _order(a, b) {
    if (a.online !== b.online)
        return a.online ? -1 : 1;
    if (a.online && a.latencyMs !== b.latencyMs)
        return a.latencyMs - b.latencyMs;
    return a.name.localeCompare(b.name);
}

// Bits per second from two byte counters. A counter that went backwards
// (the daemon restarted) gives 0, never a negative rate.
function rate(bytesNow, bytesBefore, seconds) {
    if (!(seconds > 0))
        return 0;
    const d = Number(bytesNow) - Number(bytesBefore);
    return d > 0 ? d * 8 / seconds : 0;
}

// Below this a peer is idle, not "the top consumer"
const TOP_MIN_BPS = 50000;
// A WireGuard handshake happens every 2 minutes on a live tunnel
const SILENT_MS = 5 * 60000;

function parse(daemonStatus, json, prev, now) {
    const state = stateOf(daemonStatus);
    const s = json || {};
    now = now || Date.now();
    const list = ((s.peers || {}).details || []).map(peerOf).sort(_order);
    const before = {};
    if (prev && prev.peers && prev.at)
        prev.peers.forEach(p => before[p.id] = p);
    const dt = prev && prev.at ? (now - prev.at) / 1000 : 0;
    let down = 0, up = 0, top = null, online = 0;
    list.forEach(p => {
        const b = before[p.id];
        // rx is what we received from that peer: its download toward us
        if (b && p.online && state === "connected") {
            p.down = rate(p.rx, b.rx, dt);
            p.up = rate(p.tx, b.tx, dt);
        }
        if (p.online) {
            online++;
            down += p.down;
            up += p.up;
            if (p.down + p.up >= TOP_MIN_BPS && (!top || p.down + p.up > top.down + top.up))
                top = p;
        }
    });
    const relays = ((s.relays || {}).details || []).map(r => ({
        "name": relayName(r.uri),
        "available": r.available !== false
    }));
    const view = {
        "state": state,
        "at": now,
        "me": {
            "name": shortName(s.fqdn) || "you",
            "fqdn": s.fqdn || "",
            "ip": bareIp(s.netbirdIp)
        },
        "peers": list,
        "online": online,
        "total": list.length,
        "down": down,
        "up": up,
        "topId": top ? top.id : "",
        "relays": relays,
        "managementUp": !s.management || s.management.connected !== false
    };
    view.omens = state === "connected" ? omensOf(view, now) : [];
    return view;
}

// Warnings the scene raises: things that quietly break a mesh
function omensOf(view, now) {
    const out = [];
    if (!view.managementUp)
        out.push({ "kind": "management", "text": "The management server is unreachable: new peers and changes will wait." });
    view.relays.forEach(r => {
        if (r.available)
            return;
        const users = view.peers.filter(p => p.relay === r.name).map(p => p.name);
        out.push({
            "kind": "relay",
            "relay": r.name,
            "text": r.name + " is not answering" + (users.length ? ": " + users.join(", ") + (users.length > 1 ? " go" : " goes") + " through it." : ".")
        });
    });
    view.peers.forEach(p => {
        if (p.online && p.handshake && now - p.handshake > SILENT_MS)
            out.push({ "kind": "silent", "peer": p.id, "text": p.name + " has been silent for " + Math.round((now - p.handshake) / 60000) + " min." });
    });
    return out;
}

// Traffic -> 0..1 on a log scale, so 50 kb/s and 90 Mb/s both read well
function level(bps) {
    const mbps = Math.max(0, Number(bps) || 0) / 1e6;
    return Math.min(1, Math.log(1 + mbps * 20) / Math.log(2401));
}

// Latency -> depth 0 (surface) .. 1 (deepest), log scale from 1 to 320 ms
function depthOf(ms) {
    const m = Math.max(1, Number(ms) || 1);
    return Math.max(0, Math.min(1, Math.log(m) / Math.log(320)));
}

function fmtRate(bps) {
    const b = Math.max(0, Number(bps) || 0);
    if (b < 1e3)
        return Math.round(b) + " b/s";
    if (b < 1e6)
        return Math.round(b / 1e3) + " kb/s";
    if (b < 1e9)
        return (b / 1e6).toFixed(b < 1e7 ? 1 : 0) + " Mb/s";
    return (b / 1e9).toFixed(1) + " Gb/s";
}

// Compact form for labels: "9.2M", "310k"
function fmtShort(bps) {
    const b = Math.max(0, Number(bps) || 0);
    if (b < 1e6)
        return Math.round(b / 1e3) + "k";
    if (b < 1e9)
        return (b / 1e6).toFixed(b < 1e7 ? 1 : 0) + "M";
    return (b / 1e9).toFixed(1) + "G";
}

function fmtBytes(n) {
    const b = Math.max(0, Number(n) || 0);
    const units = ["B", "kB", "MB", "GB", "TB"];
    let i = 0, v = b;
    while (v >= 1000 && i < units.length - 1) {
        v /= 1000;
        i++;
    }
    return (i === 0 ? Math.round(v) : v.toFixed(v < 10 ? 1 : 0)) + " " + units[i];
}

function fmtAgo(ms) {
    const s = Math.max(0, Math.round(ms / 1000));
    if (s < 60)
        return s + " s";
    const m = Math.round(s / 60);
    if (m < 60)
        return m + " min";
    const h = Math.floor(m / 60);
    if (h < 48)
        return h + " h " + String(m % 60).padStart(2, "0");
    return Math.floor(h / 24) + " days";
}
