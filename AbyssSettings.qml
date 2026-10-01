import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "components"
import "components/Terminal.js" as Terminal

// Plugin settings. Everything works out of the box; each option says in one
// short line what it changes. Four short sections, and a fifth, the test
// lab, that only shows while the lab is the mesh source.
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
        description: "Otherwise it moves only under the pointer · ⚡ more battery"
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

    ToggleSetting {
        settingKey: "companion"
        label: "Companion"
        description: "Darwin the goldfish: eats the traffic's crumbs, cleans the glass, waves when clicked"
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
        text: "Source"
    }

    SelectionSetting {
        id: source
        settingKey: "source"
        label: "Mesh source"
        description: "Automatic: NetBird when installed, the test lab otherwise. Abyss itself never goes online"
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
                "label": "Test lab",
                "value": "demo"
            }
        ]
        defaultValue: "auto"
    }

    // --- Test lab: a made-up mesh to try groups, latency and failures on.
    // Shown only while it is the source; nothing here touches NetBird.
    LabHeader {
        id: lab
        visible: source.value === "demo"
        summary: {
            const mesh = ({
                    "home": "10 peers",
                    "work": "5 peers",
                    "crowd": "30 peers",
                    "lab": labPeers.value + (labPeers.value === 1 ? " peer" : " peers")
                })[labMesh.value] || "";
            const trouble = ({
                    "silent": "a peer stops answering",
                    "flap": "a peer keeps dropping out",
                    "relay": "a relay is down",
                    "management": "management unreachable",
                    "signedOut": "signed out",
                    "stopped": "service stopped"
                })[labTrouble.value];
            return [mesh, labLatency.value ? "+" + labLatency.value + " ms" : "", trouble || "", ({
                        "calm": "calm links",
                        "rush": "rush hour"
                    })[labTraffic.value] || "", labLazy.value ? "lazy connections" : ""].filter(s => s).join(" · ");
        }
        // Back to a quiet home mesh, in one click
        dirty: labMesh.value !== "home" || labLatency.value !== 0 || labTrouble.value !== "none" || labTraffic.value !== "normal" || labLazy.value
        onReset: {
            labMesh.value = "home";
            labLatency.value = 0;
            labTrouble.value = "none";
            labTraffic.value = "normal";
            labLazy.value = false;
        }
    }

    SelectionSetting {
        id: labMesh
        visible: lab.visible
        settingKey: "labMesh"
        label: "Mesh"
        description: "Custom size to see how groups form"
        options: [
            {
                "label": "Home · 10 peers",
                "value": "home"
            },
            {
                "label": "Work · 5 peers",
                "value": "work"
            },
            {
                "label": "Crowd · 30 peers",
                "value": "crowd"
            },
            {
                "label": "Custom size",
                "value": "lab"
            }
        ]
        defaultValue: "home"
    }

    SliderSetting {
        id: labPeers
        visible: lab.visible && labMesh.value === "lab"
        settingKey: "labPeers"
        label: "Peers"
        defaultValue: 24
        minimum: 1
        maximum: 120
    }

    SliderSetting {
        id: labLatency
        visible: lab.visible
        settingKey: "labLatency"
        label: "Added latency"
        description: "On every peer: they sink deeper and may switch places"
        defaultValue: 0
        minimum: 0
        maximum: 400
        unit: "ms"
    }

    SelectionSetting {
        id: labTrouble
        visible: lab.visible
        settingKey: "labTrouble"
        label: "Trouble"
        description: "Applied when chosen; the jellyfish still connects and disconnects"
        options: [
            {
                "label": "None",
                "value": "none"
            },
            {
                "label": "A peer stops answering",
                "value": "silent"
            },
            {
                "label": "A peer keeps dropping out",
                "value": "flap"
            },
            {
                "label": "A relay goes down",
                "value": "relay"
            },
            {
                "label": "Management unreachable",
                "value": "management"
            },
            {
                "label": "Signed out",
                "value": "signedOut"
            },
            {
                "label": "Service stopped",
                "value": "stopped"
            }
        ]
        defaultValue: "none"
    }

    SelectionSetting {
        id: labTraffic
        visible: lab.visible
        settingKey: "labTraffic"
        label: "Traffic"
        options: [
            {
                "label": "Calm",
                "value": "calm"
            },
            {
                "label": "Normal",
                "value": "normal"
            },
            {
                "label": "Rush hour",
                "value": "rush"
            }
        ]
        defaultValue: "normal"
    }

    ToggleSetting {
        id: labLazy
        visible: lab.visible
        settingKey: "labLazy"
        label: "Lazy connections"
        description: "Idle peers doze in the water: NetBird wakes them on use"
        defaultValue: false
    }
}
