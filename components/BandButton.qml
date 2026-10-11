import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

// One button of the install band (primary, secondary, quiet, flat, GitHub mark).
// All variants share the same states: hover veil, keyboard ring, pressed veil,
// disabled at half opacity.
Item {
    id: btn

    // primary | secondary | quiet | flat | mark
    property string kind: "secondary"
    property string label: ""
    property string iconName: ""
    property string tip: ""
    property bool reduceMotion: false

    signal clicked

    readonly property bool _filled: kind === "primary"
    readonly property color _fg: _filled ? Theme.primaryText : (kind === "quiet" ? Theme.surfaceVariantText : Theme.surfaceText)
    readonly property int _pad: kind === "quiet" ? 8 : (kind === "flat" ? 12 : 16)

    implicitHeight: 44
    implicitWidth: kind === "mark" ? 44 : Math.max(44, content.implicitWidth + _pad * 2)
    opacity: enabled ? 1 : 0.5
    scale: area.pressed && !reduceMotion ? 0.97 : 1
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label || tip
    Keys.onReturnPressed: if (enabled)
        clicked()
    Keys.onSpacePressed: if (enabled)
        clicked()

    Behavior on scale {
        NumberAnimation {
            duration: btn.reduceMotion ? 0 : 100
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: btn._filled ? Theme.primary : "transparent"
        border.width: btn.kind === "secondary" ? 1 : 0
        border.color: Theme.surfaceVariantText
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: btn._filled ? Theme.primaryText : Theme.surfaceText
        opacity: !btn.enabled ? 0 : (area.pressed ? 0.16 : (area.containsMouse ? 0.08 : 0))
        Behavior on opacity {
            NumberAnimation {
                duration: btn.reduceMotion ? 0 : 150
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: Theme.cornerRadius + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: btn.visualFocus
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8
        DankIcon {
            visible: btn.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: btn.iconName
            size: 16
            color: btn._fg
        }
        GitHubMark {
            visible: btn.kind === "mark"
            anchors.verticalCenter: parent.verticalCenter
            size: 24
            color: Theme.surfaceText
        }
        StyledText {
            visible: btn.kind !== "mark"
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, btn.width - btn._pad * 2 - (btn.iconName !== "" ? 24 : 0))
            text: btn.label
            elide: Text.ElideRight
            color: btn._fg
            font.pixelSize: Theme.fontSizeMedium
            font.weight: btn.kind === "quiet" ? Font.Medium : (btn.kind === "flat" ? Font.Normal : Font.DemiBold)
            font.underline: btn.kind === "quiet"
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
        ToolTip.visible: containsMouse && btn.tip !== ""
        ToolTip.text: btn.tip
        ToolTip.delay: 500
    }
}
