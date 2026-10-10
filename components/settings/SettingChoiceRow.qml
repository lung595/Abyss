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
    function choose(i) {
        value = valueOf(options[i]);
        const s = Host.find(root.parent);
        if (s)
            s.saveValue(settingKey, value);
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

    StyledText {
        objectName: "title"
        width: parent.width
        text: root.label
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }
    StyledText {
        objectName: "description"
        width: parent.width
        visible: root.description !== ""
        text: root.description
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }
    Flow {
        objectName: "control"
        width: parent.width
        spacing: Theme.spacingS
        Repeater {
            model: root.options
            Rectangle {
                id: pill
                required property var modelData
                required property int index
                readonly property bool on: root.valueOf(modelData) === root.value
                width: Math.min(pillText.implicitWidth + 28, parent.width)
                height: 34
                radius: 17
                color: on ? Theme.primary : Theme.surfaceContainerHighest
                border.width: root.activeFocus && on ? 2 : 1
                border.color: root.activeFocus && on ? Theme.surfaceText : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                StyledText {
                    id: pillText
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 28)
                    text: root.labelOf(pill.modelData)
                    font.pixelSize: Theme.fontSizeMedium
                    color: pill.on ? Theme.primaryText : Theme.surfaceText
                }
                TapHandler {
                    onTapped: {
                        root.forceActiveFocus();
                        root.choose(pill.index);
                    }
                }
            }
        }
    }
}
