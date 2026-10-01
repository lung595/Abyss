// DemoMesh.js tests: the test lab's mesh and its troubles.
// Run from anywhere: gjs tests/demomesh.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const D = load("components/DemoMesh.js");
const M = load("components/Mesh.js");
const G = load("components/Groups.js");

const T0 = 1700000000000;
const read = (profile, lab, offline, relayDown) => M.parse("Connected", D.status(profile, T0, true, {}, offline || {}, relayDown || "", lab), null, T0);

// Size: clamped to 1..120, always the asked number of peers
for (const [asked, want] of [[1, 1], [24, 24], [120, 120], [0, 1], [500, 120], [-3, 1], ["7", 7]])
    eq("lab of " + asked + " peers has " + want, D.setLab(asked), want);

// Every size gives distinct names, plain hosts, and the same mesh twice
let fine = true;
for (let n = 1; n <= 120; n++) {
    D.setLab(n);
    const v = read("lab");
    const names = v.peers.map(p => p.name);
    if (new Set(names).size !== n || names.some(s => !/^[a-z0-9-]+$/.test(s)))
        fine = false, print("  n=" + n + ": " + names.join(","));
}
ok("names are distinct plain hosts for every size", fine);
D.setLab(24);
eq("the same size gives the same mesh", JSON.stringify(D.lab(24)), JSON.stringify(D.lab(24)));

// A lab of one is awake; a bigger one has a bit of everything
D.setLab(1);
eq("a lab of one is online", read("lab").online, 1);
D.setLab(40);
const big = read("lab");
const kinds = new Set(big.peers.map(p => p.kind));
ok("every creature shows up", ["server", "phone", "laptop", "nas", "vps", "pi", "desktop"].every(k => kinds.has(k)));
ok("some peers sleep", big.online < big.total && big.online > big.total / 2);
ok("both relays are used", new Set(big.peers.filter(p => p.relayed).map(p => p.relay)).size === 2);
ok("latencies span near and far", Math.min(...big.peers.filter(p => p.online).map(p => p.latencyMs)) <= 5 && Math.max(...big.peers.map(p => p.latencyMs)) >= 140);
ok("some peers can lend Internet", big.peers.some(p => p.exit));

// Groups form past "Things on screen", for any lab size (P60's arrangement)
fine = true;
for (const n of [1, 5, 11, 60, 120]) {
    D.setLab(n);
    const v = read("lab");
    for (const max of [3, 5, 10]) {
        const r = G.arrange(v.peers, max, {});
        const count = r.items.reduce((a, it) => a + (it.type === "group" ? it.members.length : 1), 0);
        if (r.items.length > max || count !== n)
            fine = false, print("  n=" + n + " max=" + max + " -> " + r.items.length + " items, " + count + " peers");
    }
}
ok("groups hold every lab peer, never more than max things", fine);

// Added latency: on every online peer, never on a sleeping one
const plain = read("home"), slow = read("home", { "addMs": 80 });
ok("added latency reaches every online peer", plain.peers.every(p => {
    const q = slow.peers.find(x => x.id === p.id);
    return p.online ? Math.abs(q.latencyMs - p.latencyMs - 80) < 1e-6 : q.latencyMs === 0 && !q.online;
}));
eq("negative latency adds nothing", read("home", { "addMs": -50 }).peers.map(p => p.latencyMs), plain.peers.map(p => p.latencyMs));

// A peer that stops answering: still online, raised as a silent warning
const quiet = D.silentPeer("home");
ok("the silent peer is a live direct one", plain.peers.some(p => p.name === quiet && p.online && !p.relayed));
ok("the silent peer is not the closest", plain.peers[0].name !== quiet);
const silent = read("home", { "silent": quiet });
ok("its warning is raised", silent.omens.some(o => o.kind === "silent" && o.text.indexOf(quiet) === 0));
eq("only one warning", silent.omens.length, 1);
eq("no warning without trouble", plain.omens.length, 0);
ok("every profile has a silent candidate", D.profiles().every(p => D.silentPeer(p) !== ""));

// Management down, relay down
ok("management down is raised", read("work", { "managementDown": true }).omens.some(o => o.kind === "management"));
const relay = read("home", {}, {}, "relay-eu");
ok("a relay down is raised and its peers sleep", relay.omens.some(o => o.kind === "relay" && o.relay === "relay-eu") && relay.peers.filter(p => p.relay === "relay-eu").length === 0);

// The flapping peer and the broken relay exist in every mesh that has them
ok("every mesh has a peer to flap", D.profiles().every(p => D.flapPeer(p) !== ""));
eq("home breaks relay-eu first", D.firstRelay("home"), "relay-eu");
eq("work has only relay-eu", D.firstRelay("work"), "relay-eu");
D.setLab(3);
eq("a lab with no relay breaks none", D.firstRelay("lab"), "");

done("DemoMesh.js");
