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
// Nothing runs here on its own: the source only reads while a view watches.
// Privacy: peers and traffic stay in memory; nothing is written to disk
// except the user's settings, and the plugin never talks to the network.
Item {
    id: root

    property var pluginService: null
    property string pluginId: "abyss"

    // For now a made-up mesh; the NetBird source will take its place with
    // the same interface (see components/DemoSource.qml)
    readonly property alias source: demo

    DemoSource {
        id: demo
    }

    Prefs {
        id: prefs
    }

    // --- Actions (called by the scene's buttons and by the IPC) -------------
    function copy(text) {
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", String(text)]);
        ToastService.showInfo("Copied " + text);
    }

    // False when the host is not one ssh can safely be handed (says why)
    function ssh(host, terminal) {
        if (!host)
            return false;
        const cmd = Terminal.sshCommand(terminal || prefs.terminal, String(host));
        if (!cmd) {
            ToastService.showInfo("Abyss", "Not opening SSH: \"" + host + "\" is not a plain host name or address");
            return false;
        }
        Quickshell.execDetached(cmd);
        return true;
    }

    function openUrl(url) {
        Qt.openUrlExternally(url);
    }

    // The jellyfish's click: the one step that moves the connection forward
    function pressJelly() {
        const st = source.view.state;
        if (st === "needsLogin")
            source.login();
        else if (st === "stopped")
            source.startService();
        else
            source.toggle();
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
        return Query.lookup(source.view.peers, key).peer;
    }

    // --- Internet exit -------------------------------------------------------
    // Through one peer (its name), through a group of mine (its id: the
    // group lends its best member, MyGroups.pickExit), or "" to stop
    function setExit(peerName, groupId) {
        _choosing = true;
        prefs.set("exitGroup", groupId || "");
        if (groupId)
            _followExitGroup(groupId);
        else
            source.setExitNode(peerName || "");
        _choosing = false;
    }
    property bool _choosing: false
    // A group of mine carries the exit: when its member goes offline, the
    // next best takes over. Runs on each read, never on its own.
    function _followExitGroup(id) {
        const g = MyGroups.byId(prefs.groups, id);
        if (!g)
            return;
        const p = MyGroups.pickExit(source.view.peers, g.members, source.exitNode);
        if (p && p.name !== source.exitNode)
            source.setExitNode(p.name);
    }
    Connections {
        target: demo
        function onViewChanged() {
            if (prefs.exitGroup !== "")
                root._followExitGroup(prefs.exitGroup);
        }
        // An exit chosen elsewhere (the bar's menu, a profile switch) ends
        // the group's
        function onExitNodeChanged() {
            if (root._choosing || prefs.exitGroup === "")
                return;
            const g = MyGroups.byId(prefs.groups, prefs.exitGroup), p = root.findPeer(demo.exitNode);
            if (!g || !p || g.members.indexOf(p.id) < 0)
                prefs.set("exitGroup", "");
        }
    }

    // --- Notifications (off by default, never for a muted peer) -------------
    Connections {
        target: demo
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
            const v = root.source.view;
            const on = v.peers.filter(p => p.online).length;
            return v.state + (v.state === "connected" ? " · " + on + "/" + v.peers.length + " online" : "");
        }

        // Opens (or closes) the deep in the bar's popout
        function open(): string {
            return root.open() ? "OK" : "Abyss is not in the bar";
        }

        function toggle(): string {
            root.source.toggle();
            return "OK";
        }

        function connect(): string {
            root.source.connect();
            return "OK";
        }

        function disconnect(): string {
            root.source.disconnect();
            return "OK";
        }

        // Copies a peer's IP to the clipboard
        function copy(peer: string): string {
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            root.copy(p.ip);
            return p.ip;
        }

        // Opens `ssh <peer>` in the terminal chosen in the settings
        function ssh(peer: string): string {
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            return root.ssh(p.fqdn || p.ip) ? "OK" : "Refused: " + (p.fqdn || p.ip) + " is not a plain host name";
        }

        // Internet through a peer, a group of mine (by name), or "off"
        function exit(target: string): string {
            const k = String(target || "").trim().toLowerCase();
            if (k === "" || k === "off" || k === "none") {
                root.setExit("", "");
                return "Internet exit off";
            }
            const g = prefs.groups.find(x => x.name.toLowerCase() === k);
            if (g) {
                root.setExit("", g.id);
                return "Internet through " + g.name + (root.source.exitNode ? " (" + root.source.exitNode + ")" : ": nobody online");
            }
            const found = Query.lookup(root.source.view.peers, k), p = found.peer;
            if (!p)
                return found.many.length ? Query.lookupError(target, found) : "No peer or group named " + target;
            root.setExit(p.name, "");
            return "Internet through " + p.name;
        }

        // Jumps the demo mesh to a state, to try the interface
        function demo(state: string): string {
            if (!root.source.demo)
                return "Not in demo mode";
            root.source.setState(state);
            return root.source.view.state;
        }
    }
}
