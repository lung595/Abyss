.pragma library

// Where everything sits in the deep, from the view model and the scene size.
// Pure functions only, tested with gjs in tests/.
//
// The idea: a sonar. You are the jellyfish at the top centre, just below the
// surface; the things shown hang below you on three rings, like sonar pings:
// near (under 15 ms), middle (under 80 ms) and far. On each ring they sit at
// even steps, the most important in the middle, so nothing ever overlaps.
// Tentacles fall from the bell and never cross; a relayed peer is reached
// through a coral lantern (its relay) on the way. Offline peers rest on the
// sea floor, on the right; networks are caves on the left of the floor.

.import "Mesh.js" as Mesh

// inset: {top, floor, caves}: how far in from each side things at the surface
// and on the floor must stay (the desktop bowl narrows there; 0 elsewhere),
// and how many caves sit on the floor (the fan keeps clear of their labels)
function frame(w, h, top, inset) {
    const surfaceY = top;
    const floorY = h - Math.max(34, h * 0.09);
    const r = Math.max(26, Math.min(w, h) * 0.08);
    const jelly = { "x": w / 2, "y": surfaceY + r + 22, "r": r };
    return {
        "w": w,
        "h": h,
        "surfaceY": surfaceY,
        "floorY": floorY,
        "insetTop": inset ? inset.top || 0 : 0,
        "insetFloor": inset ? inset.floor || 0 : 0,
        "caves": inset ? inset.caves || 0 : 0,
        "jelly": jelly,
        // The fan: an ellipse around the bell's rim; rho 0 is the rim, rho 1
        // the far ring, just above the resting peers
        "fan": {
            "x": jelly.x,
            "y": jelly.y + r * 0.3,
            "rx": Math.max(80, w / 2 - 62),
            "ry": Math.max(80, floorY - 96 - jelly.y - r * 0.3),
            "rings": [0.48, 0.74, 1]
        },
        // the band where living peers float (the disconnected message sits in it)
        "bandTop": surfaceY + 44,
        "bandBottom": floorY - 70
    };
}

// The sea floor's gentle line at x (Water.qml draws it, the reef grows on it)
function floorAt(frame, x) {
    return frame.floorY + 4 + Math.sin(x * 0.021) * 6 + Math.sin(x * 0.08) * 2;
}

// The sonar rings: the latency limits of the near and middle rings (ms)
const RING_MS = [15, 80];
function ringOf(ms) {
    return ms < RING_MS[0] ? 0 : ms < RING_MS[1] ? 1 : 2;
}

// A point of the fan: angle in degrees (0 = right, 90 = straight down), rho 0..1.
// The inner rings open wider than they are deep: near peers keep their
// depth but use the sides instead of stacking in a column under you. Linear,
// so the rings stay evenly apart at the sides too (room for a creature).
function _wide(rho) {
    return 0.28 + 0.72 * rho;
}
function fanPoint(frame, deg, rho) {
    const a = deg * Math.PI / 180, f = frame.fan;
    return { "x": f.x + Math.cos(a) * f.rx * _wide(rho), "y": f.y + Math.sin(a) * f.ry * rho };
}

// The widest part of the fan, in degrees either side of straight down
const HALF_SPAN = 75;
// Room for one label on a ring
const LABEL_GAP = 104;

// The angle between two neighbours on ring k: a label's width apart
function ringStep(frame, k) {
    const f = frame.fan, R = (_wide(f.rings[k]) * f.rx + f.rings[k] * f.ry) / 2;
    return Math.min(38, LABEL_GAP / R * 180 / Math.PI);
}
function ringRoom(frame, k) {
    return 1 + Math.floor(2 * HALF_SPAN / ringStep(frame, k));
}

// The angles of n things on a ring, filled from the middle outward (the
// first, the most important, hangs straight below you when n is odd) and
// squeezed only when the ring is overfull
function fanAngles(n, step) {
    const st = n > 1 ? Math.min(step || 38, 2 * HALF_SPAN / (n - 1)) : 0;
    const slots = [];
    for (let i = 0; i < n; i++)
        slots.push(90 + (i - (n - 1) / 2) * st);
    // middle, then alternately one step either side
    const mid = (n - 1) >> 1, order = [mid];
    for (let k = 1; order.length < n; k++) {
        if (mid + k < n)
            order.push(mid + k);
        if (mid - k >= 0 && order.length < n)
            order.push(mid - k);
    }
    return order.map(slot => slots[slot]);
}

