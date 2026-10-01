pragma Singleton
import QtQuick
QtObject {
    property bool reduceMotion: false
    property var pluginSettings: ({})
    function getPluginSettingsForPlugin(id) { return pluginSettings; }
}
