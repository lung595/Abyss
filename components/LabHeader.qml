import QtQuick
import qs.Common
import qs.Widgets

// The test lab's title in the settings: what the lab is set to, in one line
// ("24 peers · +80 ms · a peer stops answering"), and a Reset that brings
// back a quiet home mesh. The rows below it are ordinary settings.
Item {
    id: root

    property string summary: ""
    // Something differs from the quiet home mesh: Reset is offered
    property bool dirty: false
    signal reset

    width: parent ? parent.width : 0
    height: visible ? col.implicitHeight + Theme.spacingXL : 0

    Column {
        id: col
        y: Theme.spacingXL
        width: parent.width
        spacing: 2

        Item {
            width: parent.width
            height: title.implicitHeight

            Row {
                spacing: Theme.spacingS
                StyledText {
                    id: title
                    text: "Test lab"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
                // Says at a glance that none of this is the real mesh
                Rectangle {
                    anchors.verticalCenter: title.verticalCenter
                    width: tag.implicitWidth + 10
                    height: tag.implicitHeight + 4
                    radius: height / 2
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                    StyledText {
                        id: tag
                        anchors.centerIn: parent
                        text: "MADE UP"
                        font.pixelSize: Theme.fontSizeSmall - 2
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                        color: Theme.primary
                    }
                }
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.dirty
                text: "Reset"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                font.underline: resetArea.containsMouse
                color: Theme.primary
                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reset()
                }
            }
        }

        StyledText {
            width: parent.width
            text: root.summary + (root.summary ? "\n" : "") + "In memory only: NetBird is never touched"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            bottomPadding: Theme.spacingXS
        }
    }
}
