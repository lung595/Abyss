import QtQuick
import "."

// One station of the depth gauge: a 44 x 44 target, reachable by Tab, with a
// focus-visible ring and Enter/Space to activate. The current one is filled.
FocusScope {
    id: target

    required property string stationId
    required property string mark
    required property string label
    property bool current: false
    // 2 px ring on the current station and on the one focused by keyboard
    readonly property int ringWidth: activeFocus || current ? 2 : 0

    signal activated(string stationId)

    width: 44
    height: 44
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: activated(stationId)
    Keys.onEnterPressed: activated(stationId)
    Keys.onSpacePressed: activated(stationId)

    // Ring: the current station always, the focused one when reached by keyboard
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: target.ringWidth
        border.color: target.activeFocus ? Theme.surfaceText : Theme.primary
    }

    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: 16
        color: target.current ? Theme.primary : Theme.surfaceContainerHigh
        border.width: target.current ? 0 : 1
        border.color: Theme.outline

        Text {
            anchors.centerIn: parent
            text: target.mark
            color: target.current ? Theme.primaryText : Theme.surfaceText
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            target.forceActiveFocus(Qt.MouseFocusReason);
            target.activated(target.stationId);
        }
    }
}
