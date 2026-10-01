import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../.."

// Offscreen render of the settings page, one tab per shot, from DMS-like
// stand-ins (imports/qs/Modules). Usage: settings.sh <tab> <out.png>
// (tabs: connect, deep, effects, bar, desktop, source, help)
Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property string tab: args[args.length - 2]
    readonly property string out: args[args.length - 1]
    width: 600
    height: Math.max(400, Math.min(1400, settings.height + 40))
    visible: true
    color: Theme.surface

    AbyssSettings {
        id: settings
        x: 20
        y: 20
        width: 560
    }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            settings.children[0].children[0].tab = win.tab;
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
