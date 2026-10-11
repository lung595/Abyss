import QtQuick
import "."

// The keyboard focus ring of the Send view controls: 2 px `primary`, 2 px
// outside the item. Shown only for keyboard focus, never after a click.
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
    visible: target.activeFocus && target.focusByKey
}
