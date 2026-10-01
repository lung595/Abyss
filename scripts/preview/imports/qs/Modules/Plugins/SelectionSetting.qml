import QtQuick
import qs.Common
import qs.Widgets
import "Find.js" as Find
Column {
    id: root
    required property string settingKey
    required property string label
    property string description: ""
    required property var options
    property string defaultValue: ""
    property string value: defaultValue
    width: parent ? parent.width : 0
    spacing: Theme.spacingS
    Component.onCompleted: { const s = Find.settings(root.parent); if (s) root.value = s.loadValue(settingKey, defaultValue); }
    StyledText { text: root.label; font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Medium; color: Theme.surfaceText }
    StyledText { text: root.description; visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
    Rectangle {
        width: parent.width; height: 44; radius: 10; color: Theme.surfaceContainerHighest
        StyledText { x: 14; anchors.verticalCenter: parent.verticalCenter; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium
            text: { const o = root.options.find(o => (o.value || o) === root.value); return o ? (o.label || o) : root.value; } }
        DankIcon { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; name: "expand_more"; size: 20; color: Theme.surfaceText }
    }
}
