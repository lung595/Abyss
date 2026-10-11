import QtQuick
import qs.Common

// The GitHub mark that opens one section of the user guide in the browser,
// on click only (the plugin itself never goes online). The anchor picks the
// section; the base address lives here and nowhere else.
Item {
    id: root

    // Section anchor in docs/GUIDE.md, without the "#"
    required property string anchor
    required property color tint
    // Emitted after the browser was asked to open the guide
    signal opened

    readonly property string guide: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#"

    width: 24
    height: 24

    GitHubMark {
        anchors.centerIn: parent
        size: 16
        color: area.containsMouse ? Theme.primary : root.tint
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Qt.openUrlExternally(root.guide + root.anchor);
            root.opened();
        }
    }
}
