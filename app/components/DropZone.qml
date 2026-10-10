import QtQuick
import "."

// The drop target of the Send view: the drop and the pick look the same to
// the view, both end in dropped(urls). The label is the approved one.
Rectangle {
    id: zone

    signal dropped(var urls)
    signal pickRequested

    height: 120
    radius: Theme.cornerRadiusLarge
    color: "transparent"
    border.width: 1
    border.color: Theme.primary
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label.text

    Rectangle {
        anchors {
            fill: parent
            margins: 8
        }
        radius: Theme.cornerRadius
        color: drop.containsDrag ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.13) : "transparent"
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.53)
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: "Drop files here, or press Ctrl+O"
        color: Theme.onSurfaceVariant
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
    }

    DropArea {
        id: drop

        anchors.fill: parent
        onDropped: event => {
            if (event.hasUrls)
                zone.dropped(event.urls.map(u => u.toString()));
        }
    }

    TapHandler {
        onTapped: zone.pickRequested()
    }
}
