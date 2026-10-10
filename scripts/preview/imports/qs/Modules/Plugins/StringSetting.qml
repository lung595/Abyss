import QtQuick
import qs.Common
import qs.Widgets
Column {
    id: root
    required property string settingKey
    required property string label
    property string description: ""
    property string placeholder: ""
    property string defaultValue: ""
    width: parent ? parent.width : 0
    spacing: Theme.spacingXS
    StyledText { text: root.label; font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Medium; color: Theme.surfaceText }
    StyledText { text: root.description; visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
    Rectangle {
        width: parent.width; height: 40; radius: Theme.cornerRadius; color: Theme.surfaceContainerHigh
        StyledText { x: 12; anchors.verticalCenter: parent.verticalCenter; text: root.defaultValue || root.placeholder; color: Theme.surfaceVariantText }
    }
}
