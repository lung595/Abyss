import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import "components"
import "components/Terminal.js" as Terminal

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

    function ssh(host, terminal) {
        if (host)
            Quickshell.execDetached(Terminal.sshCommand(terminal || prefs.terminal, String(host)));
    }

    function openUrl(url) {
        Qt.openUrlExternally(url);
    }

    // A peer by name, id or IP (for the IPC)
    function findPeer(key) {
        const k = String(key || "").toLowerCase();
        return source.view.peers.find(p => p.name.toLowerCase() === k || p.id === k || p.ip === k) || source.view.peers.find(p => p.name.toLowerCase().startsWith(k)) || null;
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

    // dms ipc call abyss status | toggle | connect | disconnect
    // dms ipc call abyss copy <peer> | ssh <peer>
    // dms ipc call abyss demo connected | disconnected | connecting | needsLogin | stopped | relayDown | relayUp
    IpcHandler {
        target: "abyss"

        // One line: state, then how many peers are online
        function status(): string {
            const v = root.source.view;
            const on = v.peers.filter(p => p.online).length;
            return v.state + (v.state === "connected" ? " · " + on + "/" + v.peers.length + " online" : "");
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
            const p = root.findPeer(peer);
            if (!p)
                return "No peer named " + peer;
            root.copy(p.ip);
            return p.ip;
        }

        // Opens `ssh <peer>` in the terminal chosen in the settings
        function ssh(peer: string): string {
            const p = root.findPeer(peer);
            if (!p)
                return "No peer named " + peer;
            root.ssh(p.fqdn || p.ip);
            return "OK";
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
