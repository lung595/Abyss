import QtQuick
import "Mesh.js" as Mesh
import "Netbird.js" as Netbird

// The real mesh: reads the NetBird daemon through its CLI, with the same
// view model and actions as DemoSource, so every surface works on either.
//
// One read at start (the bar shows the real state); after it, nothing runs
// while no view watches: no timer, no process. While one does,
// `netbird status --json` runs every 2 s, one read at a time (never piled
// up); `netbird networks list` and `netbird profile list` only on opening,
// after a change, and every 10th read for the networks.
// Actions (up, down, select…) run in their own queue, so a sign-in waiting
// in the browser never stops the reads.
// Every argv is a list, never a shell line: no name can run anything.
// Peers, traffic and what is learned about exit routes stay in memory.
QtObject {
    id: src

    // --- Interface (the same as DemoSource) ----------------------------------
    readonly property bool demo: false
    // As NetBird says it: "Connected", "Connecting", "Idle", "NeedsLogin"…,
    // or "" when no daemon answers
    property string daemonStatus: ""
    property string profile: ""
    property var profiles: []
    // The peer (name) Internet goes through, or "" for none
    property string exitNode: ""
    // The caves: [{ id, cidr, via, on }] (Netbird.caves)
    property var networks: []
    // Demo only (a relay to break on purpose); always "" here
    readonly property string relayDown: ""
    property var view: Mesh.parse("", null, null, Date.now())
    // Last 60 reads per peer id: [[down, up], ...] (memory only)
    property var history: ({})
    readonly property bool connected: view.state === "connected"
    // The last thing that went wrong, in one line ("" when all is well)
    property string error: ""
    // An action is running (the light can say "Switching…" meanwhile)
    readonly property bool busy: _acting
    // An exit was asked for and NetBird has not confirmed it yet
    readonly property bool switching: _wantExit !== ""

    // A peer's name went online or offline (for notifications)
    signal peerEvent(string name, bool online)
    // Something to tell the user: an action failed or was refused
    signal notice(string text)

    function refresh() {
        src._read(src._reads % 10 === 0, false);
    }

    function watch(on) {
        const was = src._watchers;
        src._watchers = Math.max(0, was + (on ? 1 : -1));
        if (on && !was)
            src._read(true, true);
    }

    function connect() {
        if (src.daemonStatus === "Connected" || src.daemonStatus === "Connecting")
            return;
        src._act([Netbird.upCmd()], "Could not connect");
    }

    function disconnect() {
        src._act([Netbird.downCmd()], "Could not disconnect");
    }

    function toggle() {
        if (src.connected || src.daemonStatus === "Connecting")
            src.disconnect();
        else
            src.connect();
    }

    // `netbird up` opens the sign-in page in the browser when one is needed
    function login() {
        src._act([Netbird.upCmd()], "Could not sign in");
    }

    function startService() {
        src._act([Netbird.startServiceCmd()], "Could not start the NetBird service");
    }

    // NetBird disconnects to switch profile: connect again if it was connected
    function setProfile(name) {
        if (!name || name === src.profile || src.profiles.indexOf(name) < 0)
            return;
        const cmds = [Netbird.selectProfileCmd(name)];
        if (src.connected)
            cmds.push(Netbird.upCmd());
        src.profile = name;
        src.exitNode = "";
        src.history = {};
        src._learned = {};
        src._act(cmds, "Could not switch to " + name);
    }

    function setExitNode(name) {
        name = name || "";
        if (src._exitShown() === name)
            return;
        // Just failed: not again before 30 s (a group of mine asks on
        // every read; the note was already said)
        if (name === src._failedExit && Date.now() - src._failedAt < 30000)
            return;
        const p = name ? src.view.peers.find(q => q.name === name) : null;
        if (name && !p) {
            src._say("No peer named " + name);
            return;
        }
        const plan = Netbird.exitCommands(src._nets, src._exitMap, p ? p.id : "");
        if (plan.error) {
            src._say("Internet through " + name + ": " + plan.error);
            return;
        }
        src._wantExit = name || src._direct;
        src._wantUntil = Date.now() + 10000;
        src.exitNode = name;
        src._act(plan.cmds, name ? "Could not go out through " + name : "Could not stop going out through a peer");
    }

    function toggleNetwork(id) {
        const n = src._nets.find(x => x.id === id);
        if (!n)
            return;
        src.networks = src.networks.map(c => c.id === id ? Object.assign({}, c, { "on": !n.selected }) : c);
        src._act([n.selected ? Netbird.deselectNetworksCmd([id]) : Netbird.selectNetworksCmd([id], true)], "Could not switch " + id + (n.selected ? " off" : " on"));
    }

    // Demo only: kept so every caller works on both sources
    function setState(state) {
    }
    function flap(name) {
    }

    // --- Reading -------------------------------------------------------------
    property int _watchers: 0
    property int _reads: 0
    property bool _reading: false
    // What the next read must also fetch, asked while one was running
    property bool _moreNetworks: false
    property bool _moreProfiles: false
    // `netbird networks list`, as read (Netbird.readNetworks), and whether
    // it was asked once (an empty list or a stopped daemon is not asked
    // again on every read; every 10th read and every change ask anyway)
    property var _nets: []
    property bool _netsRead: false
    // Exit routes seen going through a peer: { routeId: peerId }
    property var _learned: ({})
    property var _exitMap: ({})

    // One read: networks and profiles when asked, then the status. A read
    // asked while one runs is folded into one more read after it
    function _read(withNetworks, withProfiles) {
        src._moreNetworks = src._moreNetworks || withNetworks || !src._netsRead;
        src._moreProfiles = src._moreProfiles || withProfiles;
        if (src._reading)
            return;
        src._reading = true;
        src._reads++;
        if (src._moreNetworks)
            src._reader.run(Netbird.networksCmd(), (out, err, code) => {
                src._netsRead = true;
                if (code === 0)
                    src._nets = Netbird.readNetworks(out);
            });
        if (src._moreProfiles)
            src._reader.run(Netbird.profilesCmd(), (out, err, code) => {
                if (code !== 0)
                    return;
                const p = Netbird.readProfiles(out);
                src.profiles = p.names;
                src.profile = p.active;
            });
        src._moreNetworks = false;
        src._moreProfiles = false;
        src._reader.run(Netbird.statusCmd(), (out, err, code) => {
            src._take(Netbird.readStatus(out || err, code));
            src._reading = false;
            if (src._moreNetworks || src._moreProfiles)
                src._read(false, false);
        });
    }

    // One status read, into the view
    function _take(st) {
        const now = Date.now();
        src.daemonStatus = st.daemonStatus;
        if (!src._acting)
            src.error = st.error;
        const before = {};
        src.view.peers.forEach(p => before[p.name] = p.online);
        const next = Mesh.parse(st.daemonStatus, st.json, src.view, now);
        src._learnExits(next.peers);
        const lending = Netbird.markExits(next.peers, src._exitMap);
        if (src._wantExit && (lending === src._wantExit || (src._wantExit === src._direct && !lending) || now > src._wantUntil))
            src._wantExit = "";
        src.exitNode = src._wantExit ? src._exitShown() : lending;
        src.networks = Netbird.caves(src._nets, next.peers);
        if (next.state === "connected" && src.connected)
            next.peers.forEach(p => {
                if (p.name in before && before[p.name] !== p.online)
                    src.peerEvent(p.name, p.online);
            });
        src.view = next;
        src._remember(next.peers);
    }

    // Which peer each exit route goes through, learned while one is in use
    function _learnExits(peers) {
        const selected = Netbird.exitRoutes(src._nets).filter(r => r.selected);
        const lender = peers.find(p => p.lending);
        if (selected.length && lender && selected.some(r => src._learned[r.id] !== lender.id)) {
            const l = Object.assign({}, src._learned);
            selected.forEach(r => l[r.id] = lender.id);
            src._learned = l;
        }
        src._exitMap = Netbird.exitMap(src._nets, peers, src._learned);
    }

    function _remember(peers) {
        const h = {};
        peers.forEach(p => {
            const list = (src.history[p.id] || []).slice(-59);
            list.push([p.down, p.up]);
            h[p.id] = list;
        });
        src.history = h;
    }

    // --- Exit node while NetBird switches -------------------------------------
    // The peer asked for (or _direct), shown until a read agrees or 10 s pass
    readonly property string _direct: "\u0000direct"
    property string _wantExit: ""
    property real _wantUntil: 0
    // The last exit that failed, and when (no retry for 30 s)
    property string _failedExit: ""
    property real _failedAt: 0

    function _exitShown() {
        if (!src._wantExit)
            return src.exitNode;
        return src._wantExit === src._direct ? "" : src._wantExit;
    }

    // --- Actions -------------------------------------------------------------
    property bool _acting: false
    property int _pending: 0

    // Runs argv lists one after the other; stops at the first failure and
    // says why; reads everything again once the queue is empty
    function _act(cmds, failText) {
        if (!cmds.length)
            return;
        src._acting = true;
        src._pending++;
        let failed = false;
        cmds.forEach((cmd, i) => src._actor.run(cmd, (out, err, code) => {
            if (!failed && code !== 0) {
                failed = true;
                if (src._wantExit) {
                    src._failedExit = src._wantExit === src._direct ? "" : src._wantExit;
                    src._failedAt = Date.now();
                }
                src._wantExit = "";
                src._say(failText + ": " + (Netbird.firstLine(err) || Netbird.firstLine(out) || "netbird exited with " + code));
            }
            if (i < cmds.length - 1)
                return;
            if (--src._pending === 0) {
                src._acting = false;
                src._read(true, true);
            }
        }, () => failed));
    }

    // The same note twice within 30 s is said once
    property string _said: ""
    property real _saidAt: 0
    function _say(text) {
        const now = Date.now();
        src.error = text;
        if (text === src._said && now - src._saidAt < 30000)
            return;
        src._said = text;
        src._saidAt = now;
        src.notice(text);
    }

    // --- Processes -----------------------------------------------------------
    property Timer _tick: Timer {
        interval: 2000
        repeat: true
        running: src._watchers > 0
        onTriggered: src.refresh()
    }

    property CliRunner _reader: CliRunner {}
    property CliRunner _actor: CliRunner {}

    // One read at start, so the bar and the launcher show the real state
    // before any view opens (then nothing until one does)
    Component.onCompleted: src._read(true, true)
}