// How wide a few things spread: 60° between neighbours, up to the whole fan
function spreadSpan(n) {
    return n > 1 ? Math.min(2 * HALF_SPAN, 60 * (n - 1)) : 0;
}

// Two placed things too close: their creature-and-label boxes touch, or one
// hangs in the way of the other's tentacle (same direction, other ring)
const BOX_W = 88, BOX_H = 60;
// A cave's label against a creature: the creature's box runs from its body
// down to the bottom of its tallest label (Creature.qml: label 26 px below
// the centre; "TOP CONSUMER", name and rates make it ~40 px tall), the cave's
// label from its hover height down to 52 px above the floor (Cave.qml: the
// cave sits 8 px below floorY, its label ends 60 px above it). Any
// peer may become the top consumer, so every one keeps that room (P124).
// Sideways, the top consumer's rates widen its pill: it keeps 100 px from a
// cave, not 88 (104 put a tentacle over a lantern in the lab demo).
const BODY_UP = 30, LABEL_DOWN = 66, CAVE_LABEL = [88, 52], CAVE_W = 100;
function _clash(a, b, strict) {
    if (a.cave || b.cave) {
        const c = a.cave ? a : b, q = a.cave ? b : a;
        return Math.abs(q.x - c.x) < CAVE_W && q.y + LABEL_DOWN > c.floorY - CAVE_LABEL[0] && q.y - BODY_UP < c.floorY - CAVE_LABEL[1];
    }
    if (Math.abs(a.x - b.x) < BOX_W && Math.abs(a.y - b.y) < BOX_H)
        return true;
    return strict && a.ring !== b.ring && Math.abs(a.deg - b.deg) < 14;
}

// The roomy arrangement, used whenever it fits: every thing gets its own
// direction, spread over the whole fan instead of stacked in the middle.
// The most important aims straight down, the next ones fan out either side;
// each stays on its ring, and one that would touch a neighbour slides to the
// nearest free direction. strict: no tentacle may pass behind another thing
// either. prev: {id: angle} of the last layout, see _keepOrder.
// Returns the placed things, or null if they cannot all get a place.
function spread(f, rings, strict, prev) {
    const order = [];
    rings.forEach((ps, k) => ps.forEach(p => order.push({ "p": p, "k": k })));
    // back to importance order
    order.sort((a, b) => a.p._rank - b.p._rank);
    const n = order.length, S = spreadSpan(n);
    const ideal = _keepOrder(order.map(o => o.p.id), fanAngles(n, n > 1 ? S / (n - 1) : 0), prev);
    // The caves' labels are in the way too (never a tentacle clash: no ring)
    const caves = [];
    for (let c = 0; c < f.caves; c++)
        caves.push({ "x": caveX(f, c), "floorY": f.floorY, "cave": true, "ring": -1, "deg": 999 });
    const placed = caves.slice();
    for (let i = 0; i < n; i++) {
        const k = order[i].k, rho = f.fan.rings[k];
        const tries = [];
        for (let d = 90 - HALF_SPAN; d <= 90 + HALF_SPAN; d += 5)
            tries.push(d);
        tries.sort((a, b) => Math.abs(a - ideal[i]) - Math.abs(b - ideal[i]));
        const spot = tries.map(d => Object.assign({ "id": order[i].p.id, "deg": d, "rho": rho, "ring": k }, fanPoint(f, d, rho))).find(c => !placed.some(q => _clash(c, q, strict)));
        if (!spot)
            return null;
        placed.push(spot);
    }
    return placed.slice(caves.length);
}

// Traffic reorders things all the time (the busiest hangs in the middle): two
// neighbours of about the same weight would swap sides at every change and
// swim across the middle, and the fan would never settle. So the same even
// angles are handed out in the last layout's left-to-right order: nothing
// crosses, a newcomer takes the place its importance gives it among the
// others. ids and angles in importance order; prev: {id: angle} or null.
function _keepOrder(ids, angles, prev) {
    if (!prev)
        return angles;
    const want = ids.map((id, i) => prev[id] !== undefined ? prev[id] : angles[i]);
    const slots = angles.slice().sort((a, b) => a - b), out = [];
    ids.map((id, i) => i).sort((a, b) => want[a] - want[b] || a - b).forEach((i, j) => out[i] = slots[j]);
    return out;
}

