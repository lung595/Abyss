.pragma library

// Where everything sits in the deep, from the view model and the scene size.
// Pure functions only, tested with gjs in tests/.
//
// The idea: you are the jellyfish on the left, just below the surface. Each
// online peer floats at a depth set by its latency (deeper = slower); a
// relayed peer is reached through a coral lantern (its relay). Offline peers
// rest on the sea floor.

.import "Mesh.js" as Mesh

function frame(w, h, top) {
    const surfaceY = top;
    const floorY = h - Math.max(34, h * 0.09);
    const r = Math.max(34, Math.min(w, h) * 0.105);
    return {
        "w": w,
        "h": h,
        "surfaceY": surfaceY,
        "floorY": floorY,
        "jelly": { "x": Math.max(r + 18, w * 0.15), "y": surfaceY + r * 1.15 + 46, "r": r },
        // the band where living peers float
        "bandTop": surfaceY + 44,
        "bandBottom": floorY - 70
    };
}

// Keep two labels from sitting on each other: push the later one down (or up
// when it would leave the band). A few passes are enough for a few dozen peers.
function _relax(items, minDx, minDy, lo, hi) {
    for (let pass = 0; pass < 12; pass++) {
        let moved = false;
        for (let i = 0; i < items.length; i++)
            for (let j = i + 1; j < items.length; j++) {
                const a = items[i], b = items[j];
                if (Math.abs(a.x - b.x) >= minDx || Math.abs(a.y - b.y) >= minDy)
                    continue;
                const push = (minDy - Math.abs(a.y - b.y)) / 2 + 1;
                if (a.y <= b.y) {
                    a.y -= push;
                    b.y += push;
                } else {
                    a.y += push;
                    b.y -= push;
                }
                a.y = Math.max(lo, Math.min(hi, a.y));
                b.y = Math.max(lo, Math.min(hi, b.y));
                moved = true;
            }
        if (!moved)
            break;
    }
}

// peers: the view's peers already filtered for display.
// Returns { frame, peers: {id: {x, y, floor}}, relays: {name: {x, y}} }
function layout(peers, w, h, top) {
    const f = frame(w, h, top);
    const out = { "frame": f, "peers": {}, "relays": {} };
    const live = peers.filter(p => p.online);
    const rest = peers.filter(p => !p.online);
    const x0 = f.jelly.x + f.jelly.r * 1.9, x1 = w - 58;
    const n = live.length;
    const items = live.map((p, i) => ({
        "id": p.id,
        "x": n > 1 ? x0 + (x1 - x0) * i / (n - 1) : (x0 + x1) / 2,
        "y": f.bandTop + Mesh.depthOf(p.latencyMs) * (f.bandBottom - f.bandTop)
    }));
    const minDx = Math.min(92, (x1 - x0) / Math.max(1, n - 1) * 1.6);
    _relax(items, minDx, 74, f.bandTop, f.bandBottom);
    items.forEach(it => out.peers[it.id] = { "x": it.x, "y": it.y, "floor": false });
    // Relays: a lantern between you and the peers it carries
    const groups = {};
    live.forEach(p => {
        if (p.relayed)
            (groups[p.relay] = groups[p.relay] || []).push(out.peers[p.id]);
    });
    Object.keys(groups).sort().forEach((name, k) => {
        const g = groups[name];
        const minX = Math.min.apply(null, g.map(q => q.x));
        const avgY = g.reduce((s, q) => s + q.y, 0) / g.length;
        out.relays[name] = {
            "x": Math.max(f.jelly.x + f.jelly.r * 1.6, Math.min(minX - 70, f.jelly.x + f.jelly.r * 2.2 + k * 60)),
            "y": Math.max(f.bandTop + 20, Math.min(f.bandBottom - 40, f.jelly.y + (avgY - f.jelly.y) * 0.55 + k * 34))
        };
    });
    // Offline peers rest on the right of the floor (the left is for caves);
    // with nobody online (disconnected) they use the whole floor, and a crowd
    // rests on two rows
    const m = rest.length;
    const fx0 = n ? Math.max(f.jelly.x + f.jelly.r * 1.2, w * 0.5) : f.jelly.x + f.jelly.r * 1.4, fx1 = w - 60;
    const twoRows = m > 1 && (fx1 - fx0) / (m - 1) < 70;
    rest.forEach((p, i) => {
        out.peers[p.id] = {
            "x": m > 1 ? fx0 + (fx1 - fx0) * i / (m - 1) : (fx0 + fx1) / 2,
            "y": f.floorY - 30 - (twoRows && i % 2 ? 34 : 0),
            "floor": true
        };
    });
    return out;
}

// Caves (networks reached through a peer) sit on the left of the floor
function caveX(frame, i) {
    return frame.jelly.x + frame.jelly.r * 0.2 + i * Math.max(96, frame.w * 0.16);
}

// A tentacle from the jellyfish rim to a peer, optionally through a relay:
// cubic curves sampled into a polyline, so pulses can run along it.
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

function tentacle(start, end, via) {
    if (via) {
        const a = _bez(start, [start[0] + 8, start[1] + 80], [via[0] - 90, via[1] + 10], via, 16);
        const b = _bez(via, [via[0] + 50, via[1] - 6], [end[0] - 60, end[1] + 16], [end[0] - 16, end[1]], 12);
        return a.concat(b.slice(1));
    }
    return _bez(start, [start[0] + 16, start[1] + 96], [end[0] - 130, end[1]], [end[0] - 18, end[1]], 24);
}

// Where tentacle i of n leaves the bell (spread along the rim, in the order
// of their targets so tentacles do not cross)
function rimPoint(jelly, i, n) {
    const span = jelly.r * 1.3;
    return [jelly.x - span / 2 + span * (i + 0.5) / Math.max(1, n), jelly.y + jelly.r * 0.22];
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
