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
// [kind, words that may sit anywhere in the name, words that must be a
// whole word of it]. Short words only count whole ("air" in "chair", "nas"
// in "banana" or "host" in "ghost" said nothing about the device)
const KINDS = [
    ["phone", ["phone", "pixel", "android", "galaxy", "mobile", "tablet", "ipad"], []],
    ["pi", ["raspberry"], ["pi", "rpi"]],
    ["nas", ["synology", "truenas", "qnap", "storage", "backup"], ["nas"]],
    ["vps", ["vps", "droplet", "hetzner", "linode", "vultr", "azure"], ["cloud", "ec2", "ovh", "gcp", "aws"]],
    ["server", ["server", "proxmox", "docker", "homelab", "gateway", "router"], ["srv", "k8s", "nuc", "gw", "host", "node", "pve"]],
    ["laptop", ["laptop", "macbook", "chromebook", "thinkpad", "zenbook", "notebook", "latitude", "ideapad"], ["book", "xps", "air"]]
];

// "rpi4-garden_01" -> ["rpi4", "garden", "01", "rpi"]: every word, and each
// one without its trailing number
function _words(n) {
    const w = n.split(/[^a-z0-9]+/).filter(s => s);
    return w.concat(w.map(s => s.replace(/\d+$/, "")).filter(s => s));
}

function kindOf(name) {
    const n = String(name || "").toLowerCase();
    const words = _words(n);
    for (let i = 0; i < KINDS.length; i++)
        if (KINDS[i][1].some(k => n.indexOf(k) >= 0) || KINDS[i][2].some(k => words.indexOf(k) >= 0))
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
    const nets = (d.networks || d.routes || []).slice();
    const exit = nets.some(n => n === "0.0.0.0/0" || n === "::/0");
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
        "calm": 0,
        // What goes through it right now ("networks" on newer clients,
        // "routes" on older ones)
        "networks": nets,
        // The whole Internet goes through it now (a 0.0.0.0/0 route: an exit
        // node). `exit` (it can lend Internet) starts the same; the NetBird
        // source widens it to every peer with an exit route (Netbird.js)
        "lending": online && exit,
        "exit": exit,
        "since": _time(d.lastStatusUpdate),
        "handshake": _time(d.lastWireguardHandshake)
    };
}

// Names are what the scene, the exit node and commands go by, so two peers
// never share one: "pc" and "pc" become "pc.home" and "pc.work" (as many
// labels of their fqdn as it takes), or their full fqdn / address
function _unique(list) {
    const count = {};
    list.forEach(p => count[p.name] = (count[p.name] || 0) + 1);
    const clash = list.filter(p => count[p.name] > 1);
    if (!clash.length)
        return list;
    const taken = {};
    list.forEach(p => {
        if (count[p.name] === 1)
            taken[p.name] = true;
    });
    clash.forEach(p => {
        const labels = p.fqdn ? p.fqdn.split(".") : [];
        let name = "";
        for (let n = 2; n <= labels.length && !name; n++) {
            const c = labels.slice(0, n).join(".");
            if (!taken[c] && clash.filter(q => q.fqdn.split(".").slice(0, n).join(".") === c).length === 1)
                name = c;
        }
        if (!name)
            name = !taken[p.ip] && p.ip ? p.ip : p.name + "~" + p.id.slice(0, 6);
        p.name = name;
        taken[name] = true;
    });
    return list;
}

