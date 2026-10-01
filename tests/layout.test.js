// Layout.js tests. Run from anywhere: gjs tests/layout.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const L = load("components/Layout.js");
const M = load("components/Mesh.js");

const p = (id, ms, relay) => ({ id, name: id, online: ms > 0, latencyMs: ms, relayed: !!relay, relay: relay || "" });
const peers = [p("a", 4), p("b", 12), p("c", 40, "relay-eu"), p("d", 150, "relay-eu"), p("e", 0), p("f", 0)];
const lay = L.layout(peers, 560, 420, 60);
const f = lay.frame;

ok("jellyfish below the surface", f.jelly.y - f.jelly.r > f.surfaceY);
eq("jellyfish at the top centre", f.jelly.x, 280);
ok("every peer placed", peers.every(q => lay.peers[q.id]));
const ring = id => lay.peers[id].ring;
ok("one ring per latency band: near, middle, far", ring("a") === 0 && ring("b") === 0 && ring("c") === 1 && ring("d") === 2);
// The rings open wider than deep: the near ring reaches further sideways
// than down, so near peers spread instead of stacking under you
const ring0 = [L.fanPoint(f, 0, f.fan.rings[0]), L.fanPoint(f, 90, f.fan.rings[0])];
ok("the near ring spreads wider than it hangs deep", (ring0[0].x - f.fan.x) / f.fan.rx > (ring0[1].y - f.fan.y) / f.fan.ry);
ok("rings stay nested in every direction", [0, 30, 60, 90, 120, 150, 180].every(d => {
    const q = f.fan.rings.map(rho => L.fanPoint(f, d, rho));
    const dist = q.map(p => Math.hypot(p.x - f.fan.x, p.y - f.fan.y));
    return dist[0] < dist[1] && dist[1] < dist[2];
}));
eq("rings by latency", [L.ringOf(4), L.ringOf(14.9), L.ringOf(15), L.ringOf(79), L.ringOf(80), L.ringOf(300)], [0, 0, 1, 1, 2, 2]);
ok("living peers hang between the bell and the floor", ["a", "b", "c", "d"].every(id => lay.peers[id].y > f.jelly.y && lay.peers[id].y < f.floorY - 40));
ok("on its ring, the first thing hangs nearest the middle", Math.abs(lay.peers.a.x - f.jelly.x) <= Math.abs(lay.peers.b.x - f.jelly.x) + 1e-9);
ok("the most important hangs nearest straight below you", ["b", "c", "d"].every(id => Math.abs(lay.peers.a.x - f.jelly.x) <= Math.abs(lay.peers[id].x - f.jelly.x) + 1e-9));
ok("alone in the deep: straight below you", Math.abs(L.layout([p("solo", 30)], 580, 480, 54).peers.solo.x - 290) < 1e-9);
// A few things spread over the fan instead of stacking in the middle
const trio = L.layout([p("n", 4), p("m", 40), p("x", 150)], 580, 480, 54);
const xs = ["n", "m", "x"].map(id => trio.peers[id].x).sort((a, b) => a - b);
ok("three things on three rings do not stack: each has its own direction", xs[1] - xs[0] > 90 && xs[2] - xs[1] > 90);
ok("they use the width: one on each side of you", xs[0] < 290 - 90 && xs[2] > 290 + 90);
const dirs = (l) => Object.keys(l.peers).filter(id => !l.peers[id].floor).map(id => ({ "deg": Math.atan2((l.peers[id].y - l.frame.fan.y) / l.frame.fan.ry, (l.peers[id].x - l.frame.fan.x) / l.frame.fan.rx) * 180 / Math.PI, "ring": l.peers[id].ring }));
const five = L.layout([p("a", 4), p("b", 12), p("c", 40), p("d", 150), p("e", 30)], 580, 480, 54);
ok("five: no tentacle hangs over another thing (other rings, other directions)", dirs(five).every((a, i, all) => all.every((b, j) => i === j || a.ring === b.ring || Math.abs(a.deg - b.deg) >= 14 - 1e-6)));
ok("peers inside the scene", peers.every(q => lay.peers[q.id].x < 560 && lay.peers[q.id].x > 0));
eq("offline peers rest on the floor", [lay.peers.e.floor, lay.peers.f.floor, lay.peers.e.y], [true, true, f.floorY - 30]);
ok("a relay lantern for relay-eu", !!lay.relays["relay-eu"]);
// Distance from the fan's centre (the lantern sits between you and its peers)
const far = q => Math.hypot(q.x - f.fan.x, q.y - f.fan.y);
const lf = far(lay.relays["relay-eu"]);
ok("the lantern sits on the way to its peers", lf < far(lay.peers.c) && lf < far(lay.peers.d));
eq("no lantern for unused relays", Object.keys(lay.relays), ["relay-eu"]);

