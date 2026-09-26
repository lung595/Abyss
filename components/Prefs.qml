import QtQuick
import qs.Common
import qs.Services

// Reactive view over the plugin's saved settings, shared by every surface.
QtObject {
    id: root

    readonly property string pluginId: "abyss"

    property var _data: SettingsData.getPluginSettingsForPlugin(pluginId) || ({})

    function _get(key, def) {
        const v = _data[key];
        return v === undefined || v === null ? def : v;
    }

    // Offline peers resting on the sea floor (otherwise hidden)
    readonly property bool showOffline: _get("showOffline", true)
    // Light pulses running along the tentacles while a view is open
    readonly property bool pulses: _get("pulses", true)
    // A toast when a peer comes online or goes offline
    readonly property bool notifications: _get("notifications", false)
    // Terminal used for SSH ("auto" tries the usual ones)
    readonly property string terminal: _get("terminal", "auto")
    // Desktop: keep the deep alive when the pointer is elsewhere
    readonly property bool desktopLive: _get("desktopLive", false)
    // Peers the user muted (no notifications, drawn asleep): id -> name
    readonly property var muted: _get("muted", ({}))
    // Peers the user pinned (a star, listed first when searching): id -> name
    readonly property var favorites: _get("favorites", ({}))

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
