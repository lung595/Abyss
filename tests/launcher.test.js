// LauncherItems.js tests (what "abyss" offers in the launcher).
// Run from anywhere: gjs tests/launcher.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const L = load("components/LauncherItems.js");

const peers = [
    { id: "a", name: "atlas", ip: "100.64.0.2", online: true, latencyMs: 4, exit: true },
    { id: "b", name: "vega", ip: "100.64.0.3", online: true, latencyMs: 12, exit: true },
    { id: "c", name: "orion", ip: "100.64.0.4", online: false, latencyMs: 2, exit: true },
    { id: "d", name: "lyra", ip: "100.64.0.5", online: true, latencyMs: 30, exit: true },
    { id: "e", name: "laptop", ip: "100.64.0.6", online: true, latencyMs: 1, exit: false },
    { id: "f", name: "tern", ip: "100.64.0.7", online: true, latencyMs: 60, exit: true },
    { id: "g", name: "pike", ip: "100.64.0.8", online: true, latencyMs: 90, exit: true }
];
const groups = [{ id: "u1", name: "Busy", members: ["a", "b", "c"] }];
const base = { status: "connected", online: 6, total: 7, peers: peers, groups: groups, exitNode: "", exitGroup: "" };
const names = list => list.map(i => i.name);

let it = L.items(base, "");
eq("the deep comes first", it[0].name, "Open Abyss");
eq("then the step that moves the connection", it[1].name, "Disconnect NetBird");
ok("every group of mine that can lend", names(it).indexOf("Internet through all of Busy") >= 0);
eq("three quickest peers, no more", it.filter(i => i.action.indexOf("exit:peer:") === 0).length, 3);
ok("nothing to stop while going out directly", !it.some(i => i.action === "exit:off"));
ok("an offline lender is never offered", !it.some(i => i.name === "Internet through orion"));
ok("a peer that cannot lend is never offered", !L.items(base, "internet laptop").length);

it = L.items(Object.assign({}, base, { exitNode: "vega", exitGroup: "" }), "");
eq("what is in use comes right after connecting, with a sun", it[2].name + " " + it[2].icon, "Internet through vega material:wb_sunny");
eq("and the way back last", it[it.length - 1].action, "exit:off");

it = L.items(Object.assign({}, base, { exitNode: "atlas", exitGroup: "u1" }), "");
eq("a group in use says through whom", it[2].comment.indexOf("via atlas") >= 0, true);

eq("words narrow it down", names(L.items(base, "ssh vega")).join(), "SSH to vega");
eq("copying gives the address", L.items(base, "copy atlas")[0].comment, "100.64.0.2");
eq("offline peers are not offered", L.items(base, "ssh orion").length, 0);

const off = Object.assign({}, base, { status: "needsLogin" });
eq("signed out: open and sign in only", names(L.items(off, "")).join(), "Open Abyss,Sign in to NetBird");

// Smart search from the launcher: speeds, states and kinds pick the peers
const P2 = peers.map(p => Object.assign({ kind: p.name === "vega" ? "phone" : "server", relayed: p.name === "pike", relay: p.name === "pike" ? "relay-eu" : "", down: 0, up: 0 }, p));
const smart = Object.assign({}, base, { peers: P2, relays: ["relay-eu"] });
eq(">50ms lists the slow peers", names(L.items(smart, ">50ms")).filter(n => /^(Copy|SSH)/.test(n)).join("|"), "Copy tern's address|SSH to tern|Copy pike's address|SSH to pike");
eq("a verb keeps one row per peer", names(L.items(smart, "ssh >50ms")).join("|"), "SSH to tern|SSH to pike");
eq("a kind: copy phones", names(L.items(smart, "copy phones")).join("|"), "Copy vega's address");
eq("a state: direct and fast", names(L.items(smart, "ssh direct <5ms")).join("|"), "SSH to atlas|SSH to laptop");
eq("a relay by its tail", names(L.items(smart, "ssh eu")).join("|"), "SSH to pike");
eq("plain words still narrow by name", names(L.items(smart, "ssh vega")).join(), "SSH to vega");
eq("offline peers are never offered", names(L.items(smart, "ssh offline")).join("|"), "");

done("launcher");