// The fan: the most important in the middle, the others alternately around it
const a5 = L.fanAngles(5);
eq("five on the fan: middle first", a5[0], 90);
ok("…then either side, within the fan", a5.every(a => a >= 15 && a <= 165) && new Set(a5).size === 5);
ok("…a label apart", L.fanAngles(3, 30)[1] - L.fanAngles(3, 30)[0] === 30);
ok("…symmetric", Math.abs(a5[1] + a5[2] - 180) < 1e-9 && Math.abs(a5[3] + a5[4] - 180) < 1e-9);
eq("one alone hangs straight down", L.fanAngles(1), [90]);

// A full ring passes the less important ones outward
const packed = [];
for (let i = 0; i < 9; i++) packed.push(p("m" + i, 3));
const ln = L.layout(packed, 640, 560, 54);
ok("a full near ring overflows outward", ln.peers.m0.ring === 0 && packed.some(q => ln.peers[q.id].ring > 0));

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
const ten = [];
for (let i = 0; i < 10; i++) ten.push(p("t" + i, 5 + i * 30));
const l10 = L.layout(ten, 640, 560, 54);
let close = 0;
for (let i = 0; i < 10; i++) for (let j = i + 1; j < 10; j++) {
    const a = l10.peers["t" + i], b = l10.peers["t" + j];
    if (Math.abs(a.x - b.x) < 80 && Math.abs(a.y - b.y) < 56) close++;
}
eq("ten things in the popout: labels apart", close, 0);
eq("a single peer is centred", L.layout([p("x", 5)], 560, 420, 60).peers.x.x, 280);
ok("caves left of the resting peers", L.caveX(f, 1) < lay.peers.e.x);
const asleep = L.layout(peers.map(q => Object.assign({}, q, { online: false })), 560, 420, 60);
ok("disconnected: resting peers spread over the floor", asleep.peers.a.x < lay.peers.e.x);
const many = [];
for (let i = 0; i < 10; i++) many.push(p("s" + i, 0));
const lt = L.layout(many, 560, 420, 60);
ok("a crowd rests on two rows", lt.peers.s0.y !== lt.peers.s1.y);
ok("a few rest on one row", asleep.peers.a.y === asleep.peers.b.y);
eq("empty mesh", Object.keys(L.layout([], 560, 420, 60).peers).length, 0);

// Tentacles
const t = L.tentacle([10, 10], [300, 200], null);
eq("starts at the rim", t[0], [10, 10]);
ok("ends just before the peer", Math.abs(Math.hypot(300 - t[t.length - 1][0], 200 - t[t.length - 1][1]) - 18) < 1e-6);
ok("leaves hanging down", t[1][1] - t[0][1] > Math.abs(t[1][0] - t[0][0]));
// How far a tentacle strays from the straight line between its two ends, as a
// share of that line: a tentacle hangs, it does not wander across the fan.
// Measured at 21 % for the worst lane (a far off-axis target); the bound keeps
// a future change from turning the curve into a sweep (P60, P60's lesson).
function _offLane(pts, a, b) {
    const len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1;
    let worst = 0;
    for (let i = 0; i < pts.length; i++) {
        const u = i / (pts.length - 1);
        worst = Math.max(worst, Math.hypot(pts[i][0] - (a[0] + (b[0] - a[0]) * u), pts[i][1] - (a[1] + (b[1] - a[1]) * u)));
    }
    return worst / len;
}
[[[290, 126], [460, 250]], [[290, 126], [120, 250]], [[290, 126], [290, 330]],
    [[290, 126], [520, 180]], [[290, 126], [60, 180]]].forEach(c => {
    ok("a tentacle hangs near its own line (" + c[0] + " to " + c[1] + "): "
        + (_offLane(L.tentacle(c[0], c[1], null), c[0], c[1]) * 100).toFixed(1) + " %",
    _offLane(L.tentacle(c[0], c[1], null), c[0], c[1]) <= 0.22);
});
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

