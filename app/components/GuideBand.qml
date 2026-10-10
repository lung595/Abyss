import QtQuick
import "."

// A guided message (value 10): why nothing happened and what to do, with the
// GitHub mark that opens the GUIDE section on click only. The app itself makes
// no network access.
Rectangle {
    id: band

    required property string message
    // Anchor in docs/GUIDE.md, without the leading #
    required property string anchor

    readonly property string url: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#" + anchor

    height: 44
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Theme.warning

    Text {
        anchors {
            left: parent.left
            leftMargin: Theme.spacingL
            right: mark.left
            rightMargin: Theme.spacingM
            verticalCenter: parent.verticalCenter
        }
        text: band.message
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeMedium
        elide: Text.ElideRight
    }

    GitHubMark {
        id: mark

        anchors {
            right: parent.right
            rightMargin: Theme.spacingL
            verticalCenter: parent.verticalCenter
        }
        size: 20
        color: Theme.surfaceText
        activeFocusOnTab: true
        Accessible.role: Accessible.Link
        Accessible.name: "Open the guide"
        Keys.onReturnPressed: Qt.openUrlExternally(band.url)

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(band.url)
        }
    }
}
