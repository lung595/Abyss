// Mesh.js tests. Run from anywhere: gjs tests/mesh.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const M = load("components/Mesh.js");

// States
eq("connected", M.stateOf("Connected"), "connected");
eq("no daemon = stopped", M.stateOf(""), "stopped");
eq("session expired asks for a login", M.stateOf("SessionExpired"), "needsLogin");
eq("unknown word = disconnected", M.stateOf("Weird"), "disconnected");

// Small helpers
eq("short name", M.shortName("kestrel.netbird.cloud"), "kestrel");
eq("bare ip", M.bareIp("100.92.0.7/16"), "100.92.0.7");
eq("latency ns -> ms", M.latencyMs(26000000), 26);
eq("latency missing", M.latencyMs(undefined), 0);
eq("relay name", M.relayName("rels://relay-eu.mesh.example:443"), "relay-eu");
eq("relay name without scheme", M.relayName("relay-us.x:443"), "relay-us");

// Kinds from names
eq("phone", M.kindOf("lark-phone"), "phone");
eq("pi", M.kindOf("pi-garden"), "pi");
eq("not a pi inside a word", M.kindOf("pixel-7") , "phone");
eq("nas", M.kindOf("nook-nas"), "nas");
eq("vps", M.kindOf("harbor-vps"), "vps");
eq("server", M.kindOf("proxmox01"), "server");
eq("laptop", M.kindOf("thinkpad"), "laptop");
eq("default desktop", M.kindOf("studio"), "desktop");
// Short words only count as a whole word
eq("air inside chair is no laptop", M.kindOf("chair-pc"), "desktop");
eq("air inside hairdresser is no laptop", M.kindOf("hairdresser"), "desktop");
eq("nas inside banana is no nas", M.kindOf("banana"), "desktop");
eq("host inside ghost is no server", M.kindOf("ghost"), "desktop");
eq("node inside nodejs is no server", M.kindOf("nodejs-dev"), "desktop");
eq("macbook-air is a laptop", M.kindOf("macbook-air"), "laptop");
eq("macbookair is a laptop", M.kindOf("macbookair"), "laptop");
eq("rpi4 is a pi", M.kindOf("rpi4"), "pi");
eq("pi_garden is a pi", M.kindOf("pi_garden"), "pi");
eq("k8s-node2 is a server", M.kindOf("k8s-node2"), "server");
eq("my-iphone is a phone", M.kindOf("my-iphone"), "phone");
eq("aws-bastion is a vps", M.kindOf("aws-bastion"), "vps");
eq("nas01 is a nas", M.kindOf("nas01"), "nas");

// Rates
eq("rate", M.rate(2000, 1000, 1), 8000);
eq("counter reset gives zero", M.rate(10, 5000, 1), 0);
eq("no time gives zero", M.rate(2000, 1000, 0), 0);

// Parsing
const peer = (name, status, type, latMs, rx, tx, extra) => Object.assign({
    fqdn: name + ".mesh.example", netbirdIp: "100.92.0." + name.length, publicKey: "k-" + name,
    status, connectionType: type, latency: latMs * 1e6, transferReceived: rx, transferSent: tx,
    relayAddress: type === "Relayed" ? "rels://relay-eu.mesh.example:443" : "",
    statusSince: "2026-09-26T10:00:00Z", lastWireguardHandshake: "2026-09-26T12:00:00Z"
}, extra || {});
const json = (rx) => ({
    fqdn: "wren.mesh.example", netbirdIp: "100.92.0.1/16",
    management: { connected: true },
    relays: { details: [{ uri: "rels://relay-eu.mesh.example:443", available: true }, { uri: "rels://relay-us.mesh.example:443", available: false }] },
    peers: { details: [
        peer("far", "Connected", "Relayed", 120, rx, 10),
        peer("near", "Connected", "P2P", 4, 1000, 1000),
        peer("gone", "Idle", "", 0, 0, 0)
    ] }
});
const t0 = Date.parse("2026-09-26T12:01:00Z");
const v1 = M.parse("Connected", json(1000), null, t0);
eq("me", v1.me, { name: "wren", fqdn: "wren.mesh.example", ip: "100.92.0.1" });
eq("order: online by latency, then offline", v1.peers.map(p => p.name), ["near", "far", "gone"]);
eq("counts", [v1.online, v1.total], [2, 3]);
eq("relayed peer knows its relay", [v1.peers[1].relayed, v1.peers[1].relay], [true, "relay-eu"]);
eq("first read has no rate yet", v1.down, 0);
eq("relay omen names who goes through it (nobody)", v1.omens.map(o => o.kind), ["relay"]);
const v2 = M.parse("Connected", json(1000 + 125000), v1, t0 + 1000);
eq("download rate from two reads", v2.peers[1].down, 1e6);
eq("total down", v2.down, 1e6);
eq("top consumer", v2.topId, "k-far");
const v3 = M.parse("Connected", json(1000 + 125000 + 10), v2, t0 + 2000);
ok("rates ease down instead of dropping", v3.down > 1e5 && v3.down < 1e6);
let idle = v3;
for (let i = 3; i <= 7; i++)
    idle = M.parse("Connected", json(1000 + 125000 + 10), idle, t0 + i * 1000);