// The group bubble: members on rings, all inside, never on top of each other
[1, 2, 5, 7, 8, 12, 18, 19, 24].forEach(n => {
    const s = L.ringSpots(n, 160);
    let minD = Infinity;
    for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) minD = Math.min(minD, Math.hypot(s[i].x - s[j].x, s[i].y - s[j].y));
    ok("bubble of " + n + ": all placed, inside, apart", s.length === n && s.every(q => Math.hypot(q.x, q.y) <= 160 * 0.73) && minD > 30);
});
const top4 = L.ringSpots(4, 100)[0];
ok("a few sit on one ring, the first at the top", Math.abs(top4.x) < 1e-9 && top4.y === -52);

// The magnetic lens
const spots = { a: { x: 100, y: 100 }, b: { x: 140, y: 100 }, c: { x: 400, y: 300 } };
eq("lens aims at the nearest in the real water", L.lensFocus(spots, 112, 102, 120, ""), "a");
eq("…keeps its aim unless another is clearly nearer", L.lensFocus(spots, 122, 100, 120, "a"), "a");
eq("…and switches when it is", L.lensFocus(spots, 136, 100, 120, "a"), "b");
eq("nothing within reach: no focus", L.lensFocus(spots, 250, 20, 60, ""), "");
const still = L.lensed(100, 100, 100, 100, 150, 1.6);
ok("the focused spot stays still and grows", still.x === 100 && still.y === 100 && still.s > 1);
const pushed = L.lensed(140, 100, 100, 100, 150, 1.6);
ok("neighbours move aside", pushed.x > 140 && pushed.y === 100);
eq("outside the lens nothing moves", L.lensed(400, 300, 100, 100, 150, 1.6), { x: 400, y: 300, s: 1 });
ok("waves follow the tentacle", Math.abs(L.angleAt([[0, 0], [10, 10], [20, 20]], 0.5) - 45) < 0.01);

// Soft magnet: pulled toward a near item, never beyond it, and continuous
const one = { a: { x: 100, y: 100 } };
const near = L.lensCentre(one, 90, 100, 60);
ok("the lens leans toward a near item", near.x > 90 && near.x < 100);
eq("far items do not pull", L.lensCentre(one, 300, 100, 60), { x: 300, y: 100 });
const two = { a: { x: 100, y: 100 }, b: { x: 140, y: 100 } };
const l = L.lensCentre(two, 119.9, 100, 60).x, r = L.lensCentre(two, 120.1, 100, 60).x;
ok("no jump when the nearest item changes", Math.abs(r - l) < 1);

{
    // From a cave on the floor up to a peer high on the right, and to one
    // almost level with it: the thread climbs, never dips under the mouth
    const up = L.thread([60, 400], [300, 150]), side = L.thread([60, 400], [320, 380]);
    ok("a cave thread never dips below its cave", up.concat(side).every(q => q[1] <= 400.5));
    ok("a cave thread ends just short of its peer", Math.hypot(up[up.length - 1][0] - 300, up[up.length - 1][1] - 150) < 20);
}
ok("ribbons widen with traffic", L.ribbonWidth(0.5) > L.ribbonWidth(0.2) && L.ribbonWidth(1) > L.ribbonWidth(0.5));
// Everyday traffic (1 to 10 Mb/s) stays a thread; the heaviest only a few px
ok("idle is a thread, full load stays thin", L.ribbonWidth(0) <= 1 && L.ribbonWidth(1) <= 5.5);
ok("everyday traffic is fine", L.ribbonWidth(M.level(1e6)) < 1.5 && L.ribbonWidth(M.level(1e7)) < 3);

