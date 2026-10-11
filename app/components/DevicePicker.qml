pragma ComponentBehavior: Bound

import QtQuick
import "."

// The "To" row: one chip per online device, several can be ticked for one
// drop. `names` is the list of device names, `chosen` the ticked ones.
Row {
    id: picker

    required property var names
    property var chosen: []

    signal toggled(string name)
    // Files dropped on one chip go to that device alone
    signal droppedOn(string name, var urls)

    spacing: Theme.spacingS

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "To"
        color: Theme.onSurfaceVariant
        font.pixelSize: Theme.fontSizeMedium
    }

    Repeater {
        model: picker.names

        Rectangle {
            id: chip

            required property string modelData
            readonly property bool on: picker.chosen.indexOf(modelData) >= 0

            height: 32
            width: label.implicitWidth + 24
            radius: 16

            color: on ? Theme.primary : press.pressed ? Theme.withAlpha(Theme.primary, 0.2) : hover.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
            border.width: on ? 0 : 1
            border.color: Theme.outlineStrong
            activeFocusOnTab: true
            Accessible.role: Accessible.CheckBox
            Accessible.name: modelData
            Accessible.checked: on
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    picker.toggled(chip.modelData);
                    event.accepted = true;
                }
            }

            FocusRing {
                target: chip
            }

            HoverHandler {
                id: hover
            }

            Text {
                id: label

                anchors.centerIn: parent
                // Chips stay short: 28 characters at most, the end elided
                text: chip.modelData.length > 28 ? chip.modelData.slice(0, 28) + "…" : chip.modelData
                color: chip.on ? Theme.primaryText : Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: chip.on ? Font.DemiBold : Font.Medium
            }

            TapHandler {
                id: press

                onTapped: picker.toggled(chip.modelData)
            }

            DropArea {
                anchors.fill: parent
                onDropped: event => {
                    if (event.hasUrls)
                        picker.droppedOn(chip.modelData, event.urls.map(u => u.toString()));
                }
            }
        }
    }
}
