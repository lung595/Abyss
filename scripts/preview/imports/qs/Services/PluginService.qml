pragma Singleton
import QtQuick
import qs.Common
QtObject {
    id: svc
    signal pluginDataChanged(string pluginId)
    property var globalVars: ({})
    property var pluginDaemonInstances: ({})
    function setGlobalVar(id, k, v) {}
    // Kept in memory, so the preview can make groups and pick an exit
    function savePluginData(id, k, v) {
        const next = Object.assign({}, SettingsData.pluginSettings);
        next[k] = v;
        SettingsData.pluginSettings = next;
        svc.pluginDataChanged(id);
    }
}