// The crowded arrangement: each ring filled from the middle at a label's
// width apart; nothing overlaps, but things may hang one below the other
function pack(f, rings, prev) {
    const items = [];
    rings.forEach((ps, k) => {
        const angles = _keepOrder(ps.map(p => p.id), fanAngles(ps.length, ringStep(f, k)), prev);
        ps.forEach((p, i) => items.push(Object.assign({ "id": p.id, "deg": angles[i], "rho": f.fan.rings[k], "ring": k }, fanPoint(f, angles[i], f.fan.rings[k]))));
    });
    return items;
}

// A lantern needs its own water: off every creature, off the other
// lanterns, and off the tentacles it does not carry (P90). Its ideal place
// is tried first, then the nearest one around it that is clear; when none
// is, the one with the least in the way.
const LANTERN_W = 24, LANTERN_H = 22, LANTERN_ROPE = 28;
function _lantern(f, deg, rho, items, live, name, placed) {
    const j = f.jelly;
    // The ribbons it must keep off, drawn as the scene hangs them: from
    // the leg under their direction (legSlots, as AbyssScene picks it),
    // through their own lantern once it is placed
    const at = id => items.find(it => it.id === id);
    const order = live.slice().sort((a, b) => Math.atan2(at(b.id).y - j.y, at(b.id).x - j.x) - Math.atan2(at(a.id).y - j.y, at(a.id).x - j.x));
    const slots = legSlots(j, order.map(p => at(p.id).x));
    const ropes = [];
    order.forEach((p, i) => {
        if (p.relayed && p.relay === name)
            return;
        const it = at(p.id), via = p.relayed ? placed[p.relay] : null;
        const start = slots ? legPoint(j, slots[i]) : rimPoint(j, i, order.length);
        ropes.push(tentacle(start, [it.x, it.y], via ? [via.x, via.y] : null, 0));
    });
    const tries = [];
    // Nearest first, so a free spot close to the aim wins over a far one
    [0, -0.06, 0.06, -0.12, 0.12, -0.18, 0.18, 0.24, -0.24, 0.3, 0.36].forEach(dr => [0, -6, 6, -12, 12, -18, 18, -24, 24, -32, 32, -42, 42, -52, 52, -62, 62].forEach(dd => {
        if (rho + dr >= 0.12 && rho + dr <= 0.9)
            tries.push(fanPoint(f, deg + dd, rho + dr));
    }));
    const cost = c => {
        let n = 0;
        items.forEach(it => {
            const dx = Math.abs(c.x - it.x), dy = Math.abs(c.y - it.y);
            if (dx < BOX_W / 2 && dy < BOX_H / 2)
                n += 30;
            else if (dx < BOX_W / 2 + LANTERN_W && dy < BOX_H / 2 + LANTERN_H)
                n += 3;
        });
        Object.keys(placed).forEach(k => {
            if (Math.abs(c.x - placed[k].x) < 2 * LANTERN_W && Math.abs(c.y - placed[k].y) < 2 * LANTERN_H)
                n += 10;
        });
        ropes.forEach(pts => {
            // A rope through the lantern's own box swallows it: as bad as
            // sitting on a creature, worse than crowding another lantern
            if (pts.some(q => Math.abs(q[0] - c.x) < LANTERN_W && Math.abs(q[1] - c.y + 4) < LANTERN_H))
                return n += 30;
            for (let i = 1; i < pts.length; i++)
                if (_toSegment(c, { "x": pts[i - 1][0], "y": pts[i - 1][1] }, { "x": pts[i][0], "y": pts[i][1] }) < LANTERN_ROPE)
                    return n += 1;
        });
        return n;
    };
    let best = tries[0], bestCost = cost(best);
    for (let i = 1; i < tries.length && bestCost > 0; i++) {
        const c = cost(tries[i]);
        if (c < bestCost) {
            best = tries[i];
            bestCost = c;
        }
    }
    return best;
}