// A reshuffle of importance keeps everyone on their side: nothing swims
// across the middle, and the fan stays as evenly spread as before
{
    const five = ["v", "w", "x", "y", "z"].map((id, i) => p(id, [4, 30, 150][i % 3]));
    const a = L.layout(five, 900, 560, 60);
    const prev = {};
    Object.keys(a.peers).forEach(id => prev[id] = a.peers[id].deg);
    const b = L.layout(five.slice().reverse(), 900, 560, 60, null, prev);
    ok("reordered things keep their places", five.every(q => Math.abs(b.peers[q.id].deg - a.peers[q.id].deg) < 0.01));
    const c = L.layout(five.slice().reverse(), 900, 560, 60);
    ok("without memory the order moves them", five.some(q => Math.abs(c.peers[q.id].deg - a.peers[q.id].deg) > 1));
    const d = L.layout(five.concat([p("n", 4)]), 900, 560, 60, null, prev);
    const order = ids => ids.slice().sort((i, j) => (d.peers[i] || a.peers[i]).deg - (d.peers[j] || a.peers[j]).deg);
    const before = Object.keys(prev).sort((i, j) => prev[i] - prev[j]);
    ok("a newcomer never makes the others swap sides", JSON.stringify(order(before)) === JSON.stringify(before));
}

// Nothing hangs on a cave's label (the caves sit on the floor, on the left)
{
    const six = ["a1", "a2", "a3", "a4"].map(id => p(id, 150));
    const g = L.layout(six, 646, 420, 60, { "caves": 2 });
    const clear = Object.keys(g.peers).every(id => [0, 1].every(c => Math.abs(g.peers[id].x - L.caveX(g.frame, c)) >= 88 || Math.abs(g.peers[id].y - (g.frame.floorY - 70)) >= 60));
    ok("the fan keeps clear of the caves' labels", clear);
}

// Nothing in the way (P60)("components/DemoMesh.js");
const G = load("components/Groups.js");
const T0 = 1700000000000;
const D = load("components/DemoMesh.js");
// The user's own groups, as they are in the settings today
const MINE = [
    { "id": "u1", "name": "Busy", "members": ["demo-atlas-server", "demo-nook-nas", "demo-juniper-laptop"] },
    { "id": "u2", "name": "Quiet", "members": ["demo-kestrel-phone", "demo-tern-vps", "demo-pi-garden"] }
];

// A mesh read twice, ten seconds apart, so the traffic (and with it the order
// of importance) is the demo's usual one
function _counters(profile, t) {
    const c = {};
    D.status(profile, T0, true, {}, {}, null).peers.details.forEach(d => {
        const name = d.fqdn.split(".")[0], rate = D.baseRate(profile, name) * 1e6;
        c[name] = { "rx": Math.round(rate * 0.62 * t), "tx": Math.round(rate * 0.38 * t) };
    });
    return c;
}

function _view(profile) {
    const first = M.parse("Connected", D.status(profile, T0, true, _counters(profile, 0), {}, null), null, null, T0);
    return M.parse("Connected", D.status(profile, T0 + 10000, true, _counters(profile, 10), {}, null), first, T0 + 10000);
}

// The scene's own path to the layout: what you see is grouped first, then
// each item becomes a peer for the fan (a shoal floats at the median depth of
// its members, behind a relay only when all of them share it)
function _scene(profile, maxItems, mine) {
    const view = _view(profile);
    const arr = G.view(view.peers, maxItems, [], { "favorites": {}, "mine": mine || [], "broken": [], "memo": {} });
    const items = arr.items.map(it => {
        if (it.type === "peer")
            return Object.assign({}, view.peers.find(p => p.id === it.peerId), { "id": it.id });
        const ms = it.members.map(id => view.peers.find(p => p.id === id)).filter(p => p && p.online);
        const lat = ms.map(p => p.latencyMs).sort((a, b) => a - b);
        const via = ms.length && ms.every(p => p.relayed && p.relay === ms[0].relay) ? ms[0].relay : "";
        return { "id": it.id, "online": !it.asleep && !it.fog && ms.length > 0, "latencyMs": lat.length ? lat[lat.length >> 1] : 0, "relayed": via !== "", "relay": via };
    });
    return { "view": view, "items": items, "arr": arr };
}

