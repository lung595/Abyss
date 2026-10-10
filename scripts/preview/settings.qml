import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../.."

// Offscreen render of the settings page, one section per shot, from DMS-like
// stand-ins (imports/qs/Modules). Usage, from scripts/preview:
//   qml-qt6 -I imports settings.qml -- <section>[:light][:narrow][:demo] <out.png>
// (sections: connect, appearance, effects, bar, desktop, alerts, advanced, help)
Window {
    id: win
    readonly property var args: Qt.application.arguments
    // "<section>[:light][:narrow][:demo]" selects the theme, the 366 px case and the demo source
    readonly property var spec: args[args.length - 2].split(":")
    readonly property string tab: spec[0]
    readonly property string out: args[args.length - 1]
    width: spec.indexOf("narrow") >= 0 ? 406 : 600
    height: Math.max(400, Math.min(1400, settings.height + 40))
    visible: true
    color: Theme.surface

    Component.onCompleted: {
        Theme.isLightMode = spec.indexOf("light") >= 0;
        // ":demo" shows the lab rows (hidden unless the source is the demo mesh)
        if (spec.indexOf("demo") >= 0)
            SettingsData.pluginSettings = {
                "source": "demo",
                "labMesh": "lab"
            };
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
        width: win.spec.indexOf("narrow") >= 0 ? 366 : 560
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
