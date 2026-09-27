// Groups.js and Query.js tests. Run from anywhere: gjs tests/groups.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const G = load("components/Groups.js");
const Q = load("components/Query.js");

const KINDS = ["phone", "laptop", "server", "desktop", "nas", "vps", "pi"];
// A made-up mesh of n peers: every 7th is offline, every 4th goes through a relay
function mesh(n) {
    const out = [];
    for (let i = 0; i < n; i++) {
        const online = i % 7 !== 6, relayed = online && i % 4 === 3;
        out.push({
            id: "k" + i, name: KINDS[i % 7] + "-" + i, kind: KINDS[i % 7], online,
            relayed, relay: relayed ? (i % 8 === 3 ? "relay-eu" : "relay-us") : "",
            latencyMs: online ? [4, 12, 35, 60, 140][i % 5] : 0,
            down: online ? (i * 37 % 11) * 2e4 : 0, up: online ? 1e4 : 0
        });
    }
    return out;
}

// Never more than max things, whatever the mesh
let fine = true;
for (const n of [3, 4, 10, 30, 80])
    for (let max = 3; max <= 10; max++) {
        const r = G.arrange(mesh(n), max, {});
        const count = r.items.reduce((a, it) => a + (it.type === "group" ? it.members.length : 1), 0);
        if (r.items.length > max || count !== n)
            fine = false, print("  n=" + n + " max=" + max + " -> " + r.items.length + " items, " + count + " peers");
    }
ok("at most max items, every peer in exactly one", fine);

const small = G.arrange(mesh(4), 5, {});
ok("few peers: no groups", small.items.every(i => i.type === "peer"));

const big = G.arrange(mesh(30), 5, {});
ok("30 peers in 5 places", big.items.length === 5);
ok("offline peers form one asleep group", big.items.some(i => i.id === "g:asleep" && i.members.length === 4));
ok("a criterion was chosen", ["kind", "route", "distance", "activity"].indexOf(big.key) >= 0);

// A heavy user stands alone, and stays alone a little below the threshold
const heavy = mesh(30);
// Busy enough that 16 % of the traffic is still over the 1 Mb/s floor
heavy.forEach(p => p.down *= 10);
heavy[0].down = 60e6;
const h1 = G.arrange(heavy, 5, {});
ok("heavy user is a star", h1.stars.indexOf("k0") >= 0);
const others = heavy.filter(p => p.online).reduce((a, p) => a + G.total(p), 0) - G.total(heavy[0]);
heavy[0].down = others * 0.16 / 0.84; // ~16 % of the traffic
ok("…and stays one at 16 % (hysteresis)", G.arrange(heavy, 5, { memo: h1 }).stars.indexOf("k0") >= 0);
ok("…but a newcomer at 16 % is not", G.arrange(heavy, 5, {}).stars.indexOf("k0") < 0);

// Trouble first: a peer behind a relay that is down
const r1 = G.arrange(mesh(30), 5, { broken: ["relay-eu"] });
ok("peer behind a dead relay stands alone", r1.stars.some(id => mesh(30).find(p => p.id === id).relay === "relay-eu"));

// Favourites stand alone
ok("favourite stands alone", G.arrange(mesh(30), 6, { favorites: { k9: "x" } }).stars.indexOf("k9") >= 0);

// Sticky criterion: same mesh, previous key kept
const again = G.arrange(mesh(30), 5, { memo: { key: big.key } });
eq("criterion is stable between reads", again.key, big.key);

// No search: the view is the arrangement itself
const plain = G.view(mesh(30), 5, [], {});
ok("no search: at most max items, no fog", plain.items.length <= 5 && !plain.items.some(i => i.fog));

// Search: results take the places, the rest is one fog item
const fq = G.view(mesh(30), 5, Q.parse("nas"), {});
eq("search keeps the matches", fq.hits, mesh(30).filter(p => p.kind === "nas").length);
ok("…and fogs everything else in one item", fq.items.filter(i => i.fog).length === 1 && fq.items.length <= 5);
const none = G.view(mesh(30), 5, Q.parse("zzzz"), {});
ok("no match: only the fog", none.hits === 0 && none.items.length === 1 && none.items[0].fog);

// Query words
const labels = q => Q.parse(q, ["relay-eu", "relay-us"]).map(f => f.label);
eq("phones offline", labels("phones offline"), ["phones", "offline"]);
eq("French: téléphones hors ligne", labels("téléphones hors ligne"), ["phones", "offline"]);
eq("en ligne is online, not a name", labels("en ligne"), ["online"]);
eq("latency bound", labels(">100ms"), ["latency > 100 ms"]);
eq("relay by its tail", labels("eu"), ["via relay-eu"]);
const hrbr = Q.parse("hrbr")[0];
ok("approximate name: hrbr finds harbor-vps", hrbr.name && hrbr.test({ name: "harbor-vps" }) && !hrbr.test({ name: "otter-nas" }));
const slow = Q.parse("slow")[0];
ok("slow = online and > 100 ms", slow.test({ online: true, latencyMs: 140 }) && !slow.test({ online: false, latencyMs: 0 }));

// The user's own groups: first, whole, and the count still holds
{
    const peers = mesh(30), mine = [{ id: "u1", name: "Home", members: ["k0", "k1", "k6", "k2"] }];
    const r = G.arrange(peers, 5, { mine: mine });
    const home = r.items[0];
    ok("my group comes first", home.id === "g:u:u1" && home.label === "Home" && home.mine === "u1");
    eq("only its online members gather there (k6 sleeps)", home.members.join(","), "k0,k1,k2");
    ok("still never more than max", r.items.length <= 5);
    const count = r.items.reduce((a, it) => a + (it.type === "group" ? it.members.length : 1), 0);
    eq("every peer is shown once", count, 30);
    ok("a small mesh keeps my group too", G.arrange(mesh(4), 8, { mine: [{ id: "u2", name: "Pair", members: ["k0", "k1"] }] }).items[0].id === "g:u:u2");
    ok("a group with nobody online is not drawn", G.arrange(peers, 5, { mine: [{ id: "u3", name: "Gone", members: ["k6"] }] }).items.every(i => i.id !== "g:u:u3"));
}

done("groups + query");