// The tentacles as the scene draws them: a loose leg under each direction,
// then the path down to the creature, through its relay when it has one
function _paths(l, items) {
    const j = l.frame.jelly;
    const live = items.filter(p => l.peers[p.id] && l.peers[p.id].deg !== undefined);
    live.sort((a, b) => Math.atan2(l.peers[b.id].y - j.y, l.peers[b.id].x - j.x) - Math.atan2(l.peers[a.id].y - j.y, l.peers[a.id].x - j.x));
    const slots = L.legSlots(j, live.map(p => l.peers[p.id].x));
    return live.map((p, i) => {
        const q = l.peers[p.id], via = p.relayed ? l.relays[p.relay] : null;
        const start = slots ? L.legPoint(j, slots[i]) : L.rimPoint(j, i, live.length);
        return { "id": p.id, "relay": via ? p.relay : "", "pts": L.tentacle(start, [q.x, q.y], via ? [via.x, via.y] : null) };
    });
}

function _inBox(pts, x, y, w, h) {
    return pts.some(q => Math.abs(q[0] - x) < w / 2 && Math.abs(q[1] - y) < h / 2);
}

// size: the popout (580x480), the Control Center (440x420) and the bowl
// (646x420, two caves). max: the setting "Things on screen" (3, 5, 10).
// "lab:n": the test lab's mesh of n peers, from one peer to its maximum
const LAB = [1, 2, 12, 60, 120].flatMap(n => [3, 5, 10].map(max => ["lab:" + n, 580, 480, 54, null, max]))
    .concat([["lab:24", 440, 420, 50, null, 5], ["lab:24", 646, 420, 60, { "caves": 2 }, 5]]);
[["home", 580, 480, 54, null, 5], ["work", 580, 480, 54, null, 5], ["crowd", 580, 480, 54, null, 5],
    ["home", 440, 420, 50, null, 5], ["crowd", 646, 420, 60, { "caves": 2 }, 5],
    ["crowd", 580, 480, 54, null, 10], ["crowd", 580, 480, 54, null, 3]].concat(LAB).forEach(c => {
    const m = c.slice();
    if (m[0].indexOf("lab:") === 0) {
        D.setLab(Number(m[0].slice(4)));
        m[0] = "lab";
    }
    const s = _scene(m[0], m[5], MINE), l = L.layout(s.items, m[1], m[2], m[3], m[4]);
    const paths = _paths(l, s.items);
    const ids = Object.keys(l.peers).filter(id => l.peers[id].deg !== undefined);
    const over = [];
    paths.forEach(p => ids.forEach(id => {
        const q = l.peers[id];
        if (id === p.id)
            return;
        if (_inBox(p.pts, q.x, q.y, L.BODY_W, L.BODY_H))
            over.push(p.id + " over the body of " + id);
        else if (_inBox(p.pts, q.x, q.y + L.LABEL_DY, L.LABEL_W, L.LABEL_H))
            over.push(p.id + " over the name of " + id);
    }));
    // A tentacle goes through its own relay on purpose, and through nothing else
    Object.keys(l.relays).forEach(n => paths.forEach(p => {
        if (n !== p.relay && _inBox(p.pts, l.relays[n].x, l.relays[n].y, L.HUB_W, L.HUB_H))
            over.push(p.id + " over the lantern " + n);
    }));
    ok(c[0] + " " + m[1] + "x" + m[2] + " max " + m[5] + ": nothing in the way of a tentacle ("
        + over.length + (over.length ? ": " + over.join(", ") : "") + ")", over.length === 0);
    const sat = [];
    Object.keys(l.relays).forEach(n => ids.forEach(id => {
        if (_inBox([[l.relays[n].x, l.relays[n].y]], l.peers[id].x, l.peers[id].y, L.BODY_W, L.BODY_H))
            sat.push(n + " on " + id);
    }));
    ok(c[0] + " " + m[1] + "x" + m[2] + " max " + m[5] + ": no lantern on a creature ("
        + sat.length + (sat.length ? ": " + sat.join(", ") : "") + ")", sat.length === 0);
});

// Dozing peers (lazy connections) float above the floor; asleep ones rest on it
{
    const items = [{ "id": "a", "online": true, "latencyMs": 10 }, { "id": "z", "online": false }, { "id": "d", "online": false, "dozing": true }];
    const l = L.layout(items, 580, 480, 54, null);
    ok("a dozing peer floats, an asleep one rests", !l.peers.d.floor && l.peers.z.floor && l.peers.d.y < l.peers.z.y - 40);
}

done("layout");