// Distance from point c to the segment a-b
function _toSegment(c, a, b) {
    const dx = b.x - a.x, dy = b.y - a.y, len = dx * dx + dy * dy;
    const t = len ? Math.max(0, Math.min(1, ((c.x - a.x) * dx + (c.y - a.y) * dy) / len)) : 0;
    return Math.hypot(c.x - a.x - t * dx, c.y - a.y - t * dy);
}

// How far above the floor a dozing peer floats
const DOZE_LIFT = 56;

// peers: the things shown (layout order = importance).
// prev: {id: angle} of the previous layout (its peers' `deg`), or null.
// Returns { frame, peers: {id: {x, y, floor, ring, deg}}, relays: {name: {x, y}} }
function layout(peers, w, h, top, inset, prev) {
    const f = frame(w, h, top, inset);
    const out = { "frame": f, "peers": {}, "relays": {} };
    const live = peers.filter(p => p.online).map((p, i) => Object.assign({}, p, { "_rank": i }));
    const rest = peers.filter(p => !p.online);
    // Each thing on its latency's ring; a full ring passes the less
    // important ones to the next ring out (then in); if all are full, the
    // roomiest ring takes it and squeezes
    const rings = [[], [], []], room = [0, 1, 2].map(k => ringRoom(f, k));
    live.forEach(p => {
        const want = ringOf(p.latencyMs);
        const k = [want, want + 1, want - 1, want + 2, want - 2].filter(k => k >= 0 && k < 3).find(k => rings[k].length < room[k]);
        rings[k !== undefined ? k : [0, 1, 2].sort((a, b) => (rings[a].length - room[a]) - (rings[b].length - room[b]))[0]].push(p);
    });
    // Roomy with clear tentacles if possible, else roomy, else squeezed
    const items = spread(f, rings, true, prev) || spread(f, rings, false, prev) || pack(f, rings, prev);
    items.forEach(it => out.peers[it.id] = { "x": it.x, "y": it.y, "floor": false, "ring": it.ring, "deg": it.deg });
    // Relays: a lantern on the way to the peers it carries, at their mean angle
    const groups = {};
    items.forEach(it => {
        const p = live.find(q => q.id === it.id);
        if (p.relayed)
            (groups[p.relay] = groups[p.relay] || []).push(it);
    });
    const aim = {};
    Object.keys(groups).sort().forEach(name => {
        const g = groups[name];
        aim[name] = {
            "deg": g.reduce((s, it) => s + it.deg, 0) / g.length,
            "rho": Math.max(0.3, Math.min.apply(null, g.map(it => it.rho)) * 0.5)
        };
        out.relays[name] = _lantern(f, aim[name].deg, aim[name].rho, items, live, name, out.relays);
    });
    // Once more, now that every lantern is known: the first ones were placed
    // before the ribbons hanging through the later ones existed
    Object.keys(aim).sort().forEach(name => {
        const others = Object.assign({}, out.relays);
        delete others[name];
        out.relays[name] = _lantern(f, aim[name].deg, aim[name].rho, items, live, name, others);
    });
    // Offline peers rest on the right of the floor (the left is for caves);
    // with nobody online (disconnected) they use the whole floor, and a crowd
    // rests on two rows
    const m = rest.length;
    const fx0 = live.length ? w * 0.56 : f.insetFloor + 60, fx1 = w - f.insetFloor - 60;
    const twoRows = m > 1 && (fx1 - fx0) / (m - 1) < 70;
    // Dozing ones (NetBird's lazy connections: idle, they wake on use)
    // float a little above the floor instead of resting on it
    rest.forEach((p, i) => {
        out.peers[p.id] = {
            "x": m > 1 ? fx0 + (fx1 - fx0) * i / (m - 1) : (fx0 + fx1) / 2,
            "y": f.floorY - 30 - (twoRows && i % 2 ? 34 : 0) - (p.dozing ? DOZE_LIFT : 0),
            "floor": !p.dozing
        };
    });
    return out;
}

// Caves (networks reached through a peer) sit on the left of the floor
// A cave's thread leaves from the top of its label (Cave.qml: label above
// the rock, taller on hover), never through the text or the rock
const CAVE_TOP = 96;

function caveX(frame, i) {
    return frame.insetFloor + 64 + i * Math.max(96, (frame.w - 2 * frame.insetFloor) * 0.16);
}

