pragma ComponentBehavior: Bound
import QtQuick

// A small sun: where Internet goes out, in the light's menu. Its rays turn
// slowly (a turn in 6 s) while it is shown and `spinning`; a Timer at 30 Hz
// turns it rather than an animation, so only this window redraws (P40), and
// nothing runs once the menu is closed. Still with Reduce motion.
Item {
    id: glyph
    required property color color
    property bool spinning: true
    property bool reduceMotion: false
    implicitWidth: 16
    implicitHeight: 16

    Item {
        id: rays
        anchors.fill: parent
        Repeater {
            model: 8
            Rectangle {
                id: ray
                required property int index
                x: glyph.width / 2 - width / 2
                y: 0.5
                width: 1.6
                height: 3.2
                radius: 0.8
                color: glyph.color
                opacity: index % 2 ? 0.55 : 1
                transformOrigin: Item.Center
                // Turned around the middle of the glyph, not its own
                transform: Rotation {
                    origin.x: 0.8
                    origin.y: glyph.height / 2 - 0.5
                    angle: ray.index * 45
                }
            }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 7
        height: 7
        radius: 3.5
        color: glyph.color
    }
    Timer {
        interval: 33
        repeat: true
        running: glyph.spinning && glyph.visible && !glyph.reduceMotion
        onTriggered: rays.rotation = (rays.rotation + 2) % 360
    }
}
