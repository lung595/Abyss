import QtQuick
import qs.Common
import qs.Modules.Settings.Widgets

// "Which screens show the desktop jar" setting. DMS already filters desktop
// widgets by screen through each instance's config.displayPreferences; its
// own picker only shows for plugins without a settings page, so Abyss hosts
// the same native picker here.
Item {
    id: root

    // Set when opened from Settings > Desktop Widgets (that one jar only);
    // empty from the Plugins page, where every Abyss jar follows the choice.
    property string instanceId: ""

    readonly property var targets: {
        const all = SettingsData.desktopWidgetInstances || [];
        if (instanceId)
            return all.filter(inst => inst.id === instanceId);
        return all.filter(inst => inst.widgetType === "abyss");
    }

    // Nothing to choose until a jar sits on the desktop
    visible: targets.length > 0
    width: parent ? parent.width : 0
    height: visible ? picker.height : 0

    SettingsDisplayPicker {
        id: picker
        // The native picker insets itself; cancel that so its rows line up
        // with the other settings on this page.
        x: -Theme.spacingM
        width: root.width + Theme.spacingM * 2
        displayPreferences: root.targets.length > 0 ? (root.targets[0].config?.displayPreferences ?? ["all"]) : ["all"]
        onPreferencesChanged: prefs => {
            for (const inst of root.targets)
                SettingsData.updateDesktopWidgetInstanceConfig(inst.id, {
                    "displayPreferences": prefs
                });
        }
    }
}
