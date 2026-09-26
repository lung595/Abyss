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

// counters: {name: {rx, tx}} bytes so far; offline: {name: true} peers the
// demo took offline; relayDown: a relay that stopped answering
function status(profile, now, up, counters, offline, relayDown) {
    const pr = PROFILES[profile];
    const relayOk = uri => !relayDown || uri.indexOf(relayDown) < 0;
    const details = pr.peers.map(q => {
        const [name, ip, ms, relay, , minutes] = q;
        const online = up && ms > 0 && !offline[name] && (!relay || relayOk(relay));
        const c = counters[name] || { "rx": 0, "tx": 0 };
        return {
            "fqdn": name + (profile === "work" ? ".corp.example" : ".mesh.example"),
            "netbirdIp": ip,
            "publicKey": "demo-" + name,
            "status": online ? "Connected" : "Idle",
            "statusSince": new Date(now - (online ? minutes : 120) * 60000).toISOString(),
            "connectionType": online ? (relay ? "Relayed" : "P2P") : "",
            "relayAddress": relay,
            "lastWireguardHandshake": online ? new Date(now - 40000).toISOString() : "0001-01-01T00:00:00Z",
            "transferReceived": c.rx,
            "transferSent": c.tx,
            "latency": online ? ms * 1e6 : 0
        };
    });
    return {
        "fqdn": pr.fqdn,
        "netbirdIp": pr.ip,
        "management": { "url": "https://api.mesh.example:443", "connected": true },
        "signal": { "url": "https://signal.mesh.example:443", "connected": true },
        "relays": { "details": [{ "uri": EU, "available": relayOk(EU) }, { "uri": US, "available": relayOk(US) }].filter(r => pr.peers.some(q => q[3] === r.uri)) },
        "peers": { "details": details }
    };
}
