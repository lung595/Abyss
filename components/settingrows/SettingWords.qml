import QtQuick
import qs.Common
import qs.Widgets

// The title and description every setting row shows. Both wrap to the width
// the row gives, so a narrow page never elides or overdraws them.
Column {
    id: root

    required property string label
    property string description: ""
    property int titleSize: Theme.fontSizeLarge

    spacing: Theme.spacingXS

    StyledText {
        objectName: "title"
        width: parent.width
        text: root.label
        wrapMode: Text.WordWrap
        font.pixelSize: root.titleSize
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
}
