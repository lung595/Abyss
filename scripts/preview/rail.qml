import QtQuick
import QtQuick.Window
import qs.Common
import "../../components"
import "../../components/Sections.js" as Sections

// Offscreen render of the section rail in its states, from the stand-ins.
// Usage, from scripts/preview:
//   qml-qt6 -I imports rail.qml -- <state>[:light][:wall] <out.png>
// states: rest, hover (row 3), press (row 4), focus (keyboard ring on row 2)
// "wall" swaps in a generated palette, as DMS does from a wallpaper.
Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property var spec: args[args.length - 2].split(":")
    width: 240
    height: 480
    visible: true
    color: Theme.surface

    Component.onCompleted: {
        Theme.isLightMode = spec.indexOf("light") >= 0;
        if (spec.indexOf("wall") >= 0) {
            Theme.primary = "#5FD3C4";
            Theme.surface = "#101A19";
            Theme.surfaceText = "#DCE8E5";
            Theme.surfaceVariantText = "#A9BDB9";
            Theme.outline = "#7B9792";
        }
        if (spec[0] === "hover")
            rail.hovered = 3;
        else if (spec[0] === "press") {
            rail.hovered = 4;
            rail.pressed = 4;
        } else if (spec[0] === "focus") {
            rail.forceActiveFocus();
            rail.point(2);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }
    SectionRail {
        id: rail
        x: 20
        y: 20
        height: 440
        rows: Sections.LIST
        start: 1
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
