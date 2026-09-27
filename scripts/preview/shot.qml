import QtQuick
import QtQuick.Window
import qs.Common
import "../../components"

// Offscreen renders from the demo mesh (fictional names and addresses).
// Usage: see render.sh. Modes: connected, disconnected, connecting,
// needsLogin, stopped, card, relay, find, exit, nets, work, crowd, lens,
// peek, search (these four on the 30-peer crowd mesh), grab, reef (the lamp on the floor), fly / unfly (the card
// opening / closing, as frames out-0.png ... out-11.png), step (the open card
// stepping to the next peer, same frames, 35 ms apart); a "-light" suffix uses a light theme's accents, "-cc" the Control Center size.
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
        if (mode === "find")
            scene.query = "pi";
        if (["crowd", "lens", "peek", "search", "zoom"].indexOf(mode) >= 0)
            demo.setProfile("crowd");
        if (mode === "search")
            scene.query = "nas";
        if (mode === "unfly" || mode === "step")
            scene.cardId = "demo-harbor-vps";
        if (mode === "zoom") {
            cam.start();
            return;
        }
        if (mode === "fly" || mode === "unfly" || mode === "step") {
            flight.start();
            return;
        }
        shot.interval = mode === "peek" ? 3000 : mode === "lens" || mode === "reef" || mode === "grab" ? 2600 : 1600;
        shot.start();
    }

    AbyssScene {
        id: scene
        anchors.fill: parent
        source: demo
        compact: win.cc
        cornerRadius: 16
    }

    // After the first reads: aim the lens at a peer, or rest it on a group
    // until its bubble opens by itself, then on one of its members
    Timer {
        running: win.mode === "lens" || win.mode === "reef" || win.mode === "peek" || win.mode === "grab"
        interval: 700
        // The lens keeps aiming (the demo traffic reshuffles the groups)
        repeat: win.mode !== "grab"
        onTriggered: {
            if (win.mode === "grab") {
                // Hold the busiest peer up and to the right: its ribbon stretches
                const p = scene.arr.items.find(i => i.type === "peer");
                if (p)
                    scene.grab(p.id, 110, -70);
            } else if (win.mode === "reef") {
                // The lamp on the floor, right of the caves: the scenery it reveals
                scene.pinnedPointer = Qt.point(scene.width * 0.6, scene.frame.floorY - 30);
            } else if (win.mode === "lens") {
                const p = scene.arr.items.find(i => i.type === "peer");
                const at = p ? scene.lay.peers[p.id] : null;
                scene.pinnedPointer = at ? Qt.point(at.x + 8, at.y - 4) : Qt.point(scene.width / 2, scene.height / 2);
            } else if (scene.peekId === "") {
                const g = scene.arr.items.find(i => i.type === "group" && !i.asleep && !i.fog);
                const at = g ? scene.lay.peers[g.id] : null;
                if (at)
                    scene.pinnedPointer = Qt.point(at.x + 4, at.y);
            } else {
                const q = scene.peekSpots[1] || scene.peekSpots[0];
                scene.pinnedPointer = Qt.point(scene.peekCentre.x + q.x + 6, scene.peekCentre.y + q.y + 4);
            }
        }
    }

    // The card opening (or closing), frame by frame: once the deep has settled,
    // then grab every 70 ms (the whole flight takes about 700 ms)
    Timer {
        id: flight
        property int frame: -1
        interval: frame < 0 ? 1600 : win.mode === "step" ? 35 : 70
        repeat: true
        onTriggered: {
            if (frame < 0 && win.mode === "step")
                scene.stepCard(1);
            else if (frame < 0)
                scene.cardId = win.mode === "fly" ? "demo-harbor-vps" : "";
            const n = ++frame;
            // One tick more than frames, so the last grab is written
            if (n === 12) {
                stop();
                Qt.quit();
                return;
            }
            const path = win.out.replace(/\.png$/, "-" + n + ".png");
            win.contentItem.grabToImage(r => r.saveToFile(path));
        }
    }

    // The camera gliding to a group and back, frame by frame: open the first
    // awake group once the deep has settled, grab every 70 ms, then close it
    Timer {
        id: cam
        property int frame: -1
        interval: frame < 0 ? 1600 : 70
        repeat: true
        onTriggered: {
            if (frame < 0) {
                const g = scene.arr.items.find(i => i.type === "group" && !i.asleep && !i.fog);
                if (g)
                    scene.openPeek(g.id);
                // The pointer rides along to the middle, so the group stays open
                scene.pinnedPointer = scene.peekCentre;
            }
            const n = ++frame;
            if (n === 10) {
                scene.pinnedPointer = Qt.point(-1, -1);
                scene.closePeek();
            }
            if (n === 19) {
                stop();
                Qt.quit();
                return;
            }
            const path = win.out.replace(/\.png$/, "-" + n + ".png");
            win.contentItem.grabToImage(r => r.saveToFile(path));
        }
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