// A tentacle from the jellyfish rim to a peer, optionally through a relay:
// cubic curves sampled into a polyline, so pulses can run along it. Each
// part leaves hanging down and arrives along its own line, stopping just
// before the creature.
function _bez(p0, p1, p2, p3, n) {
    const pts = [];
    for (let i = 0; i <= n; i++) {
        const t = i / n, u = 1 - t;
        pts.push([
            u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
            u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]
        ]);
    }
    return pts;
}

function _hang(a, b, stop, n) {
    const dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy) || 1;
    const e = [b[0] - dx / L * stop, b[1] - dy / L * stop];
    return _bez(a, [a[0], a[1] + L * 0.4], [e[0] - dx * 0.3, e[1] - dy * 0.3], e, n);
}

// stop: how far short of its end the ribbon lets go. A tentacle that grips
// its creature passes 0 and lets Grips.hold take over at the body.
function tentacle(start, end, via, stop) {
    const s = stop === undefined ? 18 : stop;
    if (via) {
        const a = _hang(start, via, 0, 14);
        return a.concat(_hang(via, end, s, 14).slice(1));
    }
    return _hang(start, end, s, 24);
}

// A cave's thread up to the peer that opens it: it rises straight out of
// the cave mouth and bends toward the peer, arriving a little short of it.
// Never dips below the mouth (a tentacle's curve hangs down; this one climbs).
function thread(mouth, peer) {
    const dx = peer[0] - mouth[0], dy = peer[1] - mouth[1], L = Math.hypot(dx, dy) || 1;
    const e = [peer[0] - dx / L * 16, peer[1] - dy / L * 16];
    const rise = Math.min(L * 0.45, Math.max(20, -dy * 0.6));
    return _bez(mouth, [mouth[0], mouth[1] - rise], [e[0] - dx * 0.25, e[1] + Math.abs(dy) * 0.2], e, 18);
}

// Where tentacle i of n leaves the bell (spread along the rim, in the order
// of their targets so tentacles do not cross)
function rimPoint(jelly, i, n) {
    const span = jelly.r * 1.3;
    return [jelly.x - span / 2 + span * (i + 0.5) / Math.max(1, n), jelly.y + jelly.r * 0.22];
}

// The jellyfish has LEGS threads along its rim. Alone, they all hang loose;
// each peer it reaches takes one over (its tentacle leaves from that slot),
// so with LEGS peers or more no loose thread is left.
const LEGS = 6;
function legPoint(jelly, k) {
    return rimPoint(jelly, k, LEGS);
}
// Which slot each of n tentacles leaves from, given where their targets are
// (x, sorted left to right): the slot under its direction, kept in order so
// tentacles never cross, and leaving room for the ones still to place.
// Returns slot indices, or null when there are more tentacles than slots
// (they then share the rim evenly: rimPoint).
function legSlots(jelly, xs) {
    const n = xs.length;
    if (n > LEGS)
        return null;
    const span = jelly.r * 1.3, out = [];
    let prev = -1;
    xs.forEach((x, i) => {
        // Far targets aim at the rim's ends: the direction, squeezed onto the rim
        const lean = Math.max(-1, Math.min(1, (x - jelly.x) / Math.max(1, jelly.r * 3)));
        const want = Math.round((lean + 1) / 2 * (LEGS - 1));
        const k = Math.min(LEGS - (n - i), Math.max(prev + 1, want));
        out.push(k);
        prev = k;
    });
    return out;
}

// Where the members of an open group sit in its bubble of radius R, around
// its centre: one ring for a few, two or three for more, each ring holding
// as many as its length allows, starting at the top. Returns [{x, y}].
function ringSpots(n, R) {
    if (n <= 0)
        return [];
    if (n === 1)
        return [{ "x": 0, "y": 0 }];
    const K = n <= 7 ? 1 : n <= 18 ? 2 : 3;
    const radii = [];
    for (let k = 1; k <= K; k++)
        radii.push(K === 1 ? R * 0.52 : R * 0.72 * k / K);
    const total = radii.reduce((s, r) => s + r, 0);
    const counts = radii.map(r => Math.round(n * r / total));
    counts[K - 1] += n - counts.reduce((s, c) => s + c, 0);
    const out = [];
    radii.forEach((r, k) => {
        const c = counts[k];
        for (let i = 0; i < c; i++) {
            const a = -Math.PI / 2 + (i + (k % 2) * 0.5) / c * Math.PI * 2;
            out.push({ "x": Math.cos(a) * r, "y": Math.sin(a) * r });
        }
    });
    return out;
}