// Online first, then by steady latency (closest first), then by name, so the
// order (and every layout built from it) is stable from one read to the next
function _order(a, b) {
    if (a.online !== b.online)
        return a.online ? -1 : 1;
    if (a.online && a.steadyMs !== b.steadyMs)
        return a.steadyMs - b.steadyMs;
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

// Shown rates ease toward each new measure in about a second, so a burst
// reads as a steady figure. What arranges the deep (calm traffic, steady
// latency) follows over ~20 s, so nothing swaps places on a blip.
const EASE_S = 1.2;
const CALM_S = 20;
// A read this close to the last one, or after a pause this long (the view
// was closed), measures nothing: the last figures are kept
const MIN_GAP_S = 0.5;
const MAX_GAP_S = 5;
// The steady latency only follows its average past this (log) ratio, ~20 %
const STEADY_BAND = 0.18;

// Fills a peer's figures from its previous read b, dt seconds earlier:
// down/up (eased rates), calm (slow average of both, for the arrangement),
// msAvg and steadyMs (latency averaged, and the value the layout uses)
function follow(p, b, dt, live) {
    if (p.online && b && b.online && b.msAvg > 0 && p.latencyMs > 0) {
        const k = 1 - Math.exp(-Math.min(Math.max(dt, 0), MAX_GAP_S) / CALM_S);
        p.msAvg = Math.exp(Math.log(b.msAvg) + (Math.log(p.latencyMs) - Math.log(b.msAvg)) * k);
        p.steadyMs = Math.abs(Math.log(p.msAvg / b.steadyMs)) < STEADY_BAND ? b.steadyMs : Math.round(p.msAvg * 10) / 10;
    } else {
        p.msAvg = p.latencyMs;
        p.steadyMs = p.latencyMs;
    }
    if (!live || !p.online || !b)
        return;
    if (!(dt >= MIN_GAP_S && dt <= MAX_GAP_S)) {
        p.down = b.down;
        p.up = b.up;
        p.calm = b.calm;
        p.measured = b.measured;
        return;
    }
    const down = rate(p.rx, b.rx, dt), up = rate(p.tx, b.tx, dt);
    if (!b.measured) {
        p.down = down;
        p.up = up;
        p.calm = down + up;
    } else {
        const e = 1 - Math.exp(-dt / EASE_S), c = 1 - Math.exp(-dt / CALM_S);
        p.down = b.down + (down - b.down) * e;
        p.up = b.up + (up - b.up) * e;
        p.calm = b.calm + (down + up - b.calm) * c;
    }
    p.measured = true;
}

// Below this a peer is idle, not "the top consumer"
const TOP_MIN_BPS = 50000;
// The crown only changes hands when a rival clearly outpaces the holder,
// otherwise two peers with close traffic swap it every read (the label
// flickered between the tint and the plain look)
const TOP_KEEP = 1.3;
// A WireGuard handshake happens every 2 minutes on a live tunnel
const SILENT_MS = 5 * 60000;

// The admin console of a mesh, from its management server's address: the
// cloud's own dashboard for NetBird Cloud, else the same host (where a
// self-hosted dashboard usually sits). "" when the address says nothing
function consoleUrl(managementUrl) {
    const m = String(managementUrl || "").match(/^(https?):\/\/([^\/:?#]+)/i);
    if (!m)
        return "";
    const host = m[2].toLowerCase();
    if (host === "api.netbird.io")
        return "https://app.netbird.io";
    if (/^(localhost|[0-9.]+|\[.*\])$/.test(host) || host.indexOf(".") < 0)
        return "";
    return m[1].toLowerCase() + "://" + host;
}

function parse(daemonStatus, json, prev, now) {
    const state = stateOf(daemonStatus);
    const s = json || {};
    now = now || Date.now();
    const list = _unique(((s.peers || {}).details || []).map(peerOf));
    const before = {};
    if (prev && prev.peers && prev.at)
        prev.peers.forEach(p => before[p.id] = p);
    const dt = prev && prev.at ? (now - prev.at) / 1000 : 0;
    // rx is what we received from a peer: its download toward us
    list.forEach(p => follow(p, before[p.id], dt, state === "connected"));
    // NetBird's lazy connections keep idle peers unconnected until used: an
    // idle peer may then be reachable (it wakes on use) or really off, and
    // NetBird does not say which. Such peers doze in the water, not asleep
    const lazy = !!s.lazyConnectionEnabled;
    list.forEach(p => p.dozing = lazy && !p.online);
    list.sort(_order);
    let down = 0, up = 0, top = null, online = 0;
    list.forEach(p => {
        if (p.online) {
            online++;
            down += p.down;
            up += p.up;
            if (p.down + p.up >= TOP_MIN_BPS && (!top || p.down + p.up > top.down + top.up))
                top = p;
        }
    });
    const held = prev && prev.topId ? list.find(p => p.id === prev.topId) : null;
    if (top && held && held !== top && held.online && held.down + held.up >= TOP_MIN_BPS
            && top.down + top.up < (held.down + held.up) * TOP_KEEP)
        top = held;
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
            "ip": bareIp(s.netbirdIp),
            // The client's own version, and where the admin console is
            "version": String(s.daemonVersion || ""),
            "console": consoleUrl((s.management || {}).url)
        },
        "peers": list,
        "online": online,
        "total": list.length,
        "down": down,
        "up": up,
        "topId": top ? top.id : "",
        "relays": relays,
        "lazy": lazy,
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
