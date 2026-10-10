import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../.."

// CPU bench scene: the settings page stays open; in "loop" mode a section
// change fires every second, as a click on the rail would. Usage, from
// scripts/preview: qml-qt6 -I imports bench-settings.qml -- <idle|loop> /dev/null
Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property bool looping: args[args.length - 2] === "loop"
    property var rail: null
    property int step: 0
    width: 600
    height: 700
    visible: true
    color: Theme.surface

    AbyssSettings {
        id: settings
        x: 20
        y: 20
        width: 560
    }

    // The rail exists only on the branch; the base has no such item and stays idle
    function find(item) {
        if (item.objectName === "rail")
            return item;
        for (const c of item.children) {
            const r = find(c);
            if (r)
                return r;
        }
        return null;
    }

    Timer {
        interval: 1000
        repeat: true
        running: win.looping
        onTriggered: {
            if (!win.rail)
                win.rail = win.find(settings);
            if (win.rail) {
                win.step++;
                win.rail.open(win.step % 2 ? 3 : 0);
            }
        }
    }
}
