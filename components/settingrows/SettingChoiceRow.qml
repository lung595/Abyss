import QtQuick
import qs.Common
import qs.Widgets
import "Host.js" as Host

// A choice row for one saved setting: the words, then the options as pills
// that wrap onto further lines when the page is narrow. Options are strings or
// {label, value} like DMS's SelectionSetting, and the saved value is the same.
Column {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    required property var options
    property string defaultValue: ""
    property string value: defaultValue

    function valueOf(o) {
        return typeof o === "object" ? o.value : o;
    }
    function labelOf(o) {
        return typeof o === "object" ? o.label : o;
    }
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
    function choose(i) {
        set(valueOf(options[i]));
    }
    function step(d) {
        let i = options.findIndex(o => valueOf(o) === value);
        choose(Math.max(0, Math.min(options.length - 1, i + d)));
    }

    width: parent ? parent.width : 0
    spacing: Theme.spacingS
    activeFocusOnTab: true
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Component.onCompleted: Qt.callLater(load)

    SettingWords {
        width: parent.width
        label: root.label
        description: root.description
    }
    Item {
        width: parent.width
        height: list.height
        Rectangle {
            id: ring
            readonly property Item target: reps.itemAt(root.options.findIndex(o => root.valueOf(o) === root.value))
            visible: root.activeFocus
            x: (target ? target.x : 0) - 4
            y: (target ? target.y : 0) - 4
            width: (target ? target.width : list.width) + 8
            height: (target ? target.height : list.height) + 8
            radius: target ? target.radius + 4 : 8
            color: "transparent"
            border.width: 2
            border.color: Theme.primary
        }
        Flow {
            id: list
            objectName: "control"
            width: parent.width
            spacing: Theme.spacingS
            Repeater {
                id: reps
                model: root.options
                Rectangle {
                    id: pill
                    required property var modelData
                    required property int index
                    readonly property bool on: root.valueOf(modelData) === root.value
                    width: Math.min(pillText.implicitWidth + 32, parent.width)
                    height: Math.max(36, pillText.contentHeight + 16)
                    radius: 18
                    color: on ? Theme.primary : Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                    // Hover and pressed tints; the 36 px pill is acceptable under 44 px because
                    // the whole list is one keyboard stop and the row has room around it
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.surfaceText
                        opacity: tap.pressed ? 0.12 : (hover.hovered ? 0.08 : 0)
                    }
                    HoverHandler {
                        id: hover
                    }
                    StyledText {
                        id: pillText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 32)
                        text: root.labelOf(pill.modelData)
                        font.pixelSize: Theme.fontSizeMedium
                        color: pill.on ? Theme.primaryText : Theme.surfaceText
                    }
                    TapHandler {
                        id: tap
                        onTapped: {
                            root.forceActiveFocus();
                            root.choose(pill.index);
                        }
                    }
                }
            }
        }
    }
}
