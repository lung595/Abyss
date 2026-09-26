import QtQuick
import QtQuick.Window
import qs.Common
import "../../components"

// Offscreen renders from the demo mesh (fictional names and addresses).
// Usage: see render.sh. Modes: connected, disconnected, connecting,
// needsLogin, stopped, card, relay, find, exit, nets, work; a "-light"
// suffix uses a light theme's accents, "-cc" the Control Center size.
Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property string rawMode: args[args.length - 2]
    readonly property bool light: rawMode.indexOf("-light") >= 0
    readonly property bool cc: rawMode.indexOf("-cc") >= 0
    readonly property string mode: rawMode.replace(/-light|-cc/g, "")
    readonly property string out: args[args.length - 1]
    width: cc ? 560 : 580
    height: cc ? 360 : 480
    visible: true
    color: "#141218"

    DemoSource {
        id: demo
    }

    Component.onCompleted: {
        if (light) {
            Theme.isLightMode = true;
            Theme.primary = "#6750A4";
            Theme.primaryText = "#FFFFFF";
            Theme.tertiary = "#7D5260";
            Theme.secondary = "#625B71";
            Theme.success = "#2E7D4F";
        }
        // One made-up peer muted, one pinned
        SettingsData.pluginSettings = { "muted": { "demo-studio": "studio" }, "favorites": { "demo-atlas-server": "atlas-server" } };
        const states = { "disconnected": "disconnected", "connecting": "connecting", "needsLogin": "needsLogin", "stopped": "stopped" };
        if (states[mode])
            demo.setState(states[mode]);
        if (mode === "relay")
            demo.setState("relayDown");
        if (mode === "exit")
            demo.setExitNode("harbor-vps");
        if (mode === "work")
            demo.setProfile("work");
        if (mode === "nets")
            scene.netsOpen = true;
        if (mode === "card")
            scene.cardId = "demo-harbor-vps";
        if (mode === "find") {
            scene.query = "pi";
            scene.findId = "demo-pi-garden";
        }
        shot.start();
    }

    AbyssScene {
        id: scene
        anchors.fill: parent
        source: demo
        compact: win.cc
        cornerRadius: 16
    }

    // Let a few clock ticks run so pulses and tentacles are in place
    Timer {
        id: shot
        interval: 1600
        onTriggered: win.contentItem.grabToImage(r => {
            r.saveToFile(win.out);
            Qt.quit();
        })
    }
}
