.pragma library

// Made-up meshes shaped exactly like `netbird status --json`, so the whole
// interface can be tried (and screenshotted) without NetBird installed.
// Every name, key and address below is fictional.

const EU = "rels://relay-eu.mesh.example:443";
const US = "rels://relay-us.mesh.example:443";

// name, address, latency (ms, 0 = offline), relay uri ("" = direct),
// usual traffic (Mb/s), minutes online
const PROFILES = {
    "home": {
        "fqdn": "wren.mesh.example", "ip": "100.92.0.1/16",
        "peers": [
            ["atlas-server", "100.92.14.3", 4, "", 3.4, 1500],
            ["nook-nas", "100.92.18.40", 6, "", 1.3, 4200],
            ["kestrel-phone", "100.92.7.61", 9, "", 0.08, 190],
            ["juniper-laptop", "100.92.40.18", 12, "", 0.4, 64],
            ["lark-phone", "100.92.9.77", 0, "", 0.05, 0],
            ["studio", "100.92.22.9", 22, "", 0.9, 12],
            ["pi-garden", "100.92.51.2", 41, EU, 0.3, 32],
            ["harbor-vps", "100.92.63.30", 118, EU, 2.1, 4300],
            ["finch-nas", "100.92.33.5", 0, US, 0.5, 0],
            ["tern-vps", "100.92.70.11", 165, US, 0.7, 800]
        ],
        "networks": [
            { "id": "home-lan", "cidr": "192.168.1.0/24", "via": "nook-nas", "on": true },
            { "id": "lab", "cidr": "10.20.0.0/16", "via": "pi-garden", "on": false }
        ]
    },
    "work": {
        "fqdn": "wren.corp.example", "ip": "100.71.0.4/16",
        "peers": [
            ["forge-server", "100.71.2.10", 3, "", 2.8, 9000],
            ["ledger-nas", "100.71.2.44", 7, "", 1, 9000],
            ["desk-12", "100.71.5.12", 15, "", 0.6, 300],
            ["ci-runner-vps", "100.71.9.3", 55, EU, 2, 2000],
            ["gateway-vps", "100.71.9.8", 90, EU, 0.4, 2000]
        ],
        "networks": [
            { "id": "office", "cidr": "10.0.0.0/16", "via": "forge-server", "on": true }
        ]
    }
};

// A crowded made-up mesh (30 peers), to try the groups, the lens and the
// search. Built from word lists so every name stays fictional.
function _crowd() {
    const birds = ["heron", "egret", "plover", "swift", "gannet", "puffin", "ibis", "osprey", "curlew", "dunlin", "merlin", "shrike", "robin", "wagtail", "linnet"];
    const kinds = ["server", "phone", "laptop", "nas", "vps", "pi", "desktop"];
    const peers = [];
    for (let i = 0; i < 30; i++) {
        const kind = kinds[i % kinds.length];
        const name = birds[i % birds.length] + "-" + (kind === "desktop" ? "pc" : kind) + (i >= birds.length ? "-2" : "");
        const ms = i % 9 === 8 ? 0 : [3, 8, 14, 26, 48, 75, 120, 160][i * 5 % 8];
        const relay = kind === "vps" || i % 6 === 5 ? (i % 2 ? EU : US) : "";
        const rate = i === 3 ? 6.5 : [0.02, 0.3, 0.08, 1.2, 0.05, 0.5, 0.01][i % 7];
        peers.push([name, "100.93." + (10 + i) + "." + (i * 7 % 250 + 2), ms, relay, rate, 60 + i * 97]);
    }
    return {
        "fqdn": "wren.crowd.example",
        "ip": "100.93.0.1/16",
        "peers": peers,
        "networks": [{ "id": "home-lan", "cidr": "192.168.1.0/24", "via": "plover-laptop", "on": true }]
    };
}
PROFILES.crowd = _crowd();

// The test lab's own mesh: n made-up peers (1 to LAB_MAX) in a mix that
// exercises everything at once: every kind of creature, both relays, some
// asleep, latencies from the next room to the other side of the world, one
// peer that hogs the link. The same n always gives the same mesh.
const LAB_MAX = 120;
function lab(n) {
    n = Math.max(1, Math.min(LAB_MAX, Math.round(Number(n) || 1)));
    const words = ["alder", "birch", "cedar", "dune", "ember", "fjord", "grove", "haze", "iris", "jade", "kelp", "lumen", "moss", "nectar", "onyx", "pearl", "quill", "reed", "sable", "tide"];
    const kinds = ["server", "phone", "laptop", "nas", "vps", "pi", "pc"];
    const ladder = [2, 5, 9, 14, 22, 35, 58, 90, 140, 210];
    const peers = [];
    for (let i = 0; i < n; i++) {
        const kind = kinds[i % kinds.length], round = Math.floor(i / words.length);
        const name = words[i % words.length] + "-" + kind + (round ? "-" + (round + 1) : "");
        // Every 6th asleep, but never the first: a mesh of one is awake
        const ms = i && i % 6 === 5 ? 0 : ladder[(i * 7 + round) % ladder.length];
        const relay = kind === "vps" || i % 5 === 4 ? (i % 2 ? EU : US) : "";
        const rate = i === 2 ? 5.5 : [0.02, 0.4, 0.08, 1.1, 0.06, 0.3, 0.01][(i * 3) % 7];
        peers.push([name, "100.94." + (Math.floor(i / 250) + 1) + "." + (i % 250 + 2), ms, relay, rate, 30 + i * 53]);
    }
    return {
        "fqdn": "wren.lab.example",
        "ip": "100.94.0.1/16",
        "peers": peers,
        "networks": [{ "id": "lab-lan", "cidr": "10.42.0.0/16", "via": peers[0][0], "on": true }]
    };
}

