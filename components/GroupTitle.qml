import QtQuick
import qs.Common
import qs.Widgets

// The name of an open group, at the top of the scene (placeholder: being built)
Item {
    id: title

    property var scene
    // Groups.js group item: {id, label, members}
    property var item: null
    property string sub: ""
    property color tint: "white"
    // 0..1 while the group zooms open
    property real reveal: 0

    width: col.width
    height: col.height
    opacity: reveal

    Column {
        id: col
        spacing: 2
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: title.item ? title.item.label : ""
            font.pixelSize: 20
            font.weight: Font.DemiBold
            color: title.scene ? title.scene.ink : "white"
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: title.sub
            font.pixelSize: 11
            color: title.scene ? title.scene.inkDim : "white"
        }
    }
}