eq("an idle mesh soon has no top consumer", idle.topId, "");
// Opening the view: a read after a long pause, then one a few ms later,
// measure nothing (the old spike: a second of bytes over a few ms)
const back = M.parse("Connected", json(1000 + 125000 + 250000), v2, t0 + 60000);
const quick = M.parse("Connected", json(1000 + 125000 + 500000), back, t0 + 60005);
eq("no rate after a pause or a few ms apart", [back.down, quick.down], [v2.down, v2.down]);
// Two peers with close traffic: the crown stays put instead of flickering
const duo = (a, b) => ({ peers: { details: [
    peer("a", "Connected", "P2P", 4, a, 0), peer("b", "Connected", "P2P", 5, b, 0)] } });
let crown = M.parse("Connected", duo(0, 0), null, t0);
crown = M.parse("Connected", duo(200000, 190000), crown, t0 + 1000);
const holder = crown.topId;
let swaps = 0;
for (let i = 2; i <= 12; i++) {
    const a = 200000 * i + (i % 2 ? 30000 : 0), b = 190000 * i + (i % 2 ? 0 : 60000);
    const next = M.parse("Connected", duo(a, b), crown, t0 + i * 1000);
    if (next.topId !== crown.topId) swaps++;
    crown = next;
}
eq("close traffic keeps the same top consumer", [holder, swaps], ["k-a", 0]);
// A clear rival takes it over
let rival = crown;
for (let i = 13; i <= 20; i++)
    rival = M.parse("Connected", duo(200000 * 12 + 30000, 190000 * 12 + 60000 + 900000 * (i - 12)), rival, t0 + i * 1000);
eq("a clearly busier peer takes the crown", rival.topId, "k-b");
ok("the arrangement's traffic moves slowly", v3.peers[1].calm > 0.9e6);
// Latency jitter: the steady value holds, a real change is followed
const lat = (ms) => ({ peers: { details: [peer("j", "Connected", "P2P", ms, 0, 0)] } });
let lv = M.parse("Connected", lat(10), null, t0);
for (let i = 1; i <= 30; i++)
    lv = M.parse("Connected", lat(i % 2 ? 7 : 13), lv, t0 + i * 1000);
eq("latency jitter keeps its place", lv.peers[0].steadyMs, 10);
for (let i = 31; i <= 90; i++)
    lv = M.parse("Connected", lat(60), lv, t0 + i * 1000);
ok("a lasting change of latency is followed", lv.peers[0].steadyMs > 40);
const vd = M.parse("Idle", json(5000), v2, t0 + 3000);
eq("no rates and no omens when disconnected", [vd.down, vd.omens.length], [0, 0]);
const vs = M.parse("", null, null, t0);
eq("stopped daemon: empty view", [vs.state, vs.total, vs.me.name], ["stopped", 0, "you"]);
const late = M.parse("Connected", json(1000), null, t0 + 10 * 60000);
ok("silent peer omen after 5 min", late.omens.some(o => o.kind === "silent"));
const noMgmt = json(1); noMgmt.management.connected = false;
ok("management omen", M.parse("Connected", noMgmt, null, t0).omens[0].kind === "management");

// Scales
eq("level of nothing", M.level(0), 0);
ok("level grows", M.level(1e5) < M.level(1e7));
eq("level saturates", M.level(1e12), 1);
eq("depth of 1 ms", M.depthOf(1), 0);
eq("depth of 320 ms", M.depthOf(320), 1);
ok("depth grows with latency", M.depthOf(10) < M.depthOf(100));

// Formats
eq("rate kb", M.fmtRate(310000), "310 kb/s");
eq("rate Mb", M.fmtRate(9.2e6), "9.2 Mb/s");
eq("rate big Mb", M.fmtRate(48e6), "48 Mb/s");
eq("short", [M.fmtShort(9.2e6), M.fmtShort(310000)], ["9.2M", "310k"]);
eq("bytes", [M.fmtBytes(512), M.fmtBytes(3.2e9)], ["512 B", "3.2 GB"]);
eq("ago", [M.fmtAgo(12000), M.fmtAgo(125 * 60000)], ["12 s", "2 h 05"]);

// Which peers can lend Internet: they serve 0.0.0.0/0 (an exit node)
eq("a peer serving 0.0.0.0/0 can lend", M.peerOf(peer("x", "Connected", "P2P", 5, 0, 0, { networks: ["10.0.0.0/8", "0.0.0.0/0"] })).exit, true);
eq("older clients call them routes", M.peerOf(peer("x", "Connected", "P2P", 5, 0, 0, { routes: ["0.0.0.0/0"] })).exit, true);
eq("no such route: cannot lend", M.peerOf(peer("x", "Connected", "P2P", 5, 0, 0, { networks: ["192.168.1.0/24"] })).exit, false);

done("mesh");
