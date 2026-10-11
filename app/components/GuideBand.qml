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
    // The error kind is the error role at 13 % over the surface (spec 2.9.4)
    color: band.error ? Theme.withAlpha(Theme.error, 0.13) : Theme.surfaceContainerHigh
    border.width: 1
    border.color: band.error ? Theme.error : Theme.warning

    // Two strokes, as the mark of the mockup (a font glyph reads too thin)
    Item {
        id: cross

        visible: band.error
        width: 12
        height: 12
        anchors {
            left: parent.left
            leftMargin: Theme.spacingL
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: [45, -45]

            Rectangle {
                required property int modelData

                anchors.centerIn: parent
                width: 16
                height: 2
                radius: 1
                rotation: modelData
                color: Theme.error
            }
        }
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

    Rectangle {
        id: retry

        visible: band.actionLabel !== ""
        anchors {
            right: mark.left
            rightMargin: Theme.spacingL
            verticalCenter: parent.verticalCenter
        }
        width: retryText.implicitWidth + 2 * Theme.spacingL
        height: 32
        radius: height / 2
        color: Theme.error
        Accessible.role: Accessible.Button
        Accessible.name: band.actionLabel

        Text {
            id: retryText

            anchors.centerIn: parent
            text: band.actionLabel
            // The surface role reads on the error fill in both themes
            color: Theme.surface
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
        }

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
