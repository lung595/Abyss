import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import "Mesh.js" as Mesh
import "Layout.js" as Lay

// The deep, shared by the popout, the Control Center and the desktop.
//
// You are the jellyfish; each peer is a creature at the depth of its latency,
// linked to you by a tentacle whose width and light pulses are its live
// traffic. One clock (a 30 Hz Timer) moves the pulses, the marine snow and
// the bob; it only runs while the scene is watched and connected, or during a
// transition. Everything else is painted once and only redrawn on change.
Item {
    id: root

    property var source: null
    // Copy, SSH and browser helpers (the daemon); null in previews
    property var actions: null
    // The view is on screen (popout shown, Control Center open, desktop)
    property bool active: true
    property real cornerRadius: 16
    // Desktop: stay still until the pointer is over it
    property bool freezeWhenIdle: false
    property bool interacting: true
    // Control Center: a smaller top bar
    property bool compact: false

    readonly property Prefs prefs: Prefs {}
    readonly property var view: source ? source.view : Mesh.parse("", null, null, 0)
    readonly property bool connected: view.state === "connected"
    readonly property bool reduceMotion: prefs.reduceMotion
    readonly property bool awake: active && (!freezeWhenIdle || interacting || prefs.desktopLive)
    readonly property bool flowing: awake && connected && !reduceMotion && prefs.pulses

    // --- Colours: all from the theme; the deep stays dark in light mode, the
    // way Orbit keeps its night sky
    function mix(a, b, k) {
        return Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1);
    }
    readonly property color _night: "#02040b"
    readonly property color _dusk: "#081426"
    readonly property color _white: "#ffffff"
    readonly property color _grey: "#8a8fa0"
    readonly property color abyss: mix(Theme.primary, _night, 0.92)
    readonly property color shallow: mix(Theme.primary, _dusk, 0.68)
    readonly property color ink: mix(Theme.primary, _white, 0.88)
    readonly property color inkDim: Qt.rgba(ink.r, ink.g, ink.b, 0.62)
    readonly property color sleepColor: mix(Theme.primary, _grey, 0.7)
    readonly property color sunColor: mix(Theme.warning, _white, 0.4)
    readonly property var tints: [Theme.primary, Theme.tertiary, Theme.success, Theme.secondary, mix(Theme.primary, Theme.tertiary, 0.5), mix(Theme.tertiary, Theme.success, 0.5), mix(Theme.primary, Theme.success, 0.5), mix(Theme.secondary, Theme.tertiary, 0.5)]
    // Stable colour per peer name
    function tintOf(name) {
        let h = 0;
        const s = String(name || "");
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) >>> 0;
        return tints[h % tints.length];
    }

    // --- Layout ------------------------------------------------------------
    readonly property real topH: 54
    readonly property var shown: view.peers.filter(p => p.online || prefs.showOffline)
    readonly property var lay: Lay.layout(shown, Math.max(240, width), Math.max(220, height), topH)
    readonly property var frame: lay.frame
    readonly property var peerById: {
        const m = {};
        view.peers.forEach(p => m[p.id] = p);
        return m;
    }
    // Delegates are rebuilt only when the set of peers changes, not on
    // every traffic read
    readonly property string _idsKey: shown.map(p => p.id).join("|")
    readonly property var ids: _idsKey ? _idsKey.split("|") : []
    readonly property string _relaysKey: Object.keys(lay.relays).sort().join("|")
    readonly property var relayNames: _relaysKey ? _relaysKey.split("|") : []
    readonly property var downRelays: view.relays.filter(r => !r.available).map(r => r.name)

    function spotOf(id) {
        const p = lay.peers[id];
        return p ? Qt.point(p.x, p.y) : Qt.point(width / 2, frame.floorY);
    }

    // --- Tentacles (kept while retracting after a disconnect) ---------------
    property var tents: []
    property var tentPts: ({})
    property var threads: []
    onLayChanged: _build()
    onConnectedChanged: {
        if (!awake || reduceMotion)
            ext = connected ? 1 : 0;
        _build();
    }

    function _build() {
        if (!connected) {
            threads = [];
            return;
        }
        const f = lay.frame, j = f.jelly;
        const live = shown.filter(p => p.online && lay.peers[p.id]);
        live.sort((a, b) => {
            const pa = lay.peers[a.id], pb = lay.peers[b.id];
            return Math.atan2(pb.y - j.y, pb.x - j.x) - Math.atan2(pa.y - j.y, pa.x - j.x);
        });
        const pts = {};
        tents = live.map((p, i) => {
            const at = lay.peers[p.id], via = p.relayed ? lay.relays[p.relay] : null;
            const line = Lay.tentacle(Lay.rimPoint(j, i, live.length), [at.x, at.y], via ? [via.x, via.y] : null);
            pts[p.id] = line;
            return {
                "id": p.id,
                "pts": line,
                "len": Lay.length(line),
                "color": tintOf(p.name),
                "level": Mesh.level(p.down + p.up),
                "dashed": prefs.isMuted(p.id),
                "warn": p.relayed && downRelays.indexOf(p.relay) >= 0
            };
        });
        tentPts = pts;
        const nets = source ? source.networks : [];
        const th = [];
        nets.forEach((n, i) => {
            const peer = view.peers.find(p => p.name === n.via);
            const at = peer ? lay.peers[peer.id] : null;
            if (!n.on || !at || !peer.online)
                return;
            const cx = Lay.caveX(f, i), cy = f.floorY - 40;
            th.push({
                "pts": Lay.tentacle([cx, cy], [at.x + 18, at.y + 20], null).map(q => [q[0], q[1]]),
                "color": Theme.tertiary
            });
        });
        threads = th;
    }

    // --- The clock ---------------------------------------------------------
    property real t: 0
    property real ext: connected ? 1 : 0
    property double _last: 0
    property var _pulses: []
    property var _acc: ({})
    property var _snow: []
    readonly property int poolSize: 90
    readonly property int snowSize: 18

    Timer {
        id: clock
        interval: 33
        repeat: true
        running: root.awake && (root.flowing || Math.abs(root.ext - (root.connected ? 1 : 0)) > 0.001)
        onRunningChanged: {
            root._last = Date.now();
            if (!running)
                root._hideMovers();
        }
        onTriggered: root.step()
    }

    function _hideMovers() {
        _pulses = [];
        for (let i = 0; i < poolSize; i++) {
            const it = pulsePool.itemAt(i);
            if (it)
                it.visible = false;
        }
    }

    function step() {
        const now = Date.now();
        const dt = Math.min(0.1, Math.max(0, (now - _last) / 1000));
        _last = now;
        t += dt;
        const target = connected ? 1 : 0;
        if (ext !== target)
            ext = reduceMotion ? target : target > ext ? Math.min(1, ext + dt / 1.1) : Math.max(0, ext - dt / 0.7);
        // Light pulses: inward = download (toward you), outward = upload
        if (flowing && ext >= 1) {
            tents.forEach(tn => {
                const p = peerById[tn.id];
                if (!p || !p.online || tn.warn)
                    return;
                const a = _acc[tn.id] || (_acc[tn.id] = { "i": 0, "o": 0 });
                a.i += dt * (0.3 + 12 * Math.pow(Mesh.level(p.down), 1.5));
                a.o += dt * (0.15 + 5 * Math.pow(Mesh.level(p.up), 1.5));
                while (a.i > 1) {
                    a.i--;
                    _pulses.push({ "id": tn.id, "f": 1, "v": -1, "len": tn.len, "col": tn.color });
                }
                while (a.o > 1) {
                    a.o--;
                    _pulses.push({ "id": tn.id, "f": 0, "v": 1, "len": tn.len, "col": tn.color });
                }
            });
            _pulses = _pulses.filter(q => {
                q.f += q.v * dt * 150 / Math.max(40, q.len);
                return q.f >= 0 && q.f <= 1;
            }).slice(-poolSize);
        } else if (_pulses.length) {
            _pulses = [];
        }
        for (let i = 0; i < poolSize; i++) {
            const it = pulsePool.itemAt(i);
            if (!it)
                continue;
            const q = _pulses[i], pts = q ? tentPts[q.id] : null;
            if (!pts) {
                it.visible = false;
                continue;
            }
            const pt = Lay.pointAt(pts, q.f);
            it.x = pt[0];
            it.y = pt[1];
            it.inward = q.v < 0;
            it.tint = q.col;
            it.visible = true;
        }
        // Marine snow drifting down
        if (flowing) {
            if (_snow.length !== snowSize)
                _snow = Array.from({ "length": snowSize }, (_, i) => ({ "x": Math.random() * width, "y": Math.random() * height, "v": 5 + Math.random() * 9 }));
            for (let i = 0; i < snowSize; i++) {
                const s = _snow[i], it = snowPool.itemAt(i);
                s.y += s.v * dt;
                if (s.y > frame.floorY) {
                    s.y = frame.surfaceY;
                    s.x = Math.random() * width;
                }
                if (it) {
                    it.x = s.x;
                    it.y = s.y;
                }
            }
        }
    }

    // --- Watching: the source only reads NetBird while someone looks --------
    property bool _watching: false
    function _watch() {
        const want = active && !!source;
        if (want !== _watching && source) {
            source.watch(want);
            _watching = want;
        }
    }
    onActiveChanged: _watch()
    onSourceChanged: _watch()
    Component.onCompleted: _watch()
    Component.onDestruction: {
        if (_watching && source)
            source.watch(false);
    }

    // --- Actions -----------------------------------------------------------
    property string cardId: ""
    property bool netsOpen: false
    property string dropName: ""
    property string query: ""
    property string findId: ""
    property string omenHidden: ""

    function openCard(id) {
        cardId = cardId === id ? "" : id;
        netsOpen = false;
        forceActiveFocus();
    }
    function copy(text, what) {
        if (actions)
            actions.copy(text);
        ToastService.showInfo(what + " copied", text);
    }
    function ssh(peer) {
        if (actions)
            actions.ssh(peer.fqdn || peer.ip, prefs.terminal);
    }
    function openWeb(peer) {
        if (actions)
            actions.openUrl("http://" + (peer.fqdn || peer.ip));
    }
    function _peerAt(px, py) {
        let best = null, dist = 46;
        shown.forEach(p => {
            const s = lay.peers[p.id];
            if (!p.online || !s)
                return;
            const d = Math.hypot(s.x - px, s.y - py);
            if (d < dist) {
                dist = d;
                best = p;
            }
        });
        return best;
    }
    function dragOver(px, py) {
        const p = _peerAt(px, py);
        dropName = p ? p.name : "";
    }

    // --- Layers ------------------------------------------------------------
    layer.enabled: false
    clip: true

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.abyss
        clip: true

        Water {
            anchors.fill: parent
            scene: root
            frame: root.frame
            shallow: root.shallow
            abyss: root.abyss
            ink: root.ink
            kelp: root.mix(Theme.success, root.abyss, 0.5)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.cardId = "";
                root.netsOpen = false;
                root.forceActiveFocus();
            }
        }

        // Marine snow
        Repeater {
            id: snowPool
            model: root.snowSize
            Rectangle {
                visible: root.flowing
                width: 1.6
                height: 1.6
                radius: 0.8
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.35)
                x: -10
            }
        }

        // Internet exit: a shaft of light from the surface to the exit peer
        Rectangle {
            readonly property var exitPeer: root.source && root.source.exitNode ? root.view.peers.find(p => p.name === root.source.exitNode) : null
            readonly property point at: exitPeer ? root.spotOf(exitPeer.id) : Qt.point(0, 0)
            visible: !!exitPeer && exitPeer.online && root.connected
            x: at.x - 26
            y: root.frame.surfaceY
            width: 52
            height: Math.max(0, at.y - root.frame.surfaceY)
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(root.sunColor.r, root.sunColor.g, root.sunColor.b, 0.38)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(root.sunColor.r, root.sunColor.g, root.sunColor.b, 0.04)
                }
            }
        }

        Repeater {
            model: root.source ? root.source.networks : []
            Cave {
                required property var modelData
                required property int index
                scene: root
                net: modelData
                x: Lay.caveX(root.frame, index)
                y: root.frame.floorY + 8
                onToggled: {
                    if (root.source && root.connected)
                        root.source.toggleNetwork(modelData.id);
                }
            }
        }

        Tentacles {
            anchors.fill: parent
            scene: root
            tents: root.tents
            threads: root.threads
            ext: root.ext
        }

        // Light pulses travelling along the tentacles
        Repeater {
            id: pulsePool
            model: root.poolSize
            Item {
                property bool inward: true
                property color tint: "white"
                visible: false
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    x: -6
                    y: -6
                    color: Qt.rgba(parent.tint.r, parent.tint.g, parent.tint.b, 0.28)
                }
                Rectangle {
                    width: parent.inward ? 5 : 3.5
                    height: width
                    radius: width / 2
                    x: -width / 2
                    y: -width / 2
                    color: parent.inward ? Qt.lighter(parent.tint, 1.5) : "white"
                }
            }
        }

        Repeater {
            model: root.relayNames
            Lantern {
                required property string modelData
                scene: root
                name: modelData
                down: root.downRelays.indexOf(modelData) >= 0
                tint: root.mix(Theme.primary, Theme.tertiary, 0.5)
                x: root.lay.relays[modelData] ? root.lay.relays[modelData].x : 0
                y: root.lay.relays[modelData] ? root.lay.relays[modelData].y : 0
            }
        }

        Repeater {
            model: root.ids
            Creature {
                required property string modelData
                required property int index
                readonly property var p: root.peerById[modelData]
                visible: !!p
                scene: root
                peer: p || ({ "id": modelData, "name": "", "kind": "desktop", "online": false, "down": 0, "up": 0 })
                spot: root.spotOf(modelData)
                onFloor: !!root.lay.peers[modelData] && root.lay.peers[modelData].floor
                tint: root.tintOf(peer.name)
                isTop: root.connected && root.view.topId === modelData
                favorite: root.prefs.isFavorite(modelData)
                muted: root.prefs.isMuted(modelData)
                highlighted: root.cardId === modelData || root.findId === modelData || (root.dropName !== "" && root.dropName === peer.name)
                phase: index * 1.37
            }
        }

        Jellyfish {
            id: jelly
            scene: root
            x: root.frame.jelly.x
            y: root.frame.jelly.y
            r: root.frame.jelly.r
            lit: Math.max(0.08, root.ext)
        }
        Chip {
            x: root.frame.jelly.x - width / 2
            y: root.frame.jelly.y - root.frame.jelly.r * 1.15 - height
            title: jellyArea.containsMouse ? root.view.me.name + " · you" : "you"
            sub: jellyArea.containsMouse ? root.view.me.ip : ""
            ink: root.connected ? root.abyss : root.ink
            subInk: root.connected ? Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.7) : root.inkDim
            color: root.connected ? Theme.tertiary : Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.7)
        }
        MouseArea {
            id: jellyArea
            hoverEnabled: true
            x: root.frame.jelly.x - root.frame.jelly.r
            y: root.frame.jelly.y - root.frame.jelly.r * 1.6
            width: root.frame.jelly.r * 2
            height: root.frame.jelly.r * 2.6
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.view.state === "needsLogin")
                    root.source.login();
                else if (root.view.state === "stopped")
                    root.source.startService();
                else if (root.source)
                    root.source.toggle();
            }
        }

        SurfaceSun {
            readonly property var exitPeer: root.source && root.source.exitNode ? root.view.peers.find(p => p.name === root.source.exitNode) : null
            visible: root.connected && !!root.source
            scene: root
            home: exitPeer ? Qt.point(root.spotOf(exitPeer.id).x, root.frame.surfaceY) : Qt.point(root.width - 58, root.frame.surfaceY)
            label: exitPeer ? "Internet via " + exitPeer.name : "Internet"
            onDropped: (px, py) => {
                const p = root._peerAt(px, py);
                root.dropName = "";
                if (root.source)
                    root.source.setExitNode(p ? p.name : "");
            }
        }

        // When not connected: what is going on, and the one action that helps
        Column {
            visible: !root.connected
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.frame.jelly.r
            y: root.frame.bandTop + (root.frame.bandBottom - root.frame.bandTop) * 0.3
            spacing: 10
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ({
                        "connecting": "Reaching the mesh…",
                        "needsLogin": "NetBird needs you to sign in",
                        "stopped": "NetBird is not running"
                    })[root.view.state] || "The deep is asleep"
                wrapMode: Text.NoWrap
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.ink
            }
            ActionChip {
                visible: root.view.state !== "connecting" && !!root.source
                anchors.horizontalCenter: parent.horizontalCenter
                primary: true
                icon: ({
                        "needsLogin": "login",
                        "stopped": "play_arrow"
                    })[root.view.state] || "power_settings_new"
                text: ({
                        "needsLogin": "Sign in",
                        "stopped": "Start NetBird"
                    })[root.view.state] || "Connect"
                onClicked: {
                    if (root.view.state === "needsLogin")
                        root.source.login();
                    else if (root.view.state === "stopped")
                        root.source.startService();
                    else
                        root.source.connect();
                }
            }
        }

        TopBar {
            id: bar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            scene: root
            view: root.view
            source: root.source
            compact: root.compact
            onNetworksClicked: {
                root.netsOpen = !root.netsOpen;
                root.cardId = "";
            }
        }

        // Networks and the Internet exit, from the bar
        Rectangle {
            visible: root.netsOpen && !!root.source
            anchors.top: bar.bottom
            anchors.topMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 8
            width: 250
            height: netCol.implicitHeight + 16
            radius: 12
            color: Qt.rgba(root.abyss.r, root.abyss.g, root.abyss.b, 0.92)
            border.width: 1
            border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.14)
            z: 30
            Column {
                id: netCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                StyledText {
                    text: "NETWORKS"
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    color: root.inkDim
                }
                Repeater {
                    model: root.source ? root.source.networks : []
                    Item {
                        required property var modelData
                        width: netCol.width
                        height: 32
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                text: modelData.id
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: root.ink
                            }
                            StyledText {
                                text: modelData.cidr + " · via " + modelData.via
                                font.pixelSize: 10
                                font.family: Theme.monoFontFamily
                                color: root.inkDim
                            }
                        }
                        ActionChip {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            text: modelData.on ? "On" : "Off"
                            checked: modelData.on
                            accent: Theme.tertiary
                            ink: root.ink
                            onClicked: root.source.toggleNetwork(modelData.id)
                        }
                    }
                }
                Item {
                    visible: !!root.source && root.source.exitNode !== ""
                    width: netCol.width
                    height: 32
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        StyledText {
                            text: "Internet exit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: root.ink
                        }
                        StyledText {
                            text: "0.0.0.0/0 · via " + (root.source ? root.source.exitNode : "")
                            font.pixelSize: 10
                            font.family: Theme.monoFontFamily
                            color: root.inkDim
                        }
                    }
                    ActionChip {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: "Stop"
                        ink: root.ink
                        onClicked: root.source.setExitNode("")
                    }
                }
                StyledText {
                    width: netCol.width
                    text: "Tip: drag the light at the surface onto a peer to send your Internet through it."
                    font.pixelSize: 10
                    color: root.inkDim
                }
            }
        }

        // A warning (relay down, management unreachable, silent peer)
        Rectangle {
            readonly property var omen: root.view.omens.length ? root.view.omens[0] : null
            readonly property string key: omen ? omen.text : ""
            visible: !!omen && root.omenHidden !== key && root.cardId === ""
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 24, omenText.implicitWidth + 58)
            height: 30
            radius: 15
            color: Theme.warning
            z: 25
            StyledText {
                id: omenText
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: hide.left
                anchors.verticalCenter: parent.verticalCenter
                text: "⚠ " + (parent.omen ? parent.omen.text : "")
                wrapMode: Text.NoWrap
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.abyss
            }
            MouseArea {
                id: hide
                anchors.right: parent.right
                width: 34
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                onClicked: root.omenHidden = parent.key
                StyledText {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: root.abyss
                }
            }
        }

        // Type-to-find hint
        Chip {
            visible: root.query !== ""
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 10
            title: "“" + root.query + "” → " + (root.findId && root.peerById[root.findId] ? root.peerById[root.findId].name : "no peer")
            sub: "Enter: open · Esc: clear"
            ink: root.ink
            z: 26
        }

        PeerCard {
            readonly property var p: root.cardId ? root.peerById[root.cardId] : null
            visible: !!p
            anchors.top: bar.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            width: Math.min(300, root.width * 0.58)
            z: 40
            scene: root
            source: root.source
            peer: p || ({ "id": "", "name": "", "kind": "desktop", "online": false, "down": 0, "up": 0, "rx": 0, "tx": 0, "ip": "", "fqdn": "" })
            tint: root.tintOf(peer.name)
            history: root.source && p && root.source.history[p.id] ? root.source.history[p.id] : []
            isTop: !!p && root.view.topId === p.id
            isExit: !!p && !!root.source && root.source.exitNode === p.name
            favorite: !!p && root.prefs.isFavorite(p.id)
            muted: !!p && root.prefs.isMuted(p.id)
            viaNetworks: root.source && p ? root.source.networks.filter(n => n.via === p.name) : []
            onClosed: root.cardId = ""
        }
    }

    // --- Keyboard: type a name to find a peer -----------------------------
    Timer {
        id: queryReset
        interval: 2600
        onTriggered: {
            root.query = "";
            root.findId = "";
        }
    }
    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (query !== "") {
                query = "";
                findId = "";
            } else if (cardId !== "" || netsOpen) {
                cardId = "";
                netsOpen = false;
            } else {
                return;
            }
            event.accepted = true;
            return;
        }
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && findId !== "") {
            cardId = findId;
            query = "";
            findId = "";
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Backspace && query !== "") {
            query = query.slice(0, -1);
        } else if (event.text && /^[\w.-]$/.test(event.text)) {
            query += event.text.toLowerCase();
        } else {
            return;
        }
        // Favorites first, then names that start with the query, then any match
        const list = view.peers.slice().sort((a, b) => (prefs.isFavorite(b.id) ? 1 : 0) - (prefs.isFavorite(a.id) ? 1 : 0));
        const hit = query === "" ? null : list.find(p => p.name.toLowerCase().startsWith(query)) || list.find(p => p.name.toLowerCase().indexOf(query) >= 0);
        findId = hit ? hit.id : "";
        queryReset.restart();
        event.accepted = true;
    }
}
