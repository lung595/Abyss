// Layout.js tests. Run from anywhere: gjs tests/layout.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const L = load("components/Layout.js");

const p = (id, ms, relay) => ({ id, name: id, online: ms > 0, latencyMs: ms, relayed: !!relay, relay: relay || "" });
const peers = [p("a", 4), p("b", 12), p("c", 40, "relay-eu"), p("d", 150, "relay-eu"), p("e", 0), p("f", 0)];
const lay = L.layout(peers, 560, 420, 60);
const f = lay.frame;

ok("jellyfish below the surface", f.jelly.y - f.jelly.r > f.surfaceY);
ok("every peer placed", peers.every(q => lay.peers[q.id]));
ok("deeper when slower", lay.peers.a.y < lay.peers.d.y);
ok("living peers stay in the band", ["a", "b", "c", "d"].every(id => lay.peers[id].y >= f.bandTop && lay.peers[id].y <= f.bandBottom));
ok("peers right of the jellyfish", ["a", "b", "c", "d"].every(id => lay.peers[id].x > f.jelly.x + f.jelly.r));
ok("peers inside the scene", peers.every(q => lay.peers[q.id].x < 560 && lay.peers[q.id].x > 0));
eq("offline peers rest on the floor", [lay.peers.e.floor, lay.peers.f.floor, lay.peers.e.y], [true, true, f.floorY - 30]);
ok("a relay lantern for relay-eu", !!lay.relays["relay-eu"]);
ok("the lantern sits before its peers", lay.relays["relay-eu"].x < lay.peers.c.x);
eq("no lantern for unused relays", Object.keys(lay.relays), ["relay-eu"]);

// Crowded: labels never overlap
const crowd = [];
for (let i = 0; i < 14; i++) crowd.push(p("n" + i, 8));
const lc = L.layout(crowd, 560, 420, 60);
let clash = 0;
for (let i = 0; i < 14; i++) for (let j = i + 1; j < 14; j++) {
    const a = lc.peers["n" + i], b = lc.peers["n" + j];
    if (Math.abs(a.x - b.x) < 40 && Math.abs(a.y - b.y) < 40) clash++;
}
eq("crowded mesh: no two peers on top of each other", clash, 0);
eq("a single peer is centred", L.layout([p("x", 5)], 560, 420, 60).peers.x.x, (L.frame(560, 420, 60).jelly.x + L.frame(560, 420, 60).jelly.r * 1.9 + 560 - 58) / 2);
ok("caves left of the resting peers", L.caveX(f, 1) < lay.peers.e.x);
const asleep = L.layout(peers.map(q => Object.assign({}, q, { online: false })), 560, 420, 60);
ok("disconnected: resting peers spread over the floor", asleep.peers.a.x < lay.peers.e.x);
const ten = [];
for (let i = 0; i < 10; i++) ten.push(p("s" + i, 0));
const lt = L.layout(ten, 560, 420, 60);
ok("a crowd rests on two rows", lt.peers.s0.y !== lt.peers.s1.y);
ok("a few rest on one row", asleep.peers.a.y === asleep.peers.b.y);
eq("empty mesh", Object.keys(L.layout([], 560, 420, 60).peers).length, 0);

// Tentacles
const t = L.tentacle([10, 10], [300, 200], null);
eq("starts at the rim", t[0], [10, 10]);
eq("ends just before the peer", t[t.length - 1], [282, 200]);
const tv = L.tentacle([10, 10], [300, 200], [150, 120]);
ok("goes through the relay", tv.some(q => q[0] === 150 && q[1] === 120));
eq("point at 0", L.pointAt([[0, 0], [10, 0]], 0), [0, 0]);
eq("point at half", L.pointAt([[0, 0], [10, 0], [10, 10]], 0.5), [10, 0]);
eq("point at the end", L.pointAt([[0, 0], [10, 0]], 1), [10, 0]);
eq("length", L.length([[0, 0], [3, 4]]), 5);
eq("head of a polyline", L.head([[0, 0], [1, 0], [2, 0], [3, 0]], 0.5).length, 2);
eq("full head", L.head([[0, 0], [1, 0]], 1).length, 2);
const r0 = L.rimPoint(f.jelly, 0, 4), r3 = L.rimPoint(f.jelly, 3, 4);
ok("rim points spread left to right", r0[0] < r3[0] && r0[1] === r3[1]);

done("layout");
