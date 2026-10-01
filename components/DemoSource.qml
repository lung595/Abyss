import QtQuick
import "Mesh.js" as Mesh
import "DemoMesh.js" as Demo

// Stands in for NetBird: a made-up mesh (DemoMesh.js) with the same view
// model and the same actions as the real source. Traffic only flows while a
// view is watching, the way the NetBird source only reads while one is open.
// It is also the test lab (Settings > Test lab): any number of peers, added
// latency, a peer that stops answering, a relay or the management server
// down, a peer that keeps dropping out. Everything stays in memory.
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

    // --- Test lab (bound to the settings by the daemon) ----------------------
    // Which mesh: "home", "work", "crowd", or "lab" (labPeers made-up peers)
    property string labMesh: "home"
    property int labPeers: 24
    // Milliseconds added to every peer's latency
    property int labLatency: 0
    // What goes wrong: "none", "silent" (a peer stops answering), "flap" (a
    // peer keeps dropping out), "relay", "management", "signedOut", "stopped"
    property string labTrouble: "none"
    // How busy the links are: "calm", "normal" or "rush"
    property string labTraffic: "normal"
    // NetBird's lazy connections: idle peers doze instead of sleeping
    property bool labLazy: false
    onLabLazyChanged: refresh()
    // The peers the trouble hits right now, by name ("" when none)
    readonly property string silentPeer: labTrouble === "silent" ? Demo.silentPeer(profile) : ""
    readonly property string flappingPeer: labTrouble === "flap" ? Demo.flapPeer(profile) : ""
    // The same, worked out on the spot: a handler of labTrouble may run
    // before the bindings above have followed it
    function _silent() {
        return labTrouble === "silent" ? Demo.silentPeer(profile) : "";
    }

    // A peer's name went online or offline (for notifications)
    signal peerEvent(string name, bool online)

    property var _counters: ({})
    property var _offline: ({})
    property string _hog: ""
    property int _reads: 0
    property bool _managementDown: false
    // Faking the last minute at start: nobody is told about it
    property bool _priming: false

    // now: the time of this read (the history priming fakes one per second)
    function refresh(now) {
        now = now || Date.now();
        const up = daemonStatus === "Connected";
        const json = daemonStatus ? Demo.status(profile, now, up, _counters, _offline, relayDown, {
            "addMs": labLatency,
            "silent": _silent(),
            "managementDown": _managementDown,
            "lazy": labLazy
        }) : null;
        const before = {};
        (view.peers || []).forEach(p => before[p.name] = p.online);
        view = Mesh.parse(daemonStatus, json, view, now);
        if (up && !_priming)
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

    // One read: every live peer moves some bytes; one of them hogs. In the
    // lab, the flapping peer drops out or comes back every 6 reads
    function _step(now) {
        _reads++;
        const flap = labTrouble === "flap" ? Demo.flapPeer(profile) : "";
        if (flap && _reads % 6 === 0) {
            const o = Object.assign({}, _offline);
            o[flap] = !o[flap];
            _offline = o;
        }
        const busy = ({ "calm": 0.15, "rush": 5 })[labTraffic] || 1;
        const quiet = _silent();
        const live = view.peers.filter(p => p.online && p.name !== quiet);
        if (!live.length)
            return refresh(now);
        if (!_hog || _reads % 9 === 0)
            _hog = live[Math.floor(Math.random() * live.length)].name;
        const c = Object.assign({}, _counters);
        live.forEach(p => {
            let mbps = busy * Demo.baseRate(profile, p.name) * (p.name === _hog ? 16 : 1) * (0.55 + Math.random() * 0.9);
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
    // The real source runs `netbird up --setup-key`: here the made-up mesh
    // just comes up (a key is still checked, like the real one)
    function join(key, url, hostname) {
        if (!/^[A-Za-z0-9][A-Za-z0-9_.=-]{7,}$/.test(String(key || "").trim()))
            return false;
        connect();
        return true;
    }
    function logout() {
        disconnect();
    }
    function shareSsh(on) {
    }
    // The real source asks systemd to start the service
    function startService() {
        daemonStatus = "Idle";
        refresh();
    }
    // again: rebuild even when it is the current one (the lab's size changed)
    function setProfile(name, again) {
        if ((name === profile && !again) || profiles.indexOf(name) < 0)
            return;
        profile = name;
        exitNode = "";
        networks = Demo.networks(name);
        history = {};
        _seed();
        view = Mesh.parse(daemonStatus, null, null, Date.now());
        refresh();
    }
    // Exit routes no peer is known for (the real source only)
    readonly property var looseExits: []
    function setExitRoute(id) {
    }
    // NetBird takes a moment to switch; the demo pretends to, briefly
    property bool switching: false
    function setExitNode(name) {
        exitNode = name || "";
        switching = true;
        _switch.restart();
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
    // --- Test lab ------------------------------------------------------------
    // Puts the mesh in the state the lab's trouble asks for. Called when the
    // setting changes: the jellyfish still connects and disconnects after
    function _applyTrouble() {
        const t = labTrouble;
        _settle.stop();
        _offline = {};
        relayDown = t === "relay" ? Demo.firstRelay(profile) : "";
        _managementDown = t === "management";
        if (t === "signedOut")
            daemonStatus = "NeedsLogin";
        else if (t === "stopped")
            daemonStatus = "";
        else if (daemonStatus === "NeedsLogin" || daemonStatus === "")
            daemonStatus = "Connected";
    }
    onLabTroubleChanged: {
        _applyTrouble();
        refresh();
    }
    onLabLatencyChanged: refresh()
    onLabMeshChanged: {
        Demo.setLab(labPeers);
        setProfile(labMesh, labMesh === "lab");
        _applyTrouble();
        refresh();
    }
    onLabPeersChanged: {
        Demo.setLab(labPeers);
        if (labMesh === "lab")
            setProfile("lab", true);
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
    property Timer _switch: Timer {
        interval: 700
        onTriggered: src.switching = false
    }
    property Timer _settle: Timer {
        interval: 1400
        onTriggered: {
            src.daemonStatus = "Connected";
            src.refresh();
        }
    }
    Component.onCompleted: {
        Demo.setLab(labPeers);
        // (only while nothing chose another mesh before this ran)
        if (profile === "home" && labMesh !== profile && profiles.indexOf(labMesh) >= 0) {
            profile = labMesh;
            networks = Demo.networks(labMesh);
        }
        _applyTrouble();
        // Prime a minute of history so cards open on a real curve
        const t = Date.now();
        _seed();
        _priming = true;
        refresh(t - 61000);
        for (let i = 60; i > 0; i--)
            _step(t - i * 1000);
        _priming = false;
    }
}
