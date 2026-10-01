import QtQuick

// A burst of bubbles rising and fading: the celebration when a new device
// joins. Plays a few seconds each time `running` turns on, then rests.
Item {
    id: fizz

    property bool running: false
    property color tint: "white"
    property int count: 16

    Repeater {
        model: fizz.running ? fizz.count : 0
        Rectangle {
            id: b
            required property int index
            // A fixed spread per bubble, so the burst looks the same each time
            readonly property real seed: ((index * 7919) % 97) / 97
            readonly property real size: 4 + seed * 9
            width: size
            height: size
            radius: size / 2
            color: "transparent"
            border.width: 1.2
            border.color: Qt.rgba(fizz.tint.r, fizz.tint.g, fizz.tint.b, 0.85)
            x: fizz.width / 2 + (seed - 0.5) * fizz.width * 0.9
            y: fizz.height
            opacity: 0
            SequentialAnimation {
                running: true
                PauseAnimation {
                    duration: (b.index % 6) * 120
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: b
                        property: "y"
                        from: fizz.height
                        to: -b.size - b.seed * 30
                        duration: 1400 + b.seed * 900
                        easing.type: Easing.OutQuad
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: b
                            property: "opacity"
                            to: 1
                            duration: 200
                        }
                        NumberAnimation {
                            target: b
                            property: "opacity"
                            to: 0
                            duration: 1300 + b.seed * 700
                        }
                    }
                }
            }
        }
    }
}
