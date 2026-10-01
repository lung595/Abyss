import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "components"
import "components/Terminal.js" as Terminal

// Plugin settings. Everything works out of the box; each option says in one
// short line what it changes.
PluginSettings {
    id: root
    pluginId: "abyss"

    // Filled in by DMS when this page opens from Settings > Desktop Widgets
    property string instanceId: ""
    property var instanceData: null

    // Section title with air above it: hierarchy from size and weight only
    component Section: StyledText {
        width: parent ? parent.width : 0
        topPadding: Theme.spacingXL
        bottomPadding: Theme.spacingXS
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // Only shown once a jar sits on the desktop
    Section {
        topPadding: 0
        text: "Desktop"
        visible: desktopScreens.visible
    }

    DesktopScreens {
        id: desktopScreens
        instanceId: root.instanceId
    }

    ToggleSetting {
        visible: desktopScreens.visible
        settingKey: "desktopLive"
        label: "Keep the desktop alive"
        description: "Otherwise it only moves under the pointer · ⚡ Uses more battery"
        defaultValue: false
    }

    Section {
        topPadding: desktopScreens.visible ? Theme.spacingXL : 0
        text: "The deep"
    }

    SliderSetting {
        settingKey: "maxItems"
        label: "Things on screen"
        description: "Beyond this, peers gather in groups you can dive into"
        defaultValue: 5
        minimum: 3
        maximum: 10
    }

    SelectionSetting {
        settingKey: "groupOpen"
        label: "Open groups"
        description: "Carrying the Internet light, resting on a group always opens it"
        options: [
            {
                "label": "On hover and click",
                "value": "both"
            },
            {
                "label": "On hover",
                "value": "hover"
            },
            {
                "label": "On click",
                "value": "click"
            }
        ]
        defaultValue: "both"
    }

    ToggleSetting {
        settingKey: "showOffline"
        label: "Show offline peers"
        description: "Asleep on the sea floor"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "pulses"
        label: "Light pulses"
        description: "Traffic running along the tentacles"
        defaultValue: true
    }

    Section {
        text: "Peers"
    }

    ToggleSetting {
        settingKey: "notifications"
        label: "Notifications"
        description: "When a peer comes online or goes offline (muted peers stay quiet)"
        defaultValue: false
    }

    SelectionSetting {
        settingKey: "terminal"
        label: "Terminal for SSH"
        description: "Automatic tries the usual ones"
        options: Terminal.options()
        defaultValue: "auto"
    }

    Section {
        text: "NetBird"
    }

    SelectionSetting {
        settingKey: "source"
        label: "Mesh source"
        description: "Automatic reads NetBird when it is installed, the demo mesh otherwise"
        options: [
            {
                "label": "Automatic",
                "value": "auto"
            },
            {
                "label": "NetBird",
                "value": "netbird"
            },
            {
                "label": "Demo mesh",
                "value": "demo"
            }
        ]
        defaultValue: "auto"
    }
}
