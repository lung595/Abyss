import QtQuick
import qs.Common
import qs.Widgets
import "Host.js" as Host

// A switch row for one saved setting. Unlike DMS's ToggleSetting the words get
// the width the switch leaves and wrap, so a narrow page never draws a title
// under the switch. The saved key and value are the same as before.
Item {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    property bool defaultValue: false
    property bool value: defaultValue

    readonly property int gap: Theme.spacingM

    width: parent ? parent.width : 0
    implicitHeight: Math.max(words.implicitHeight, track.height)
    height: implicitHeight
    activeFocusOnTab: true

    function load() {
        const s = Host.find(root.parent);
        if (s && s.pluginService)
            value = s.loadValue(settingKey, defaultValue);
    }
    // Only a gesture saves, so opening the page writes nothing
    function set(v) {
        if (v === value)
            return;
        value = v;
        const s = Host.find(root.parent);
        if (s)
            s.saveValue(settingKey, value);
    }
    function toggle() {
        set(!value);
    }

    Component.onCompleted: Qt.callLater(load)
    Keys.onSpacePressed: toggle()
    Keys.onReturnPressed: toggle()
    Keys.onEnterPressed: toggle()

    SettingWords {
        id: words
        anchors.left: parent.left
        anchors.right: track.left
        anchors.rightMargin: root.gap
        anchors.verticalCenter: parent.verticalCenter
        label: root.label
        description: root.description
    }

    Rectangle {
        id: track
        objectName: "control"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 30
        radius: 15
        color: root.value ? Theme.primary : Theme.surfaceContainerHighest
        // Hover and pressed tints, no timer or animation needed
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.surfaceText
            opacity: tap.pressed ? 0.12 : (hover.hovered ? 0.08 : 0)
        }
        Rectangle {
            width: 22
            height: 22
            radius: 11
            y: 4
            x: root.value ? 26 : 4
            color: root.value ? Theme.primaryText : Theme.outline
            // Only a gesture moves it; nothing runs at rest, and Reduce motion snaps it
            Behavior on x {
                enabled: !SettingsData.reduceMotion
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
    // Focus ring outside the track: primary on the surface, not on the primary fill
    Rectangle {
        anchors.fill: track
        anchors.margins: -4
        radius: 19
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }
    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        onTapped: {
            root.forceActiveFocus();
            root.toggle();
        }
    }
}
