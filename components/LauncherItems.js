.pragma library
.import "MyGroups.js" as MyGroups
.import "Query.js" as Query

// What typing "abyss" in the launcher (Super+Space) offers. First the deep
// itself — the whole scene, with everything it can do — then the quick
// steps, so the main needs take one line: connect, pick where Internet goes
// out, copy an address, open SSH. Pure: the launcher component turns the
// actions ("type:data") into calls.
//
// state: { status, online, total, peers, groups, exitNode, exitGroup }
// status: "connected" | "connecting" | "disconnected" | "needsLogin" | "stopped"

const CAT = ["Abyss"];

function _item(name, icon, comment, action) {
    return { "name": name, "icon": "material:" + icon, "comment": comment, "action": action, "categories": CAT };
}

// The step that moves the connection forward, as the jellyfish's click
function _connection(s) {
    if (s.status === "connected")
        return _item("Disconnect NetBird", "vpn_key_off", s.online + "/" + s.total + " peers online", "toggle:");
    if (s.status === "needsLogin")
        return _item("Sign in to NetBird", "login", "Opens the sign-in page", "toggle:");
    if (s.status === "stopped")
        return _item("Start the NetBird service", "play_arrow", "The service is stopped", "toggle:");
    if (s.status === "connecting")
        return _item("Stop connecting", "vpn_key_off", "Connecting…", "toggle:");
    return _item("Connect NetBird", "vpn_lock", "Off", "toggle:");
}

// Where Internet can go out, as the light's menu: groups first, then their
// peers and the others. The one in use wears a sun
function _internet(s) {
    const open = s.groups.map(g => g.id);
    const out = [], seen = {};
    MyGroups.exitTree(s.groups, s.peers, open, s.exitNode, s.exitGroup).forEach(r => {
        if (r.kind === "group") {
            out.push(_item("Internet through all of " + r.name, r.on ? "wb_sunny" : "public",
                (r.on ? "In use · via " + s.exitNode : r.count + " can lend it") + " · the best one online, the next takes over",
                r.dim ? "none:" : "exit:group:" + r.id));
            return;
        }
        if (!r.online || seen[r.name])
            return;
        seen[r.name] = true;
        out.push(_item("Internet through " + r.name, r.on ? "wb_sunny" : "public",
            (r.on ? "In use · " : "") + r.ms + " ms", "exit:peer:" + r.name));
    });
    if (s.exitNode)
        out.push(_item("Internet directly", "public_off", "Stop going out through " + s.exitNode, "exit:off"));
    return out.filter(i => i.action !== "none:");
}

// The whole list for a query ("" shows the essentials)
function items(s, query) {
    const q = String(query || "").trim().toLowerCase();
    const head = [_item("Open Abyss", "water", "Your mesh as a deep sea: every peer, group and the Internet light", "open:"), _connection(s)];
    if (s.status !== "connected")
        return q ? head.filter(i => _match(i, q)) : head;
    const net = _internet(s);
    if (!q) {
        // The essentials: what is in use, every group, the three quickest
        // peers, and the way back to going out directly
        const inUse = i => i.icon === "material:wb_sunny";
        const isPeer = i => i.action.indexOf("exit:peer:") === 0;
        const quickest = net.filter(i => isPeer(i) && !inUse(i)).sort((a, b) => parseInt(a.comment) - parseInt(b.comment)).slice(0, 3);
        return head.concat(net.filter(i => inUse(i) || !isPeer(i)), quickest).sort((a, b) => _rank(a) - _rank(b));
    }
    // Smart words (a speed like ">100ms", slow, direct, relay, a kind such
    // as nas or phone…) pick the peers themselves, as in the deep's search:
    // "abyss >100ms", "abyss ssh nas", "abyss copy phones"
    const toks = q.split(/\s+/), verb = ["copy", "ssh"].indexOf(toks[0]) >= 0 ? toks[0] : "";
    const filters = Query.parse((verb ? toks.slice(1) : toks).join(" "), s.relays);
    const smart = filters.some(f => !f.name);
    const rows = p => {
        const out = [];
        if (verb !== "ssh")
            out.push(_item("Copy " + p.name + "'s address", "content_copy", p.ip, "copy:" + p.name));
        if (verb !== "copy")
            out.push(_item("SSH to " + p.name, "terminal", p.ip, "ssh:" + p.name));
        return out;
    };
    if (smart) {
        const found = [];
        s.peers.filter(p => p.online && filters.every(f => f.test(p))).forEach(p => rows(p).forEach(r => found.push(r)));
        return head.concat(net).filter(i => _match(i, q)).concat(found);
    }
    const peers = [];
    s.peers.filter(p => p.online).forEach(p => {
        peers.push(_item("Copy " + p.name + "'s address", "content_copy", p.ip, "copy:" + p.name));
        peers.push(_item("SSH to " + p.name, "terminal", p.ip, "ssh:" + p.name));
    });
    return head.concat(net, peers).filter(i => _match(i, q));
}

// Open and connect first, then what is in use, groups, peers, "directly"
function _rank(i) {
    if (i.action === "open:" || i.action === "toggle:")
        return i.action === "open:" ? 0 : 1;
    if (i.icon === "material:wb_sunny")
        return 2;
    return i.action.indexOf("exit:group:") === 0 ? 3 : i.action === "exit:off" ? 5 : 4;
}

// Every word must appear in the name or the comment ("int vega")
function _match(i, q) {
    const hay = (i.name + " " + i.comment).toLowerCase();
    return q.split(/\s+/).every(w => hay.indexOf(w) >= 0);
}
