import QtQuick
import qs.Common
import qs.Widgets
import "Host.js" as Host

// A one-line text setting: wrapping words, then the field. Saves when the
// field loses focus or Enter is pressed, and only if the text changed, like
// DMS's StringSetting (same key, same value).
Column {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    property string placeholder: ""
    property string defaultValue: ""
    property string value: defaultValue

    function load() {
        const s = Host.find(root.parent);
        if (s && s.pluginService && !input.activeFocus) {
            value = s.loadValue(settingKey, defaultValue);
            input.text = value;
        }
    }
    function commit() {
        if (input.text === value)
            return;
        value = input.text;
        const s = Host.find(root.parent);
        if (s)
            s.saveValue(settingKey, value);
    }

    width: parent ? parent.width : 0
    spacing: Theme.spacingXS
    Component.onCompleted: Qt.callLater(load)

    SettingWords {
        width: parent.width
        label: root.label
        description: root.description
        titleSize: Theme.fontSizeMedium
    }
    Rectangle {
        objectName: "control"
        width: parent.width
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
            color: Theme.surfaceText
            selectByMouse: true
            clip: true
            onEditingFinished: root.commit()
            onActiveFocusChanged: if (!activeFocus)
                root.commit()
        }
        // The hint is clipped by the field, not wrapped: it is not a word to read
        StyledText {
            x: 12
            width: parent.width - 24
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            opacity: 0.7
        }
    }
}
