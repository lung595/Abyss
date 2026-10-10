import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../.."

// Offscreen render of the settings page, one tab per shot, from DMS-like
// stand-ins (imports/qs/Modules). Usage: settings.sh <tab> <out.png>
// (sections: connect, appearance, effects, bar, desktop, alerts, advanced, help)
Window {
    id: win
    readonly property var args: Qt.application.arguments
    // "<section>[:light][:narrow]" selects the theme and the 366 px case
    readonly property var spec: args[args.length - 2].split(":")
    readonly property string tab: spec[0]
    readonly property string out: args[args.length - 1]
    width: spec.indexOf("narrow") >= 0 ? 386 : 600
    height: Math.max(400, Math.min(1400, settings.height + 40))
    visible: true
    color: Theme.surface

    Component.onCompleted: {
        Theme.isLightMode = spec.indexOf("light") >= 0;
    }

    // grabToImage skips the window colour: paint the backdrop so washes show true
    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    AbyssSettings {
        id: settings
        x: 20
        y: 20
        width: win.spec.indexOf("narrow") >= 0 ? 346 : 560
        section: win.tab
    }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            shot.start();
        }
    }
    Timer {
        id: shot
        interval: 600
        onTriggered: win.contentItem.grabToImage(r => {
            r.saveToFile(win.out);
            Qt.quit();
        })
    }
}
