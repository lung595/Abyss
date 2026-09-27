.pragma library

// What the deep shows when there are more peers than places: never more than
// `max` things on screen. Pure functions only, tested with gjs in tests/.
//
// The idea: a few peers stay alone (the ones in trouble, the heavy users and
// the favourites); everyone else joins a group formed by whichever criterion
// sorts them most clearly right now (species, route, distance or activity).
// A group opens by itself as a bubble when the pointer rests on it (the scene
// does that); nothing here changes then.

// Total traffic of a peer, in bits per second: its calm average when the
// source keeps one (Mesh.follow), so a burst never reshuffles the groups
function total(p) {
    return p.measured ? p.calm || 0 : (p.down || 0) + (p.up || 0);
}
// Latency for grouping: the steady value, so jitter never moves a peer
function _ms(p) {
    return p.steadyMs !== undefined ? p.steadyMs : p.latencyMs;
}

const KIND_NAMES = {
    "phone": ["phone", "phones"],
    "laptop": ["laptop", "laptops"],
    "desktop": ["desktop", "desktops"],
    "server": ["server", "servers"],
    "vps": ["VPS", "VPS"],
    "nas": ["NAS", "NAS"],
    "pi": ["Pi", "Pis"]
};

// Ways peers can belong together: a bucket key per peer and a label per bucket
const CRITERIA = [
    {
        "id": "kind",
        "of": p => p.kind,
        "label": (k, n) => n + " " + (KIND_NAMES[k] || [k, k])[n > 1 ? 1 : 0]
    },
    {
        "id": "route",
        "of": p => p.relayed ? p.relay : "direct",
        "label": (k, n) => k === "direct" ? n + " direct" : n + " via " + k
    },
    {
        "id": "distance",
        "of": p => _ms(p) < 20 ? "near" : _ms(p) <= 100 ? "mid" : "far",
        "label": (k, n) => n + " " + ({
                "near": "near · < 20 ms",
                "mid": "mid-way",
                "far": "far · > 100 ms"
            })[k]
    },
    {
        "id": "activity",
        "of": p => total(p) > 1e6 ? "busy" : total(p) > 5e4 ? "light" : "idle",
        "label": (k, n) => n + " " + ({
                "busy": "busy",
                "light": "quiet",
                "idle": "idle"
            })[k]
    }
];

// A heavy user stands alone above this share of the traffic, and stays alone
// until it falls under the lower one (so it does not flicker in and out)
const STAR_SHARE = 0.2;
const STAR_KEEP = 0.12;
const STAR_MIN_BPS = 1e6;
// Another criterion must beat the current one by this much to replace it
const STICKY = 0.12;

// Splits peers into at most `slots` buckets by one criterion. The smallest
// buckets merge into "misc" when there are too many. The score rewards peers
// in clearly named groups and punishes the misc pile and groups of one.
function bucketize(peers, crit, slots) {
    const map = {}, order = [];
    peers.forEach(p => {
        const k = String(crit.of(p));
        if (!map[k]) {
            map[k] = [];
            order.push(k);
        }
        map[k].push(p);
    });
    let buckets = order.map(k => ({ "k": k, "members": map[k] })).sort((a, b) => b.members.length - a.members.length || (a.k < b.k ? -1 : 1));
    let misc = [];
    if (buckets.length > slots) {
        buckets.slice(slots - 1).forEach(b => misc = misc.concat(b.members));
        buckets = buckets.slice(0, slots - 1);
    }
    const groups = buckets.map(b => ({ "crit": crit, "k": b.k, "members": b.members }));
    if (misc.length)
        groups.push({ "crit": crit, "k": "misc", "members": misc });
    const named = groups.filter(g => g.k !== "misc").reduce((a, g) => a + g.members.length, 0);
    let score = named / peers.length - 0.35 * misc.length / peers.length - 0.08 * groups.filter(g => g.members.length === 1).length;
    // A single group says nothing
    if (groups.length < 2)
        score -= 0.6;
    // Species is how people think of their devices: a small head start
    if (crit.id === "kind")
        score += 0.06;
    return { "groups": groups, "score": score };
}

function _peerItem(p, star) {
    return { "id": "p:" + p.id, "type": "peer", "peerId": p.id, "star": !!star };
}

function _groupItem(id, label, members, extra) {
    return Object.assign({ "id": id, "type": "group", "label": label, "members": members.map(p => p.id) }, extra || {});
}

