import QtQuick
import "Mesh.js" as Mesh
import "DemoMesh.js" as Demo

// Stands in for NetBird while the plugin only has its interface: a made-up
// mesh (DemoMesh.js) with the same view model and the same actions the real
// source will have. Traffic only flows while a view is watching, the way the
// NetBird source will only read the daemon while a view is open.
QtObject {
    id: src

    readonly property bool demo: true
    // What the daemon would report: "Connected", "Connecting", "Idle",
    // "NeedsLogin", or "" when the service is not running
    property string daemonStatus: "Connected"
    property string profile: "home"
    readonly property var profiles: Demo.profiles()
    // The peer (name) Internet goes through, or "" for none
    property string exitNode: ""
    property var networks: Demo.networks("home")
    // A relay that stopped answering, to try the warnings: "relay-us" or ""
    property string relayDown: ""
    property var view: Mesh.parse("Connected", null, null, Date.now())
    // Last 60 reads per peer id: [[down, up], ...] (memory only)
    property var history: ({})
    readonly property bool connected: view.state === "connected"

    // A peer's name went online or offline (for notifications)
    signal peerEvent(string name, bool online)

    property var _counters: ({})
    property var _offline: ({})
    property string _hog: ""
    property int _reads: 0

    // now: the time of this read (the history priming fakes one per second)
    function refresh(now) {
        now = now || Date.now();
        const up = daemonStatus === "Connected";
        const json = daemonStatus ? Demo.status(profile, now, up, _counters, _offline, relayDown) : null;
        const before = {};
        (view.peers || []).forEach(p => before[p.name] = p.online);
        view = Mesh.parse(daemonStatus, json, view, now);
        if (up)
            view.peers.forEach(p => {
                if (p.name in before && before[p.name] !== p.online)
                    src.peerEvent(p.name, p.online);
            });
        const h = Object.assign({}, history);
        view.peers.forEach(p => {
            const list = (h[p.id] || []).slice(-59);
            list.push([p.down, p.up]);
            h[p.id] = list;
        });
        history = h;
    }

    // One read: every live peer moves some bytes; one of them hogs
    function _step(now) {
        _reads++;
        const live = view.peers.filter(p => p.online);
        if (!live.length)
            return refresh(now);
        if (!_hog || _reads % 9 === 0)
            _hog = live[Math.floor(Math.random() * live.length)].name;
        const c = Object.assign({}, _counters);
        live.forEach(p => {
            let mbps = Demo.baseRate(profile, p.name) * (p.name === _hog ? 16 : 1) * (0.55 + Math.random() * 0.9);
            if (p.name === exitNode)
                mbps += 4 + Math.random() * 5;
            const prev = c[p.name] || { "rx": 0, "tx": 0 };
            c[p.name] = {
                "rx": prev.rx + mbps * 1e6 / 8,
                "tx": prev.tx + mbps * (0.08 + Math.random() * 0.3) * 1e6 / 8
            };
        });
        _counters = c;
        refresh(now);
    }

    // Plausible totals so far, so cards show real-looking figures
    function _seed() {
        const c = {};
        Demo.status(profile, Date.now(), true, {}, {}, "").peers.details.forEach(d => {
            const n = d.fqdn.split(".")[0];
            c[n] = { "rx": 1e8 * (1 + n.length % 7), "tx": 2e7 * (1 + n.length % 5) };
        });
        _counters = c;
    }

    function connect() {
        if (daemonStatus === "Connected" || daemonStatus === "Connecting")
            return;
        daemonStatus = "Connecting";
        refresh();
        _settle.restart();
    }
    function disconnect() {
        _settle.stop();
        daemonStatus = "Idle";
        refresh();
    }
    function toggle() {
        if (connected || daemonStatus === "Connecting")
            disconnect();
        else
            connect();
    }
    // The real source opens `netbird login` in the browser
    function login() {
        connect();
    }
    // The real source asks systemd to start the service
    function startService() {
        daemonStatus = "Idle";
        refresh();
    }
    function setProfile(name) {
        if (name === profile || profiles.indexOf(name) < 0)
            return;
        profile = name;
        exitNode = "";
        networks = Demo.networks(name);
        history = {};
        _seed();
        view = Mesh.parse(daemonStatus, null, null, Date.now());
        refresh();
    }
    function setExitNode(name) {
        exitNode = name || "";
    }
    function toggleNetwork(id) {
        networks = networks.map(n => n.id === id ? Object.assign({}, n, { "on": !n.on }) : n);
    }
    // Jump to any state, for trying the interface: dms ipc call abyss demo <state>
    function setState(state) {
        _settle.stop();
        if (state === "relayDown" || state === "relayUp") {
            relayDown = state === "relayDown" ? "relay-us" : "";
        } else {
            daemonStatus = ({
                    "connected": "Connected",
                    "connecting": "Connecting",
                    "disconnected": "Idle",
                    "needsLogin": "NeedsLogin",
                    "stopped": ""
                })[state] ?? daemonStatus;
        }
        refresh();
    }
    // Takes a peer offline or back (the demo's way to show notifications)
    function flap(name) {
        const o = Object.assign({}, _offline);
        o[name] = !o[name];
        _offline = o;
        refresh();
    }

    property int _watchers: 0
    function watch(on) {
        _watchers = Math.max(0, _watchers + (on ? 1 : -1));
        if (on)
            refresh();
    }

    property Timer _reader: Timer {
        interval: 1000
        repeat: true
        running: src._watchers > 0 && src.daemonStatus === "Connected"
        triggeredOnStart: true
        onTriggered: src._step(Date.now())
    }
    property Timer _settle: Timer {
        interval: 1400
        onTriggered: {
            src.daemonStatus = "Connected";
            src.refresh();
        }
    }
    Component.onCompleted: {
        // Prime a minute of history so cards open on a real curve
        const t = Date.now();
        _seed();
        refresh(t - 61000);
        for (let i = 60; i > 0; i--)
            _step(t - i * 1000);
    }
}
