import QtQuick
import qs.Common
import qs.Widgets
import "Find.js" as Find
Row {
    id: root
    required property string settingKey
    required property string label
    property string description: ""
    property bool defaultValue: false
    property bool value: defaultValue
    width: parent ? parent.width : 0
    spacing: Theme.spacingM
    Component.onCompleted: Qt.callLater(() => { const s = Find.settings(root.parent); if (s) root.value = s.loadValue(settingKey, defaultValue); })
    Column {
        width: parent.width - 52 - Theme.spacingM
        spacing: Theme.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        StyledText { text: root.label; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Medium; color: Theme.surfaceText }
        StyledText { text: root.description; visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 52; height: 30; radius: 15
        color: root.value ? Theme.primary : Theme.surfaceContainerHighest
        Rectangle { width: 22; height: 22; radius: 11; y: 4; x: root.value ? 26 : 4; color: root.value ? Theme.primaryText : Theme.outline }
    }
}
