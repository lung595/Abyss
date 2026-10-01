import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "components"
import "components/Terminal.js" as Terminal

// Plugin settings, as tabs: one short subject each, a title with an icon,
// and one plain line under every option. Anything that costs battery or
// smoothness says so right under it (⚡). Everything works out of the box.
PluginSettings {
    id: root
    pluginId: "abyss"

    // Filled in by DMS when this page opens from Settings > Desktop Widgets
    property string instanceId: ""
    property var instanceData: null

    readonly property var daemon: PluginService.pluginDaemonInstances["abyss"] ?? null
    readonly property var src: daemon ? daemon.source : null
    readonly property var prefs: daemon ? daemon.prefs : null

    Item {
        id: page
        width: parent ? parent.width : 0
        implicitHeight: tabs.height + Theme.spacingM + panel.height
        height: implicitHeight

        // Opened from Desktop Widgets: straight to the desktop tab
        property string tab: root.instanceId ? "desktop" : "connect"

        readonly property var tabList: [
            { "id": "connect", "icon": "hub", "text": "Connect", "title": "Connections", "sub": "Join a mesh, let your devices in, and how Abyss opens them" },
            { "id": "deep", "icon": "water", "text": "The deep", "title": "The deep", "sub": "What the sea shows, and how much of it at once" },
            { "id": "effects", "icon": "bolt", "text": "Effects & battery", "title": "Effects & battery", "sub": "Every moving thing, and what it costs. Off = calmer and longer battery" },
            { "id": "bar", "icon": "toolbar", "text": "Bar & alerts", "title": "Bar & alerts", "sub": "The small jellyfish in your bar, and when Abyss speaks up" },
            { "id": "desktop", "icon": "desktop_windows", "text": "Desktop", "title": "Desktop fishbowl", "sub": "The round jar on your wallpaper" },
            { "id": "source", "icon": "science", "text": "Source & lab", "title": "Source & test lab", "sub": "Your real NetBird, or a made-up mesh to try things on" },
            { "id": "help", "icon": "menu_book", "text": "Help", "title": "Quick guide", "sub": "Everything in Abyss, in one minute" }
        ]
        readonly property var current: tabList.find(t => t.id === tab) || tabList[0]

        // --- Tabs: chips that wrap, the chosen one lit -----------------------
        Flow {
            id: tabs
            width: parent.width
            spacing: Theme.spacingS
            Repeater {
                model: page.tabList
                Rectangle {
                    required property var modelData
                    readonly property bool on: page.tab === modelData.id
                    height: 36
                    width: tabRow.implicitWidth + 28
                    radius: 18
                    color: on ? Qt.tint(Theme.surfaceContainerHigh, Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)) : tabArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.width: on ? 1.5 : 0
                    border.color: Theme.primary
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 7
                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: modelData.icon
                            size: 17
                            color: parent.parent.on ? Theme.primary : Theme.surfaceText
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: parent.parent.on ? Font.DemiBold : Font.Normal
                            color: parent.parent.on ? Theme.primary : Theme.surfaceText
                        }
                    }
                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.tab = modelData.id
                    }
                }
            }
        }

        // --- The chosen tab's panel ------------------------------------------
        Rectangle {
            id: panel
            y: tabs.height + Theme.spacingM
            width: parent.width
            height: body.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadius * 1.5
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.18)

            Column {
                id: body
                x: Theme.spacingL
                y: Theme.spacingL
                width: parent.width - Theme.spacingL * 2
                spacing: Theme.spacingL

                // Title with its icon, and what the tab is about
                Column {
                    width: parent.width
                    spacing: 4
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: page.current.icon
                            size: 20
                            color: Theme.primary
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: page.current.title
                            font.pixelSize: Theme.fontSizeLarge + 2
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: page.current.sub
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }

                // ===== Connect ===================================================
                Column {
                    visible: page.tab === "connect"
                    width: parent.width
                    spacing: Theme.spacingL

                    Group {
                        icon: "add_link"
                        title: "Add this computer to a mesh"
                        sub: "Paste a setup key from NetBird's dashboard (Setup Keys). Your phone? Use the + in the deep: it shows a QR code"
                        Field {
                            id: keyField
                            width: parent.width
                            placeholder: "Setup key, e.g. A1B2C3D4-E5F6-…"
                            secret: true
                        }
                        Field {
                            id: urlField
                            visible: selfHosted.on
                            width: parent.width
                            placeholder: "Your server, e.g. https://netbird.example.org"
                        }
                        Item {
                            width: parent.width
                            height: 34
                            Check {
                                id: selfHosted
                                anchors.verticalCenter: parent.verticalCenter
                                text: "I host my own NetBird server"
                            }
                            Button {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "login"
                                text: "Join"
                                primary: true
                                enabled: keyField.text.trim().length >= 8 && !!root.src
                                onClicked: {
                                    const ok = root.src.join(keyField.text, selfHosted.on ? urlField.text : "", "");
                                    joinNote.text = ok ? "Joining… the jellyfish lights up when you are in" : "That is not a setup key (or the address is not https://…)";
                                    joinNote.bad = !ok;
                                    if (ok)
                                        keyField.text = "";
                                }
                            }
                        }
                        StyledText {
                            id: joinNote
                            property bool bad: false
                            visible: text !== ""
                            width: parent.width
                            font.pixelSize: Theme.fontSizeSmall
                            color: bad ? Theme.error : Theme.primary
                            wrapMode: Text.WordWrap
                        }
                    }

                    Group {
                        icon: "login"
                        title: "Let my devices into this computer"
                        sub: "Your phone and other peers can open a terminal here. Uses NetBird's own SSH: nothing else to install"
                        ToggleSetting {
                            settingKey: "shareSsh"
                            label: "Allow SSH into this computer"
                            description: "Only devices of your mesh, as NetBird's access rules allow"
                            defaultValue: false
                        }
                    }

                    Group {
                        icon: "terminal"
                        title: "Opening a device"
                        sub: "Terminal, Files, Screen and Desktop on a device's card"
                        SelectionSetting {
                            settingKey: "terminal"
                            label: "Terminal"
                            description: "Used by Terminal and SFTP. Automatic picks the first one installed"
                            options: Terminal.options()
                            defaultValue: "auto"
                        }
                        StyledText {
                            width: parent.width
                            text: "Screen opens Remmina, vncviewer or KRDC; Desktop opens FreeRDP, Remmina or KRDC; Files opens your file manager. If none is there, Abyss says what to install."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                        }
                    }

                    Group {
                        icon: "key"
                        title: "Saved logins"
                        sub: "The user and port remembered per device (set them on a device's card)"
                        Repeater {
                            model: root.prefs ? Object.keys(root.prefs.links) : []
                            Rectangle {
                                required property string modelData
                                readonly property var link: root.prefs.links[modelData] || ({})
                                readonly property var peer: root.src ? root.src.view.peers.find(p => p.id === modelData) : null
                                width: parent.width
                                height: 40
                                radius: 10
                                color: Theme.surfaceContainerHigh
                                DankIcon {
                                    x: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "devices"
                                    size: 18
                                    color: Theme.surfaceVariantText
                                }
                                StyledText {
                                    x: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 140
                                    elide: Text.ElideRight
                                    text: (parent.peer ? parent.peer.name : "A device not in this mesh") + "  ·  " + (parent.link.user || "you") + (parent.link.port ? " · port " + parent.link.port : "")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }
                                Button {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "delete"
                                    text: "Forget"
                                    onClicked: root.prefs.setLink(parent.modelData, "", "")
                                }
                            }
                        }
                        StyledText {
                            visible: !root.prefs || Object.keys(root.prefs.links).length === 0
                            width: parent.width
                            text: "None yet: Abyss logs in as you, on port 22."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }
                }

                // ===== The deep ==================================================
                Column {
                    visible: page.tab === "deep"
                    width: parent.width
                    spacing: Theme.spacingL

                    SliderSetting {
                        settingKey: "maxItems"
                        label: "Things on screen"
                        description: "Beyond this, devices gather in groups you can dive into"
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
                        label: "Show offline devices"
                        description: "Asleep on the sea floor; off hides them"
                        defaultValue: true
                    }
                    ToggleSetting {
                        settingKey: "searchHints"
                        label: "Search suggestions"
                        description: "Shortcuts like Phones or Slow under the empty search bar"
                        defaultValue: true
                    }
                }

                // ===== Effects & battery =========================================
                Column {
                    visible: page.tab === "effects"
                    width: parent.width
                    spacing: Theme.spacingL

                    Rectangle {
                        visible: SettingsData.reduceMotion
                        width: parent.width
                        height: rmText.implicitHeight + 16
                        radius: 10
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        StyledText {
                            id: rmText
                            x: 12
                            width: parent.width - 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Reduce motion is on in DMS: everything below stays still anyway."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                            wrapMode: Text.WordWrap
                        }
                    }
                    Effect {
                        settingKey: "smooth"
                        label: "Smooth motion (60 fps)"
                        description: "Off: 30 fps while things move. Still looks good"
                        defaultValue: true
                        impact: "high"
                        cost: "The biggest saving when off"
                    }
                    Effect {
                        settingKey: "drift"
                        label: "Creatures drift"
                        description: "Devices sway gently in the water"
                        defaultValue: true
                        impact: "medium"
                        cost: "Redraws the sea while a view is open"
                    }
                    Effect {
                        settingKey: "pulses"
                        label: "Light pulses"
                        description: "Traffic running along the tentacles"
                        defaultValue: true
                        impact: "medium"
                        cost: "Redraws the tentacles while traffic flows"
                    }
                    Effect {
                        settingKey: "companion"
                        label: "Darwin the goldfish"
                        description: "Eats the traffic's crumbs, cleans the glass, waves when clicked"
                        defaultValue: true
                        impact: "low"
                        cost: "Small; only moves while a view is open"
                    }
                    Effect {
                        settingKey: "celebrate"
                        label: "Celebrations"
                        description: "A burst of bubbles when a device you add shows up"
                        defaultValue: true
                        impact: "low"
                        cost: "A few seconds, once per new device"
                    }
                    Effect {
                        settingKey: "desktopLive"
                        label: "Keep the desktop fishbowl alive"
                        description: "Off: it moves only under the pointer"
                        defaultValue: false
                        impact: "high"
                        cost: "Runs all the time when on"
                    }
                    StyledText {
                        width: parent.width
                        text: "Nothing runs while no view is open, whatever you choose here."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }

                // ===== Bar & alerts ==============================================
                Column {
                    visible: page.tab === "bar"
                    width: parent.width
                    spacing: Theme.spacingL

                    SelectionSetting {
                        settingKey: "pill"
                        label: "Beside the jellyfish"
                        description: "What the bar shows next to the small jellyfish"
                        options: [
                            {
                                "label": "Devices online",
                                "value": "peers"
                            },
                            {
                                "label": "Total traffic",
                                "value": "rate"
                            },
                            {
                                "label": "Nothing",
                                "value": "icon"
                            }
                        ]
                        defaultValue: "peers"
                    }
                    ToggleSetting {
                        settingKey: "statusDot"
                        label: "Status dot"
                        description: "Green connected, orange needs you, red off: readable at a glance"
                        defaultValue: true
                    }
                    ToggleSetting {
                        settingKey: "middleToggle"
                        label: "Middle-click connects"
                        description: "A middle click on the jellyfish connects or disconnects"
                        defaultValue: true
                    }
                    ToggleSetting {
                        settingKey: "notifications"
                        label: "Notifications"
                        description: "When a device comes online or goes offline (muted ones stay quiet)"
                        defaultValue: false
                    }
                    StyledText {
                        width: parent.width
                        text: "Hover the jellyfish for a summary; click it to open the deep; right-click for the menu."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }

                // ===== Desktop ===================================================
                Column {
                    visible: page.tab === "desktop"
                    width: parent.width
                    spacing: Theme.spacingL

                    StyledText {
                        visible: !desktopScreens.visible
                        width: parent.width
                        text: "No fishbowl yet. Add one in Settings → Desktop Widgets → Abyss; its options show up here."
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                    DesktopScreens {
                        id: desktopScreens
                        instanceId: root.instanceId
                    }
                    StyledText {
                        visible: desktopScreens.visible
                        width: parent.width
                        text: "Point at the bowl: the search bar and buttons fade in. Battery: see Effects & battery."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }

                // ===== Source & test lab =========================================
                Column {
                    visible: page.tab === "source"
                    width: parent.width
                    spacing: Theme.spacingL

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

                    // --- Test lab: a made-up mesh to try groups, latency and
                    // failures on. Shown only while it is the source; nothing
                    // here touches NetBird.
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

                // ===== Help ======================================================
                Column {
                    visible: page.tab === "help"
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: [
                            ["touch_app", "Click the jellyfish", "Connect or disconnect. Right-click: profile, sharing, admin console"],
                            ["pets", "Click a creature", "Its card: Terminal, Files, Screen, Desktop, copy its address"],
                            ["search", "Type anywhere", "Search devices by name or by what they are (phones, slow…), or type a command (add, share, disconnect)"],
                            ["add_circle", "The + at the top", "Add this computer or your phone, step by step, with a QR code"],
                            ["wb_sunny", "Drag the light of the surface", "Onto a device that can lend Internet: you go out through it"],
                            ["keyboard", "From a terminal", "dms ipc call abyss ssh <device>  ·  files · vnc · rdp · join · share on"]
                        ]
                        Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 54
                            radius: 12
                            color: Theme.surfaceContainerHigh
                            DankIcon {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                name: modelData[0]
                                size: 22
                                color: Theme.primary
                            }
                            Column {
                                x: 50
                                width: parent.width - 62
                                anchors.verticalCenter: parent.verticalCenter
                                StyledText {
                                    text: modelData[1]
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    width: parent.width
                                    text: modelData[2]
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    Button {
                        icon: "open_in_new"
                        text: "Full user guide"
                        onClicked: Qt.openUrlExternally("https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md")
                    }
                }
            }
        }
    }

    // --- Building blocks ------------------------------------------------------

    // A sub-card inside a tab: icon, title, one line, then its controls
    component Group: Rectangle {
        id: grp
        property string icon
        property string title
        property string sub
        default property alias content: inner.data
        width: parent ? parent.width : 0
        height: inner.implicitHeight + 28
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        Column {
            id: inner
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 10
            Row {
                spacing: 8
                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: grp.icon
                    size: 18
                    color: Theme.primary
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: grp.title
                    font.pixelSize: Theme.fontSizeMedium + 1
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }
            StyledText {
                width: parent.width
                text: grp.sub
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }

    // A toggle with its cost written right under it: ⚡ high / medium / low
    component Effect: Column {
        id: fx
        property string settingKey
        property string label
        property string description
        property bool defaultValue: true
        property string impact: "low"
        property string cost: ""
        readonly property color hue: impact === "high" ? Theme.error : impact === "medium" ? Theme.warning : Theme.primary
        width: parent ? parent.width : 0
        spacing: 6
        ToggleSetting {
            settingKey: fx.settingKey
            label: fx.label
            description: fx.description
            defaultValue: fx.defaultValue
        }
        Row {
            spacing: 8
            Rectangle {
                width: impactRow.implicitWidth + 16
                height: 22
                radius: 11
                color: Qt.rgba(fx.hue.r, fx.hue.g, fx.hue.b, 0.15)
                Row {
                    id: impactRow
                    anchors.centerIn: parent
                    spacing: 4
                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "bolt"
                        size: 13
                        color: fx.hue
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ({
                                "high": "High battery use",
                                "medium": "Some battery use",
                                "low": "Light on battery"
                            })[fx.impact]
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: fx.hue
                    }
                }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: fx.cost
                font.pixelSize: 11
                color: Theme.surfaceVariantText
            }
        }
    }

    // A text field in DMS's colours
    component Field: Rectangle {
        property alias text: input.text
        property string placeholder
        property bool secret: false
        height: 40
        radius: 10
        color: Theme.surfaceContainerHighest
        border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: Theme.fontSizeMedium
            font.family: Theme.monoFontFamily
            color: Theme.surfaceText
            echoMode: parent.secret && !activeFocus && text !== "" ? TextInput.Password : TextInput.Normal
            selectByMouse: true
            clip: true
        }
        StyledText {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: parent.placeholder
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            opacity: 0.7
        }
    }

    // A rounded button; primary = filled
    component Button: Rectangle {
        id: b
        property string icon
        property string text
        property bool primary: false
        signal clicked
        height: 34
        width: bRow.implicitWidth + 26
        radius: 17
        opacity: enabled ? 1 : 0.45
        color: primary ? Theme.primary : bArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
        border.width: primary ? 0 : 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
        Row {
            id: bRow
            anchors.centerIn: parent
            spacing: 6
            DankIcon {
                visible: b.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: b.icon
                size: 16
                color: b.primary ? Theme.primaryText : Theme.surfaceText
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: b.text
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: b.primary ? Theme.primaryText : Theme.surfaceText
            }
        }
        MouseArea {
            id: bArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: b.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: b.clicked()
        }
    }

    // A small check box with its words
    component Check: Row {
        id: chk
        property bool on: false
        property string text
        spacing: 8
        Rectangle {
            width: 20
            height: 20
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: chk.on ? Theme.primary : "transparent"
            border.width: 2
            border.color: chk.on ? Theme.primary : Theme.outline
            DankIcon {
                anchors.centerIn: parent
                visible: chk.on
                name: "check"
                size: 15
                color: Theme.primaryText
            }
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: chk.text
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }
        TapHandler {
            onTapped: chk.on = !chk.on
        }
    }
}
