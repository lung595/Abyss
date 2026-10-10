pragma Singleton
import QtQuick
import qs.Common
QtObject {
    id: svc
    signal pluginDataChanged(string pluginId)
    property var globalVars: ({})
    property var pluginDaemonInstances: ({})
    // The launcher prefix the owner set in DMS ("" = none)
    property string launcherTrigger: ""
    function getPluginTrigger(id) { return launcherTrigger; }
    function setGlobalVar(id, k, v) {}
    // Kept in memory, so the preview can make groups and pick an exit
    function savePluginData(id, k, v) {
        const next = Object.assign({}, SettingsData.pluginSettings);
        next[k] = v;
        SettingsData.pluginSettings = next;
        svc.pluginDataChanged(id);
    }
}
