import QtQuick
import Quickshell
import qs.Services
import "components"
import "components/LauncherItems.js" as LauncherItems
import "components/SendIntent.js" as SendIntent

// Type "abyss" in the launcher (Super+Space): "Open Abyss" opens the deep
// from the bar, with everything it can do; below it, the quick steps
// (connect, where Internet goes out, copy an address, SSH). The launcher
// shows plain rows only, so the scene itself opens in the bar's popout.
// With no prefix set in DMS the launcher hands over every search: Abyss only
// answers the "abyss" word and a "send a file (to vega)" sentence. Created on
// the launcher's first opening; nothing runs between two uses.
Item {
    id: root

    property var pluginService: null
    property string trigger: "abyss"

    signal itemsChanged

    readonly property var daemon: PluginService.pluginDaemonInstances["abyss"] ?? null
    readonly property var source: daemon ? daemon.source : null

    Prefs {
        id: prefs
    }

    // One fresh read per launcher session, not one per keystroke. The
    // NetBird source answers later: the rows are asked for again once, when
    // that read lands (never on the reads of an open view)
    property real _readAt: 0
    property bool _waiting: false
    function _fresh() {
        const now = Date.now();
        if (now - root._readAt > 5000) {
            root.source.refresh(now);
            root._readAt = now;
            root._waiting = !root.source.demo;
        }
    }
    Connections {
        target: root.source
        function onViewChanged() {
            if (!root._waiting)
                return;
            root._waiting = false;
            root.itemsChanged();
        }
    }

    function getItems(query) {
        if (!source)
            return [];
        // The prefix DMS strips, if the owner set one (the manifest's default)
        const prefixed = !!(PluginService.getPluginTrigger("abyss") ?? "").trim();
        const route = LauncherItems.route(query, source.view.peers, prefixed);
        if (!route)
            return [];
        // A send sentence reads the peers once, or a device named right after
        // the shell started would not be found (the rows are asked again then)
        if (route.ask)
            _fresh();
        if (route.send !== undefined)
            return [LauncherItems.sendEntry(route.send)];
        if (route.ask)
            return [];
        _fresh();
        const v = source.view;
        return LauncherItems.items({
            "status": v.state,
            "online": v.peers.filter(p => p.online).length,
            "total": v.peers.length,
            "peers": v.peers,
            "groups": prefs.groups,
            "relays": v.relays.map(r => r.name),
            "exitNode": source.exitNode,
            "exitGroup": prefs.exitGroup
        }, route.all);
    }

    function executeItem(item) {
        const a = String(item.action || ""), i = a.indexOf(":");
        const type = a.slice(0, i), data = a.slice(i + 1);
        if (type === "open")
            // After the launcher has closed, or its closing would take the
            // popout's focus away
            opener.start();
        else if (type === "toggle")
            daemon.pressJelly();
        else if (type === "exit")
            data === "off" ? daemon.setExit("", "") : data.indexOf("group:") === 0 ? daemon.setExit("", data.slice(6)) : daemon.setExit(data.slice(5), "");
        else if (type === "copy")
            daemon.copy(daemon.findPeer(data)?.ip);
        else if (type === "send") {
            // With the app installed it opens on sending; without it, the picker
            // opens once the launcher has closed, or it would be lost behind it
            sender.device = data;
            sender.start();
        } else if (type === "ssh") {
            const p = daemon.findPeer(data);
            if (p)
                daemon.ssh(p.fqdn || p.ip);
        }
    }

    // dms ipc call plugins toggle abyss: DMS asks the launcher surface first
    function toggle() {
        opener.start();
    }

    // "Send a file…": the `abyss` command when it is installed (argument list,
    // the name already validated), otherwise the picker of the widget
    AppLookup {
        id: sender
        property string device: ""

        onFound: installed => {
            const argv = SendIntent.appCommand(sender.device);
            // Detached: the app must outlive the launcher, and the shell
            if (installed && argv) {
                Quickshell.execDetached(argv);
                return;
            }
            picker.peer = root.daemon.findPeer(sender.device);
            if (picker.peer)
                picker.start();
            else
                opener.start();
        }
    }

    Timer {
        id: picker
        property var peer: null
        interval: 150
        onTriggered: root.daemon.send.pick(peer, false)
    }

    Timer {
        id: opener
        interval: 150
        onTriggered: root.daemon.open()
    }
}
