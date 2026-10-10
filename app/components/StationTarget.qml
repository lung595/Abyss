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
    readonly property int ringWidth: focusVisible || current ? 2 : 0
    // Keyboard focus only: a click focuses the target but must not restyle its ring
    readonly property bool focusVisible: activeFocus && !_byPointer
    readonly property bool hovered: area.containsMouse
    property bool _byPointer: false

    signal activated(string stationId)

    width: 44
    height: 44
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: activated(stationId)
    Keys.onEnterPressed: activated(stationId)
    Keys.onSpacePressed: activated(stationId)
    onActiveFocusChanged: {
        if (!activeFocus)
            _byPointer = false;
    }

    // Ring: the current station always, the focused one when reached by keyboard
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: target.ringWidth
        border.color: target.focusVisible ? Theme.surfaceText : Theme.primary
    }

    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: 16
        // Hover: one container step up; pressed: a brief transform-only squeeze
        color: target.current ? Theme.primary : target.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        border.width: target.current ? 0 : 1
        border.color: Theme.outlineStrong
        scale: area.pressed ? 0.96 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.shortDuration
            }
        }

        Text {
            anchors.centerIn: parent
            text: target.mark
            color: target.current ? Theme.primaryText : Theme.surfaceText
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: target._byPointer = true
        onClicked: {
            target.forceActiveFocus(Qt.MouseFocusReason);
            target.activated(target.stationId);
        }
    }
}
