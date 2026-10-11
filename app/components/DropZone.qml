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
    // Scenes can show the drag-over look without a real drag
    property bool dragOver: drop.containsDrag
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            zone.pickRequested();
            event.accepted = true;
        }
    }
    Accessible.role: Accessible.Button
    Accessible.name: label.text

    Rectangle {
        anchors {
            fill: parent
            margins: 8
        }
        radius: Theme.cornerRadius
        color: tap.pressed ? Theme.withAlpha(Theme.primary, 0.2) : zone.dragOver ? Theme.withAlpha(Theme.primary, 0.13) : hover.hovered ? Theme.surfaceContainerHigh : "transparent"
        border.width: 1
        border.color: Theme.withAlpha(Theme.outline, 0.53)
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

    FocusRing {
        target: zone
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        id: tap

        onTapped: zone.pickRequested()
    }
}
