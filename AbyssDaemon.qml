import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import "components"
import "components/Terminal.js" as Terminal
import "components/MyGroups.js" as MyGroups
import "components/Query.js" as Query

// The one engine every surface shares: the mesh source, the actions that
// leave the shell (copy, SSH, browser), notifications and the IPC.
// Surfaces find it with PluginService.pluginDaemonInstances["abyss"].
// Nothing runs here on its own: the source only reads while a view watches
// (once at start, `command -v netbird` says whether NetBird is installed).
// Privacy: peers and traffic stay in memory; nothing is written to disk
// except the user's settings, and the plugin never talks to the network.
Item {
    id: root

    property var pluginService: null
    property string pluginId: "abyss"

    // The mesh every surface draws: the NetBird daemon, or the test lab's
    // made-up mesh (setting "Mesh source"; "auto" takes NetBird when
    // its CLI is installed). Both have the same interface; only the one in
    // use exists. Null until the lookup below has answered.
    readonly property var source: sourceLoader.item
    readonly property bool useDemo: prefs.source === "demo" || (prefs.source === "auto" && !hasNetbird)
    // The `netbird` CLI is installed (looked up once, at start)
    property bool hasNetbird: false
    property bool _looked: false

    Loader {
        id: sourceLoader
        active: root._looked || root.prefs.source !== "auto"
        sourceComponent: root.useDemo ? demoSource : netbirdSource
    }
    Component {
        id: demoSource
        DemoSource {
            labMesh: prefs.labMesh
            labPeers: prefs.labPeers
            labLatency: prefs.labLatency
            labTrouble: prefs.labTrouble
            labTraffic: prefs.labTraffic
        }
    }
    Component {
        id: netbirdSource
        NetbirdSource {}
    }

    CliRunner {
        id: lookup
        Component.onCompleted: run(["sh", "-c", "command -v netbird"], (out, err, code) => {
            root.hasNetbird = code === 0;
            root._looked = true;
        })
    }

    // What the NetBird source could not do, said once
    Connections {
        target: root.source
        ignoreUnknownSignals: true
        function onNotice(text) {
            ToastService.showInfo("Abyss", text);
        }
    }

    readonly property alias prefs: prefs
    Prefs {
        id: prefs
    }

    // --- Actions (called by the scene's buttons and by the IPC) -------------
    // what: what was copied ("IP"), for the toast; one toast either way
    function copy(text, what) {
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", String(text)]);
        if (what)
            ToastService.showInfo(what + " copied", String(text));
        else
            ToastService.showInfo("Copied " + text);
    }

    // False when the host is not one ssh can safely be handed (says why).
    // The terminal is looked up first, so a missing one is said too
    function ssh(host, terminal) {
        if (!host)
            return false;
        const h = String(host), want = terminal || prefs.terminal;
        if (!Terminal.validHost(h)) {
            ToastService.showInfo("Abyss", "Not opening SSH: \"" + h + "\" is not a plain host name or address");
            return false;
        }
        lookup.run(Terminal.lookupCommand(want), (out, err, code) => {
            const found = String(out).trim();
            if (code !== 0 || !found)
                ToastService.showInfo("Abyss", Terminal.missingText(want));
            else
                Quickshell.execDetached(Terminal.sshCommand(found, h));
        });
        return true;
    }

    function openUrl(url) {
        Qt.openUrlExternally(url);
    }

    // The jellyfish's click: the one step that moves the connection forward
    function pressJelly() {
        const src = root.source;
        if (!src)
            return;
        const st = src.view.state;
        if (st === "needsLogin")
            src.login();
        else if (st === "stopped")
            src.startService();
        else
            src.toggle();
    }

    // The deep, in the bar's popout (the launcher, a keyboard shortcut).
    // Needs Abyss in the bar; otherwise says so
    function open() {
        if (BarWidgetService.triggerWidgetPopout("abyss"))
            return true;
        ToastService.showInfo("Abyss", "Add Abyss to the bar to open it from here");
        return false;
    }

    // A peer by name, fqdn, IP or id, or by the start of its name when only
    // one peer starts that way (for the IPC and the launcher); null otherwise
    function findPeer(key) {
        return root.source ? Query.lookup(root.source.view.peers, key).peer : null;
    }

    // --- Internet exit -------------------------------------------------------
    // Where Internet goes out now, in words: "directly", "through studio",
    // "through Homelab (studio)", or "through Homelab: nobody online"
    function exitText() {
        const src = root.source;
        if (!src)
            return "";
        const g = prefs.exitGroup ? MyGroups.byId(prefs.groups, prefs.exitGroup) : null;
        if (g)
            return "through " + g.name + (src.exitNode ? " (" + src.exitNode + ")" : ": nobody online");
        return src.exitNode ? "through " + src.exitNode : "directly";
    }

    // Through one peer (its name), through a group of mine (its id: the
    // group lends its best member, MyGroups.pickExit), or "" to stop
    function setExit(peerName, groupId) {
        if (!root.source)
            return;
        _choosing = true;
        prefs.set("exitGroup", groupId || "");
        if (groupId)
            _followExitGroup(groupId);
        else
            root.source.setExitNode(peerName || "");
        _choosing = false;
    }
    property bool _choosing: false
    // A group of mine carries the exit: when its member goes offline, the
    // next best takes over. Runs on each read, never on its own.
    function _followExitGroup(id) {
        const g = MyGroups.byId(prefs.groups, id);
        if (!g)
            return;
        const src = root.source;
        const p = MyGroups.pickExit(src.view.peers, g.members, src.exitNode);
        if (p && p.name !== src.exitNode)
            src.setExitNode(p.name);
    }
    Connections {
        target: root.source
        function onViewChanged() {
            if (prefs.exitGroup !== "")
                root._followExitGroup(prefs.exitGroup);
        }
        // An exit chosen elsewhere (the bar's menu, a profile switch) ends
        // the group's
        function onExitNodeChanged() {
            if (root._choosing || prefs.exitGroup === "")
                return;
            const g = MyGroups.byId(prefs.groups, prefs.exitGroup), p = root.findPeer(root.source.exitNode);
            if (!g || !p || g.members.indexOf(p.id) < 0)
                prefs.set("exitGroup", "");
        }
    }

    // --- Notifications (off by default, never for a muted peer) -------------
    Connections {
        target: root.source
        function onPeerEvent(name, online) {
            if (!prefs.notifications)
                return;
            const p = root.findPeer(name);
            if (p && prefs.isMuted(p.id))
                return;
            ToastService.showInfo(name + (online ? " is online" : " went offline"));
        }
    }

    // dms ipc call abyss open | status | toggle | connect | disconnect
    // dms ipc call abyss copy <peer> | ssh <peer>
    // dms ipc call abyss exit <peer | group of mine | off>
    // dms ipc call abyss demo connected | disconnected | connecting | needsLogin | stopped | relayDown | relayUp
    IpcHandler {
        target: "abyss"

        // One line: state, then how many peers are online
        function status(): string {
            if (!root.source)
                return "Abyss is starting";
            const v = root.source.view;
            const on = v.peers.filter(p => p.online).length;
            return v.state + (v.state === "connected" ? " · " + on + "/" + v.peers.length + " online · Internet " + root.exitText() : "");
        }

        // Opens (or closes) the deep in the bar's popout
        function open(): string {
            return root.open() ? "OK" : "Abyss is not in the bar";
        }

        function toggle(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.toggle();
            return "OK";
        }

        function connect(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.connect();
            return "OK";
        }

        function disconnect(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.disconnect();
            return "OK";
        }

        // Copies a peer's IP to the clipboard
        function copy(peer: string): string {
            if (!root.source)
                return "Abyss is starting";
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            root.copy(p.ip);
            return p.ip;
        }

        // Opens `ssh <peer>` in the terminal chosen in the settings
        function ssh(peer: string): string {
            if (!root.source)
                return "Abyss is starting";
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            return root.ssh(p.fqdn || p.ip) ? "OK" : "Refused: " + (p.fqdn || p.ip) + " is not a plain host name";
        }

        // Internet through a peer, a group of mine (by name), or "off";
        // "" says where it goes out now
        function exit(target: string): string {
            if (!root.source)
                return "Abyss is starting";
            const k = String(target || "").trim().toLowerCase();
            if (k === "")
                return "Internet goes out " + root.exitText();
            if (k === "off" || k === "none") {
                root.setExit("", "");
                return "Internet exit off";
            }
            const g = prefs.groups.find(x => x.name.toLowerCase() === k);
            if (g) {
                root.setExit("", g.id);
                return "Internet " + root.exitText();
            }
            const found = Query.lookup(root.source.view.peers, k), p = found.peer;
            if (!p)
                return found.many.length ? Query.lookupError(target, found) : "No peer or group named " + target;
            root.setExit(p.name, "");
            return "Internet through " + p.name;
        }

        // Jumps the demo mesh to a state, to try the interface
        function demo(state: string): string {
            if (!root.source)
                return "Abyss is starting";
            if (!root.source.demo)
                return "Not in demo mode";
            root.source.setState(state);
            return root.source.view.state;
        }
    }
}
