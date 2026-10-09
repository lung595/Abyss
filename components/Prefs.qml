import QtQuick
import qs.Common
import qs.Services
import "Send.js" as Send

// Reactive view over the plugin's saved settings, shared by every surface.
QtObject {
    id: root

    readonly property string pluginId: "abyss"

    property var _data: SettingsData.getPluginSettingsForPlugin(pluginId) || ({})

    function _get(key, def) {
        const v = _data[key];
        return v === undefined || v === null ? def : v;
    }

    // Where the mesh comes from: "auto" (NetBird when installed), "netbird"
    // or "demo" (a made-up mesh)
    readonly property string source: _get("source", "auto")
    // Offline peers resting on the sea floor (otherwise hidden)
    readonly property bool showOffline: _get("showOffline", true)
    // Light pulses running along the tentacles while a view is open
    readonly property bool pulses: _get("pulses", true)
    // A toast when a peer comes online or goes offline
    readonly property bool notifications: _get("notifications", false)
    // Terminal used for SSH ("auto" tries the usual ones)
    readonly property string terminal: _get("terminal", "auto")
    // The folder on the receiving device that sent files land in ("~" is its
    // home); Send.remoteDir turns it into what scp takes
    readonly property string sendFolder: _get("sendFolder", Send.DEFAULT_DIR)
    // How to reach each peer over SSH: peer id -> { user, port } (a phone
    // running Termux listens on 8022 and has its own user)
    readonly property var links: _get("links", ({}))
    // This device lets the other peers SSH in (NetBird's SSH server)
    readonly property bool shareSsh: _get("shareSsh", false)
    // Effects (Settings > Effects & battery): 60 fps while things move (else
    // 30), creatures swaying, bubbles when a new device joins
    readonly property bool smooth: _get("smooth", true)
    readonly property bool drift: _get("drift", true)
    readonly property bool celebrate: _get("celebrate", true)
    // Bar: a coloured dot for the state; middle click connects
    readonly property bool statusDot: _get("statusDot", true)
    readonly property bool middleToggle: _get("middleToggle", true)
    // Shortcuts under the empty search bar
    readonly property bool searchHints: _get("searchHints", true)
    // Desktop: keep the deep alive when the pointer is elsewhere
    readonly property bool desktopLive: _get("desktopLive", false)
    // How many things the deep shows at once; more peers gather in groups
    readonly property int maxItems: _get("maxItems", 5)
    // What the bar pill shows beside the jellyfish: "peers" (how many are
    // online), "rate" (the total traffic) or "icon" (nothing)
    readonly property string pill: _get("pill", "peers")
    // Darwin, the goldfish companion (only moves while a view is open)
    readonly property bool companion: _get("companion", true)
    // How a group opens: "both" (resting the pointer on it, or a click),
    // "hover" or "click"
    readonly property string groupOpen: _get("groupOpen", "both")
    // Peers the user muted (no notifications, drawn asleep): id -> name
    readonly property var muted: _get("muted", ({}))
    // Peers the user pinned (a star, listed first when searching): id -> name
    readonly property var favorites: _get("favorites", ({}))
    // The user's own groups (right-click a creature): [{ id, name, members }]
    readonly property var groups: _get("groups", [])
    // Which peer each exit route goes through, once seen (route id -> peer
    // id): exit routes named after no peer are then lent by the right one
    readonly property var exitTies: _get("exitTies", ({}))
    // Internet through a whole group of mine (its id), "" otherwise
    readonly property string exitGroup: _get("exitGroup", "")

    // Test lab (Mesh source = Test lab): the made-up mesh to try things on.
    // labMesh "home", "work", "crowd" or "lab" (labPeers peers); labLatency
    // ms added to every peer; labTrouble what goes wrong (DemoSource);
    // labTraffic "calm", "normal" or "rush"
    readonly property string labMesh: _get("labMesh", "home")
    readonly property int labPeers: _get("labPeers", 24)
    readonly property int labLatency: _get("labLatency", 0)
    readonly property string labTrouble: _get("labTrouble", "none")
    readonly property string labTraffic: _get("labTraffic", "normal")
    readonly property bool labLazy: _get("labLazy", false)

    readonly property bool reduceMotion: SettingsData.reduceMotion

    function set(key, value) {
        PluginService.savePluginData(pluginId, key, value);
    }

    function _toggleIn(key, map, id, name) {
        const next = Object.assign({}, map);
        if (next[id] !== undefined)
            delete next[id];
        else
            next[id] = name || id;
        set(key, next);
    }

    function isMuted(id) {
        return !!id && muted[id] !== undefined;
    }
    function isFavorite(id) {
        return !!id && favorites[id] !== undefined;
    }
    function linkOf(id) {
        return links[id] || ({});
    }
    function setLink(id, user, port) {
        const next = Object.assign({}, links);
        if (!user && !port)
            delete next[id];
        else
            next[id] = { "user": user || "", "port": port || "" };
        set("links", next);
    }
    function toggleMuted(id, name) {
        _toggleIn("muted", muted, id, name);
    }
    function toggleFavorite(id, name) {
        _toggleIn("favorites", favorites, id, name);
    }

    property Connections _watch: Connections {
        target: PluginService
        function onPluginDataChanged(changedId) {
            if (changedId === root.pluginId)
                root._data = SettingsData.getPluginSettingsForPlugin(root.pluginId) || ({});
        }
    }
}
