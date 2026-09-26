import QtQuick
import qs.Common
import qs.Widgets

// A rounded button: optional icon and text, an optional "on" state.
Rectangle {
    id: btn

    property string icon: ""
    property string text: ""
    property bool checked: false
    property bool primary: false
    property color ink: "white"
    property color accent: Theme.primary
    property string tip: ""

    signal clicked

    readonly property bool hovered: area.containsMouse
    height: 28
    width: row.implicitWidth + (text !== "" ? 20 : 12)
    radius: height / 2
    color: primary ? accent : checked ? Qt.rgba(accent.r, accent.g, accent.b, 0.28) : hovered ? Qt.rgba(ink.r, ink.g, ink.b, 0.12) : Qt.rgba(ink.r, ink.g, ink.b, 0.05)
    border.width: 1
    border.color: checked || primary ? accent : Qt.rgba(ink.r, ink.g, ink.b, 0.16)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        DankIcon {
            visible: btn.icon !== ""
            name: btn.icon
            size: 15
            color: btn.primary ? Theme.primaryText : btn.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            visible: btn.text !== ""
            text: btn.text
            wrapMode: Text.NoWrap
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: btn.primary ? Theme.primaryText : btn.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
