import QtQuick
import "../../components"

// CPU bench scene for DarwinMood (no drawing): `-- <mode>` is idle, calm,
// scared (a rush every second) or sleepy (needs maxed). Mock data only.
Item {
    id: root
    readonly property string mode: Qt.application.arguments[Qt.application.arguments.length - 1]

    DarwinMood {
        id: m
        active: root.mode !== "idle"
        hunger: root.mode === "sleepy" ? 1 : 0
        dirt: root.mode === "sleepy" ? 1 : 0
        bounds: ({
                "l": 0,
                "r": 400,
                "top": 0,
                "bottom": 300
            })
        hides: [
            {
                "x": 40,
                "y": 250
            }
        ]
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.mode === "scared"
        onTriggered: m.rush(200, 100)
    }
}
