// Netbird.js tests, against outputs shaped like the NetBird client's own
// (client/status/status.go, client/cmd/networks.go, profile.go).
// Run from anywhere: gjs tests/netbird.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const N = load("components/Netbird.js");
const M = load("components/Mesh.js");

// --- status --json, as the client prints it (made-up names and keys) ------
const peer = (fqdn, ip, status, extra) => Object.assign({
    "fqdn": fqdn, "netbirdIp": ip, "publicKey": "key-" + fqdn.split(".")[0], "status": status,
    "lastStatusUpdate": "2026-09-30T08:00:00Z", "connectionType": status === "Connected" ? "P2P" : "",
    "iceCandidateType": { "local": "host", "remote": "srflx" }, "iceCandidateEndpoint": { "local": "", "remote": "" },
    "relayAddress": "", "lastWireguardHandshake": "2026-09-30T09:59:00Z",
    "transferReceived": 1000, "transferSent": 500, "latency": 12000000, "quantumResistance": false, "networks": []
}, extra || {});
const STATUS = {
    "peers": { "total": 4, "connected": 3, "details": [
        peer("atlas.netbird.cloud", "100.90.0.2", "Connected", { "networks": ["0.0.0.0/0", "::/0"] }),
        peer("nook-nas.netbird.cloud", "100.90.0.3", "Connected", { "networks": ["192.168.1.0/24"] }),
        peer("harbor-vps.netbird.cloud", "100.90.0.4", "Connected", { "connectionType": "Relayed", "relayAddress": "rels://relay-eu.netbird.io:443" }),
        peer("lark-phone.netbird.cloud", "100.90.0.5", "Idle")
    ] },
    "cliVersion": "0.60.0", "daemonVersion": "0.60.0", "daemonStatus": "Connected",
    "management": { "url": "https://api.netbird.io:443", "connected": true, "error": "" },
    "signal": { "url": "https://signal.netbird.io:443", "connected": true, "error": "" },
    "relays": { "total": 1, "available": 1, "details": [{ "uri": "rels://relay-eu.netbird.io:443", "available": true, "error": "" }] },
    "netbirdIp": "100.90.0.1/16", "publicKey": "key-wren", "usesKernelInterface": true, "fqdn": "wren.netbird.cloud",
    "quantumResistance": false, "networks": [], "forwardingRules": 0, "dnsServers": [], "events": [],
    "lazyConnectionEnabled": false, "profileName": "default"
};

// --- Reading the status ---------------------------------------------------
const st = N.readStatus(JSON.stringify(STATUS, null, 2), 0);
eq("json status gives the daemon word", st.daemonStatus, "Connected");
ok("json status keeps the json", st.json && st.json.peers.total === 4);
eq("json status has no error", st.error, "");
const login = N.readStatus(JSON.stringify(Object.assign({}, STATUS, { "daemonStatus": "NeedsLogin" })), 0);
eq("a sign-in needed comes through the json", M.stateOf(login.daemonStatus), "needsLogin");
eq("older clients say it as text", N.readStatus("Daemon status: SessionExpired\n\nRun UP command to log in", 0).daemonStatus, "SessionExpired");
const down = N.readStatus("Error: failed to connect to daemon error: context deadline exceeded\nIf the daemon is not running please run:", 1);
eq("no daemon reads as stopped", M.stateOf(down.daemonStatus), "stopped");
eq("no daemon says why, in one line", down.error, "Error: failed to connect to daemon error: context deadline exceeded");
ok("broken json is an error, not a crash", N.readStatus("{ nope", 0).error.indexOf("could not be read") >= 0);
eq("nothing printed is an error", N.readStatus("", 0).error, "NetBird printed nothing");

// --- The view from a real-shaped status -----------------------------------
const view = M.parse(st.daemonStatus, st.json, null, Date.parse("2026-09-30T10:00:00Z"));
eq("connected", view.state, "connected");
eq("me", view.me, { "name": "wren", "fqdn": "wren.netbird.cloud", "ip": "100.90.0.1" });
eq("online count (Idle is not online)", view.online, 3);
const atlas = view.peers.find(p => p.name === "atlas");
eq("since comes from lastStatusUpdate", atlas.since, Date.parse("2026-09-30T08:00:00Z"));
eq("latency from Go nanoseconds", atlas.latencyMs, 12);
ok("the peer carrying 0.0.0.0/0 lends Internet now", atlas.lending && atlas.exit);
eq("its networks are kept", atlas.networks, ["0.0.0.0/0", "::/0"]);
eq("relay from the relay address", view.peers.find(p => p.name === "harbor-vps").relay, "relay-eu");
ok("an idle peer lends nothing", !view.peers.find(p => p.name === "lark-phone").lending);