function length(pts) {
    let L = 0;
    for (let i = 1; i < pts.length; i++)
        L += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    return L;
}

// Point at fraction f (0..1) of the way along a polyline
function pointAt(pts, f) {
    if (pts.length < 2)
        return pts[0] || [0, 0];
    let s = Math.max(0, Math.min(1, f)) * length(pts);
    for (let i = 1; i < pts.length; i++) {
        const d = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
        if (s <= d || i === pts.length - 1) {
            const k = d > 0 ? Math.min(1, s / d) : 0;
            return [pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * k, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * k];
        }
        s -= d;
    }
    return pts[pts.length - 1];
}

// The first fraction f of a polyline (tentacles grow out when connecting)
function head(pts, f) {
    if (f >= 1)
        return pts;
    const n = Math.max(2, Math.round(pts.length * Math.max(0, f)));
    return pts.slice(0, n);
}

// Direction of a polyline at fraction f, in degrees (for the light waves
// that run along a tentacle)
function angleAt(pts, f) {
    const a = pointAt(pts, Math.max(0, f - 0.02)), b = pointAt(pts, Math.min(1, f + 0.02));
    return Math.atan2(b[1] - a[1], b[0] - a[0]) * 180 / Math.PI;
}

// --- The magnetic lens ------------------------------------------------------
// A fish-eye centred on the pointer pushes away what you aim at: a thing d px
// from the pointer is drawn ~3 d away, so it flees as you approach. Instead
// the lens aims at the thing nearest the pointer in the real (unbent) water;
// that one stays still and only its neighbours move aside.

// spots: {id: {x, y}}; returns the id to focus, or "" (keeps `prev` unless
// another is clearly nearer, so the focus does not flicker between two)
function lensFocus(spots, px, py, radius, prev) {
    let best = "", bestD = radius, prevD = Infinity;
    Object.keys(spots).forEach(id => {
        const d = Math.hypot(spots[id].x - px, spots[id].y - py);
        if (id === prev)
            prevD = d;
        if (d < bestD) {
            bestD = d;
            best = id;
        }
    });
    if (prev && best && best !== prev && prevD < radius && bestD > prevD * 0.7)
        return prev;
    return best;
}

// Where the lens centre sits for a pointer at (px, py): a soft magnet. Each
// spot within `reach` pulls the centre toward it, harder the closer it is,
// so the aimed item slides under the glass without the lens ever jumping
// (a hard snap from item to item felt jerky). Continuous in the pointer.
function lensCentre(spots, px, py, reach) {
    let sx = 0, sy = 0, sw = 0;
    Object.keys(spots).forEach(id => {
        const dx = spots[id].x - px, dy = spots[id].y - py;
        const f = 1 - Math.hypot(dx, dy) / reach;
        if (f <= 0)
            return;
        const w = f * f;
        sx += w * dx;
        sy += w * dy;
        sw += w;
    });
    return { "x": px + sx / (1 + sw), "y": py + sy / (1 + sw) };
}

// Where a spot is drawn under a lens at (cx, cy): pushed out from the centre
// (k = strength, 0 = none) and scaled up near it. Returns {x, y, s}.
function lensed(x, y, cx, cy, radius, k) {
    const vx = x - cx, vy = y - cy, d = Math.hypot(vx, vy);
    if (d >= radius || k <= 0)
        return { "x": x, "y": y, "s": 1 };
    // Up to ×1.9 at the centre (default strength): creatures are small at
    // rest, the lens is what brings them close
    const s = 1 + 0.9 * k / 1.6 * (1 - d / radius);
    if (d === 0)
        return { "x": x, "y": y, "s": s };
    const u = d / radius, nd = radius * (k + 1) * u / (k * u + 1);
    return { "x": cx + vx / d * nd, "y": cy + vy / d * nd, "s": s };
}

// Ribbon width from a traffic level (0..1): a thread for everyday use, a
// few pixels at full load (thin lines keep the deep readable)
function ribbonWidth(lv) {
    return 0.8 + 4.2 * lv * lv * lv;
}