// Arranges `peers` into at most `max` items.
// opts: { favorites: {id: name}, broken: [relay names down],
//         memo: { key, stars: [ids], solo: [ids] } from the previous call }
// Returns { items, key, stars, solo, scores }.
function arrange(peers, max, opts) {
    opts = opts || {};
    const memo = opts.memo || {};
    const favorites = opts.favorites || {};
    const broken = p => p.online && p.relayed && (opts.broken || []).indexOf(p.relay) >= 0;
    const wasStar = {}, wasSolo = {};
    (memo.stars || []).forEach(id => wasStar[id] = true);
    (memo.solo || []).forEach(id => wasSolo[id] = true);

    const out = [];
    let key = memo.key || "", scores = [];
    const online = peers.filter(p => p.online), asleep = peers.filter(p => !p.online);
    if (peers.length <= max) {
        peers.forEach(p => out.push(_peerItem(p, false)));
        return _done(out, key, scores);
    }
    const bed = asleep.length ? 1 : 0;
    const sum = online.reduce((a, p) => a + total(p), 0) || 1;
    // Stars: trouble first, then heavy users, then favourites
    const stars = online.filter(broken);
    online.slice().sort((a, b) => total(b) - total(a)).forEach(p => {
        const share = total(p) / sum;
        if (stars.indexOf(p) < 0 && total(p) > STAR_MIN_BPS && share > (wasStar[p.id] ? STAR_KEEP : STAR_SHARE))
            stars.push(p);
    });
    online.forEach(p => {
        if (favorites[p.id] !== undefined && stars.indexOf(p) < 0)
            stars.push(p);
    });
    // Keep at least two places for groups
    const shown = stars.slice(0, Math.max(1, max - bed - 2));
    shown.forEach(p => out.push(_peerItem(p, true)));
    const rest = online.filter(p => shown.indexOf(p) < 0);
    const slots = max - out.length - bed;
    if (rest.length <= slots) {
        rest.forEach(p => out.push(_peerItem(p, false)));
    } else {
        const cands = CRITERIA.map(c => Object.assign({ "c": c }, bucketize(rest, c, slots))).sort((a, b) => b.score - a.score);
        let pick = cands[0];
        const cur = cands.find(x => x.c.id === key);
        if (cur && pick.score - cur.score < STICKY)
            pick = cur;
        key = pick.c.id;
        scores = cands.map(x => ({ "id": x.c.id, "score": Math.round(x.score * 100) / 100, "chosen": x === pick }));
        const groups = pick.groups.map(g => ({ "crit": g.crit, "k": g.k, "members": g.members.slice() }));
        // Spare places go to the busiest peers, pulled out of their group;
        // the ones already alone weigh more, so nothing flickers
        let free = max - out.length - groups.length - bed;
        while (free > 0) {
            let best = null, bestW = -1;
            groups.forEach(g => {
                if (g.members.length <= 2)
                    return;
                g.members.forEach(p => {
                    const w = total(p) * (wasSolo[p.id] ? 4 : 1) + (wasSolo[p.id] ? 1 : 0);
                    if (w > bestW) {
                        bestW = w;
                        best = { "p": p, "g": g };
                    }
                });
            });
            if (!best)
                break;
            best.g.members.splice(best.g.members.indexOf(best.p), 1);
            out.push(_peerItem(best.p, false));
            free--;
        }
        groups.forEach(g => {
            if (g.members.length === 1) {
                out.push(_peerItem(g.members[0], false));
                return;
            }
            // One lonely pile says nothing about its members: call it what it is
            const label = groups.length === 1 ? g.members.length + " online" : g.k === "misc" ? g.members.length + " misc" : g.crit.label(g.k, g.members.length);
            out.push(_groupItem("g:" + g.crit.id + ":" + g.k, label, g.members, {
                "crit": g.crit.id,
                "k": g.k
            }));
        });
    }
    if (asleep.length === 1)
        out.push(_peerItem(asleep[0], false));
    else if (asleep.length)
        out.push(_groupItem("g:asleep", asleep.length + " asleep", asleep, { "asleep": true }));
    return _done(out, key, scores);
}

function _done(items, key, scores) {
    return {
        "items": items,
        "key": key,
        "scores": scores,
        "stars": items.filter(i => i.star).map(i => i.peerId),
        "solo": items.filter(i => i.type === "peer").map(i => i.peerId)
    };
}

// The whole view. peers: every peer shown; filters: Query.parse() output;
// opts as for arrange(). Search results take the places; everything else
// becomes one fog item.
function view(peers, max, filters, opts) {
    let set = peers;
    let fog = [];
    if (filters && filters.length) {
        const hit = set.filter(p => filters.every(f => f.test(p)));
        fog = set.filter(p => hit.indexOf(p) < 0);
        set = hit;
    }
    const room = Math.max(2, max - (fog.length ? 1 : 0));
    const r = set.length ? arrange(set, room, opts) : _done([], opts && opts.memo ? opts.memo.key || "" : "", []);
    if (fog.length)
        r.items.push(_groupItem("g:fog", fog.length + " other" + (fog.length > 1 ? "s" : ""), fog, { "fog": true }));
    r.hits = set.length;
    return r;
}