// Builds (or rebuilds) the "lab" profile for n peers
function setLab(n) {
    PROFILES.lab = lab(n);
    return PROFILES.lab.peers.length;
}
setLab(24);

function profiles() {
    return Object.keys(PROFILES);
}

function networks(profile) {
    return PROFILES[profile].networks.map(n => Object.assign({}, n));
}

// Usual traffic of a peer, in Mb/s (the demo source wiggles around it)
function baseRate(profile, name) {
    const p = PROFILES[profile].peers.find(q => q[0] === name);
    return p ? p[4] : 0;
}

// The peer the lab makes silent: online, but no handshake for minutes (the
// second live peer reached directly, so the closest one stays well)
function silentPeer(profile) {
    const pr = PROFILES[profile];
    const q = pr.peers.find((p, i) => i > 0 && p[2] > 0 && !p[3]) || pr.peers.find(p => p[2] > 0);
    return q ? q[0] : "";
}

// The peer the lab makes drop out and come back: the first awake one
function flapPeer(profile) {
    const q = PROFILES[profile].peers.find(p => p[2] > 0);
    return q ? q[0] : "";
}

// The first relay a mesh uses ("relay-eu"), the one the lab breaks
function firstRelay(profile) {
    const q = PROFILES[profile].peers.find(p => p[3]);
    return q ? relayOf(q[3]) : "";
}

function relayOf(uri) {
    return String(uri || "").replace(/^[a-z]+:\/\//, "").split(".")[0];
}

// counters: {name: {rx, tx}} bytes so far; offline: {name: true} peers the
// demo took offline; relayDown: a relay that stopped answering.
// lab (optional): { addMs: latency added to every peer, silent: a peer that
// stopped answering, managementDown: the management server is unreachable }
function status(profile, now, up, counters, offline, relayDown, lab) {
    const pr = PROFILES[profile];
    lab = lab || {};
    const addMs = Math.max(0, Number(lab.addMs) || 0);
    const relayOk = uri => !relayDown || uri.indexOf(relayDown) < 0;
    const details = pr.peers.map(q => {
        const [name, ip, base, relay, , minutes] = q;
        const ms = base > 0 ? base + addMs : 0;
        const silent = name === lab.silent;
        const online = up && ms > 0 && !offline[name] && (!relay || relayOk(relay));
        const c = counters[name] || { "rx": 0, "tx": 0 };
        return {
            "fqdn": name + (({ "work": ".corp.example", "crowd": ".crowd.example", "lab": ".lab.example" })[profile] || ".mesh.example"),
            "netbirdIp": ip,
            "publicKey": "demo-" + name,
            "status": online ? "Connected" : "Idle",
            "lastStatusUpdate": new Date(now - (online ? minutes : 120) * 60000).toISOString(),
            "connectionType": online ? (relay ? "Relayed" : "P2P") : "",
            "relayAddress": relay,
            // A silent peer last shook hands 7 minutes ago (live ones: 40 s)
            "lastWireguardHandshake": online ? new Date(now - (silent ? 420000 : 40000)).toISOString() : "0001-01-01T00:00:00Z",
            "transferReceived": c.rx,
            "transferSent": c.tx,
            "latency": online ? ms * 1e6 : 0,
            // Machines that usually lend their Internet
            "networks": /vps|server|nas/.test(name) ? ["0.0.0.0/0"] : []
        };
    });
    return {
        "fqdn": pr.fqdn,
        "netbirdIp": pr.ip,
        "management": { "url": "https://api.mesh.example:443", "connected": !lab.managementDown },
        "signal": { "url": "https://signal.mesh.example:443", "connected": true },
        "relays": { "details": [{ "uri": EU, "available": relayOk(EU) }, { "uri": US, "available": relayOk(US) }].filter(r => pr.peers.some(q => q[3] === r.uri)) },
        "peers": { "details": details }
    };
}
