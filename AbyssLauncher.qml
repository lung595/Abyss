import QtQuick
import qs.Services
import "components"
import "components/LauncherItems.js" as LauncherItems

// Type "abyss" in the launcher (Super+Space): "Open Abyss" opens the deep
// from the bar, with everything it can do; below it, the quick steps
// (connect, where Internet goes out, copy an address, SSH). The launcher
// shows plain rows only, so the scene itself opens in the bar's popout.
// Created on the launcher's first opening; nothing runs between two uses.
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

    // One fresh read per launcher session, not one per keystroke
    property real _readAt: 0
    function _fresh() {
        const now = Date.now();
        if (now - _readAt > 5000) {
            source.refresh(now);
            _readAt = now;
        }
    }

    function getItems(query) {
        if (!source)
            return [];
        _fresh();
        const v = source.view;
        return LauncherItems.items({
            "status": v.state,
            "online": v.peers.filter(p => p.online).length,
            "total": v.peers.length,
            "peers": v.peers,
            "groups": prefs.groups,
            "exitNode": source.exitNode,
            "exitGroup": prefs.exitGroup
        }, query);
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
        else if (type === "ssh") {
            const p = daemon.findPeer(data);
            if (p)
                daemon.ssh(p.fqdn || p.ip);
        }
    }

    // dms ipc call plugins toggle abyss: DMS asks the launcher surface first
    function toggle() {
        opener.start();
    }

    Timer {
        id: opener
        interval: 150
        onTriggered: root.daemon.open()
    }
}
