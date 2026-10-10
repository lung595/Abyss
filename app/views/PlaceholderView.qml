import QtQuick
import "../components"

// An empty view for a station whose content is another story: only its title,
// as in the mockup, so the window and the dive are complete without it.
Item {
    id: view

    required property string title
    property string note: ""

    Text {
        anchors.centerIn: parent
        text: view.note !== "" ? view.note : view.title
        color: Theme.onSurfaceVariant
        font.pixelSize: Theme.fontSizeLarge
    }
}
