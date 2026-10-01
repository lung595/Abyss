import QtQuick
import qs.Common
import qs.Widgets
import "Find.js" as Find
Column {
    id: root
    required property string settingKey
    required property string label
    property string description: ""
    property int defaultValue: 0
    property int value: defaultValue
    property int minimum: 0
    property int maximum: 100
    property string unit: ""
    width: parent ? parent.width : 0
    spacing: Theme.spacingS
    Component.onCompleted: { const s = Find.settings(root.parent); if (s) root.value = s.loadValue(settingKey, defaultValue); }
    StyledText { text: root.label + "  ·  " + root.value + root.unit; font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Medium; color: Theme.surfaceText }
    StyledText { text: root.description; visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
    Rectangle { width: parent.width; height: 6; radius: 3; color: Theme.surfaceContainerHighest
        Rectangle { width: parent.width * (root.value - root.minimum) / Math.max(1, root.maximum - root.minimum); height: 6; radius: 3; color: Theme.primary } }
}
