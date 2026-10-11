import QtQuick
import "."

// The keyboard focus ring of the Send controls: 2 px `primary`, 2 px
// outside the item. These plain items only take focus from Tab (a click never
// focuses them), so active focus is exactly keyboard focus: no flag to keep.
Rectangle {
    required property var target

    anchors {
        fill: parent
        margins: -4
    }
    radius: target.radius + 4
    color: "transparent"
    border.width: 2
    border.color: Theme.primary
    visible: target.activeFocus
}
