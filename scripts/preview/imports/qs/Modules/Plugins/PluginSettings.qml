import QtQuick
import qs.Common
import qs.Services
// Preview stand-in for DMS's PluginSettings: same reparenting of its
// children into one column, values kept in the preview's PluginService
Item {
    id: root
    required property string pluginId
    property var pluginService: PluginService
    default property list<QtObject> content
    implicitHeight: col.implicitHeight
    height: implicitHeight
    onContentChanged: {
        for (let i = 0; i < content.length; i++)
            if (content[i] instanceof Item)
                content[i].parent = col;
    }
    function saveValue(key, value) {
        PluginService.savePluginData(pluginId, key, value);
    }
    function loadValue(key, def) {
        const v = SettingsData.pluginSettings[key];
        return v === undefined ? def : v;
    }
    Column {
        id: col
        width: parent.width
        spacing: Theme.spacingM
    }
}
