import QtQuick
import QtQuick.Window
import qs.Common
import qs.Widgets
import "../../components"
import "../../components/Health.js" as Health

// Offscreen render of the bar jellyfish in each health state, from made-up
// mesh data. Usage, from scripts/preview: qml-qt6 -I imports health.qml -- <out.png>
Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property var cases: [
        {
            "relays": [
                {
                    "available": true
                }
            ],
            "peers": [
                {
                    "name": "atlas",
                    "online": true,
                    "latencyMs": 20
                }
            ],
            "exit": ""
        },
        {
            "relays": [
                {
                    "available": true
                },
                {
                    "available": false
                }
            ],
            "peers": [
                {
                    "name": "atlas",
                    "online": true,
                    "latencyMs": 20
                }
            ],
            "exit": ""
        },
        {
            "relays": [
                {
                    "available": true
                }
            ],
            "peers": [
                {
                    "name": "atlas",
                    "online": false,
                    "latencyMs": 0
                }
            ],
            "exit": "atlas"
        }
    ]
    width: 560
    height: 90
    visible: true
    color: Theme.surface

    Row {
        anchors.centerIn: parent
        spacing: 40
        Repeater {
            model: 3
            Row {
                id: item
                readonly property var h: Health.evaluate(Health.inputOf(win.cases[index], win.cases[index].exit))
                spacing: 8
                JellyGlyph {
                    width: 28
                    height: 28
                    color: item.h.state === "bad" ? Theme.error : item.h.state === "warn" ? Theme.warning : Theme.primary
                }
                StyledText {
                    width: 120
                    wrapMode: Text.WordWrap
                    text: item.h.state + ": " + item.h.reason
                    color: Theme.surfaceText
                    font.pixelSize: 11
                }
            }
        }
    }
    Timer {
        interval: 700
        running: true
        onTriggered: win.contentItem.grabToImage(r => {
            r.saveToFile(win.args[win.args.length - 1]);
            Qt.quit();
        })
    }
}