// --- networks list ----------------------------------------------------------
const NETS = "Available Networks:\n" +
    "\n  - ID: exit-atlas\n    Network: 0.0.0.0/0\n    Status: Selected\n" +
    "\n  - ID: exit-atlas-v6\n    Network: ::/0\n    Status: Selected\n" +
    "\n  - ID: exit-harbor\n    Network: 0.0.0.0/0\n    Status: Not Selected\n" +
    "\n  - ID: Office Exit\n    Network: 0.0.0.0/0\n    Status: Not Selected\n" +
    "\n  - ID: home-lan\n    Network: 192.168.1.0/24\n    Status: Selected\n" +
    "\n  - ID: wiki\n    Domains: wiki.corp.example, *.corp.example\n    Status: Not Selected\n    Resolved IPs:\n      [wiki.corp.example]: 10.0.0.5\n";
const nets = N.readNetworks(NETS);
eq("every network is read", nets.map(n => n.id), ["exit-atlas", "exit-atlas-v6", "exit-harbor", "Office Exit", "home-lan", "wiki"]);
eq("a network route", nets[4], { "id": "home-lan", "range": "192.168.1.0/24", "domains": [], "selected": true });
eq("a domain route", nets[5].domains, ["wiki.corp.example", "*.corp.example"]);
ok("not selected", !nets[2].selected);
eq("no networks", N.readNetworks("No networks available.\n"), []);
eq("exit routes", N.exitRoutes(nets).map(n => n.id), ["exit-atlas", "exit-atlas-v6", "exit-harbor", "Office Exit"]);

// --- Which exit route goes through which peer -----------------------------
const map = N.exitMap(nets, view.peers, {});
eq("the selected v4 and v6 routes and their names point to atlas", N.routesOf(map, atlas.id), ["exit-atlas", "exit-atlas-v6"]);
eq("a route named after a peer is that peer's", map["exit-harbor"], "key-harbor-vps");
ok("a route named after nobody stays unknown", !("Office Exit" in map));
eq("what was learned is kept", N.exitMap(nets, view.peers, { "Office Exit": "key-nook-nas" })["Office Exit"], "key-nook-nas");
ok("what was learned about a gone peer is dropped", !("Office Exit" in N.exitMap(nets, view.peers, { "Office Exit": "key-gone" })));
const lendNow = N.markExits(view.peers, map);
eq("the one lending now", lendNow, "atlas");
ok("harbor can lend", view.peers.find(p => p.name === "harbor-vps").exit);
ok("nook cannot", !view.peers.find(p => p.name === "nook-nas").exit);

// --- Commands for the light -----------------------------------------------
const toHarbor = N.exitCommands(nets, map, "key-harbor-vps");
eq("moving the light: drop the old routes, then add the new one", toHarbor.cmds, [
    ["netbird", "networks", "deselect", "--", "exit-atlas", "exit-atlas-v6"],
    ["netbird", "networks", "select", "-a", "--", "exit-harbor"]]);
eq("stopping drops every selected exit route", N.exitCommands(nets, map, "").cmds, [["netbird", "networks", "deselect", "--", "exit-atlas", "exit-atlas-v6"]]);
eq("the same peer again only re-selects it", N.exitCommands(nets, map, atlas.id).cmds, [["netbird", "networks", "select", "-a", "--", "exit-atlas", "exit-atlas-v6"]]);
const nope = N.exitCommands(nets, map, "key-nook-nas");
eq("a peer with no known route runs nothing", nope.cmds, []);
ok("...and says what to do", nope.error.indexOf("dashboard") >= 0);
eq("nothing selected, stopping runs nothing", N.exitCommands(N.readNetworks("  - ID: x\n    Network: 0.0.0.0/0\n    Status: Not Selected\n"), {}, "").cmds, []);
eq("a route id starting with - stays an argument", N.selectNetworksCmd(["-rf"], false), ["netbird", "networks", "select", "--", "-rf"]);

// --- Caves ------------------------------------------------------------------
eq("caves leave the exit routes out and say who carries them", N.caves(nets, view.peers), [
    { "id": "home-lan", "cidr": "192.168.1.0/24", "via": "nook-nas", "on": true },
    { "id": "wiki", "cidr": "wiki.corp.example, *.corp.example", "via": "", "on": false }]);

// --- Profiles ---------------------------------------------------------------
const prof = N.readProfiles("NAME     ACTIVE\ndefault  \nwork     ✓\nmy home  \n");
eq("profile names", prof.names, ["default", "work", "my home"]);
eq("active profile", prof.active, "work");
eq("no profiles", N.readProfiles(""), { "names": [], "active": "" });

// Naming guesses
const P = [{ id: "a", name: "harbor-vps" }, { id: "b", name: "harbor-nas" }, { id: "c", name: "atlas" }, { id: "d", name: "pi" }];
const one = id => N.exitMap([{ id, range: "0.0.0.0/0", domains: [], selected: false }], P, {})[id];
eq("whole name inside the id", one("harbor-vps-exit"), "a");
eq("a shared word fitting two peers picks nobody", one("exit-harbor"), undefined);
eq("a shared word fitting one peer", one("Atlas Exit"), "c");
eq("generic words never match", one("exit-node"), undefined);
eq("names shorter than 3 letters never match inside", one("spirit"), undefined);

done("netbird");
