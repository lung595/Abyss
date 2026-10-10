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

    // Red for a failure, amber for a hint; `actionLabel` adds a button (Retry)
    property bool error: false
    property string actionLabel: ""
    signal acted

    readonly property string url: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#" + anchor

    height: 44
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: band.error ? Theme.error : Theme.warning

    Text {
        id: cross

        visible: band.error
        anchors {
            left: parent.left
            leftMargin: Theme.spacingL
            verticalCenter: parent.verticalCenter
        }
        text: "✕"
        color: Theme.error
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
    }

    Text {
        anchors {
            left: cross.visible ? cross.right : parent.left
            leftMargin: cross.visible ? Theme.spacingM : Theme.spacingL
            right: retry.visible ? retry.left : mark.left
            rightMargin: Theme.spacingM
            verticalCenter: parent.verticalCenter
        }
        text: band.message
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeMedium
        elide: Text.ElideRight
    }

    Text {
        id: retry

        visible: band.actionLabel !== ""
        anchors {
            right: mark.left
            rightMargin: Theme.spacingL
            verticalCenter: parent.verticalCenter
        }
        text: band.actionLabel
        color: Theme.primary
        font.pixelSize: 14
        font.weight: Font.DemiBold
        Accessible.role: Accessible.Button
        Accessible.name: band.actionLabel

        TapHandler {
            onTapped: band.acted()
        }
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
        Keys.onEnterPressed: Qt.openUrlExternally(band.url)
        Keys.onSpacePressed: Qt.openUrlExternally(band.url)

        // Focus-visible ring, as on the station targets
        Rectangle {
            anchors {
                fill: parent
                margins: -4
            }
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.surfaceText
            visible: mark.activeFocus
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(band.url)
        }
    }
}
