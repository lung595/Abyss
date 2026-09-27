import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../../components"
import "../../components/Bowl.js" as Bowl

// Offscreen renders from the demo mesh (fictional names and addresses).
// Usage: see render.sh. Modes: connected, disconnected, connecting,
// needsLogin, stopped, card, relay, find, exit, nets, work, crowd, lens,
// peek, search (these four on the 30-peer crowd mesh), grab, reef (the lamp on the floor), fly / unfly (the card
// opening / closing, as frames out-0.png ... out-11.png), step (the open card
// stepping to the next peer, same frames, 35 ms apart), zoom (the camera
// gliding to a group and back, frames), desk (the frameless desktop view on a
// made-up wallpaper; desk-hover with the pointer over it, desk-sleep awake then left just before the shot, desk-zoom a group opening in the bowl); life / life-peek (frames of the deep, or an open group, left alone); mine, menu, menu-name, carry, carry-crowd, carry-mid (groups of mine, the Internet light carried into a group, left on a member or in the middle); a "-light" suffix uses a light theme's accents, "-cc" the Control Center size.
Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property string rawMode: args[args.length - 2]
    readonly property bool light: rawMode.indexOf("-light") >= 0
    readonly property bool cc: rawMode.indexOf("-cc") >= 0
    readonly property string mode: rawMode.replace(/-light|-cc/g, "")
    readonly property string out: args[args.length - 1]
    readonly property bool desk: mode.indexOf("desk") === 0
    width: cc ? 560 : desk ? 780 : 580
    height: cc ? 360 : desk ? 620 : 480
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
        if (mode === "card" || mode === "desk-card")
            scene.cardId = "demo-harbor-vps";
        if (mode === "find")
            scene.query = "pi";
        if (["crowd", "lens", "peek", "search", "zoom", "life-peek"].indexOf(mode) >= 0)
            demo.setProfile("crowd");
        if (mode === "search")
            scene.query = "nas";
        if (mode === "unfly" || mode === "step")
            scene.cardId = "demo-harbor-vps";
        if (mode === "zoom" || mode === "desk-zoom") {
            cam.start();
            return;
        }
        if (["mine", "menu", "menu-name", "carry", "carry-crowd", "carry-mid"].indexOf(mode) >= 0) {
            if (mode === "carry-crowd")
                demo.setProfile("crowd");
            mine.start();
            return;
        }
        if (mode === "life" || mode === "life-peek") {
            alive.start();
            return;
        }
        if (mode === "fly" || mode === "unfly" || mode === "step") {
            flight.start();
            return;
        }
        shot.interval = mode === "peek" ? 3000 : mode === "lens" || mode === "reef" || mode === "grab" ? 2600 : 1600;
        shot.start();
    }

    // desk-sleep: awake while the demo reshuffles, then the pointer leaves
    // just before the shot (nothing may stay frozen half-way)
    property bool dozed: false
    Timer {
        running: win.mode === "desk-sleep"
        interval: 1300
        onTriggered: win.dozed = true
    }

    // A made-up wallpaper (soft colour blobs) behind the desktop view
    Rectangle {
        anchors.fill: parent
        visible: win.desk
        gradient: Gradient {
            GradientStop { position: 0; color: "#3b5b7a" }
            GradientStop { position: 0.55; color: "#7a5a8c" }
            GradientStop { position: 1; color: "#d9a07a" }
        }
        Rectangle {
            width: 420; height: 420; radius: 210; x: -90; y: 300
            color: "#e8c38a"; opacity: 0.45
        }
    }

    // The desktop fishbowl, as AbyssDesktop.qml lays it out
    readonly property var bowl: Bowl.build(width - 100, height - 60, 54)
    FishBowl {
        visible: win.desk
        x: 50; y: 30; width: win.width - 100; height: win.height - 60
        part: "back"; b: win.bowl
        ink: scene.ink; shallow: scene.shallow; abyss: scene.abyss; tints: scene.reefTints
    }
    FishBowl {
        visible: win.desk && opacity > 0.01
        x: 50; y: 30; width: win.width - 100; height: win.height - 60
        part: "shade"; b: win.bowl; abyss: scene.abyss
        opacity: Math.max(scene.blurMix, 0.85 * scene.cardMix)
    }
    Item {
        visible: win.desk
        x: 50; y: 30; width: win.width - 100; height: win.height - 60
        SandLetters { b: win.bowl; scene: scene }
    }
    AbyssScene {
        id: scene
        x: win.desk ? 50 + win.bowl.scene.x : 0
        y: win.desk ? 30 + win.bowl.scene.y : 0
        width: win.desk ? win.bowl.scene.w : win.width
        height: win.desk ? win.bowl.scene.h : win.height
        borderless: win.desk
        insetTop: win.desk ? win.bowl.scene.insetTop : 0
        insetFloor: win.desk ? win.bowl.scene.insetFloor : 0
        // Like the real widget: still while nobody hovers it
        freezeWhenIdle: win.desk
        interacting: win.mode !== "desk" && !win.dozed
        source: demo
        compact: win.cc
        cornerRadius: 16
    }
    FishBowl {
        visible: win.desk
        x: 50; y: 30; width: win.width - 100; height: win.height - 60
        part: "front"; b: win.bowl; opacity: 1 - 0.8 * scene.cardMix
        ink: scene.ink; shallow: scene.shallow; abyss: scene.abyss; tints: scene.reefTints
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

    // Groups of mine (right-click menu) and the Internet light carried into
    // a group. mine: a group of mine carrying the exit; menu: the menu on a
    // peer; menu-name: naming a new group; carry / carry-crowd: the light
    // rests on a shoal, the group opens, the light is left on a member.
    // What happened is printed ("carry: …"), then the last state is shot.
    Timer {
        id: mine
        property int step: 0
        interval: 1600
        repeat: true
        onTriggered: {
            const live = demo.view.peers.filter(p => p.online);
            if (win.mode === "mine") {
                const ids = live.slice(1, 4).map(p => p.id);
                SettingsData.pluginSettings = Object.assign({}, SettingsData.pluginSettings, { "groups": [{ "id": "u1", "name": "Homelab", "members": ids }], "exitGroup": "u1" });
                PluginService.pluginDataChanged("abyss");
                demo.setExitNode(live[2].name);
                win.grabLater();
                stop();
            } else if (win.mode === "menu" || win.mode === "menu-name") {
                const it = scene.arr.items.find(i => i.type === "peer");
                const at = scene.spotOf(it.id);
                scene.openMenu(it.id, Qt.point(at.x + 10, at.y));
                if (win.mode === "menu-name")
                    scene.doMenu(scene.menuActions(it.id, scene.prefs.groups).find(a => a.act === "create"));
                console.log("menu: " + scene.menuActions(it.id, scene.prefs.groups).map(a => a.text).join(" | ") + " · groups " + JSON.stringify(scene.prefs.groups));
                win.grabLater();
                stop();
            } else {
                const g = scene.arr.items.find(i => i.type === "group" && !i.asleep && !i.fog);
                if (step === 0) {
                    const at = scene.spotOf(g.id);
                    scene.dragOver(at.x, at.y);
                    console.log("carry: over " + g.label + " -> " + scene.dropHint);
                    interval = win.mode === "carry-mid" ? 1500 : 700;
                } else if (step === 1 && win.mode === "carry-mid") {
                    console.log("carry: group open " + (scene.peekId === g.id));
                    const c = scene.peekCentre;
                    scene.dragOver(c.x, c.y);
                    console.log("carry: in the middle -> " + scene.dropHint);
                    scene.dropSun(c.x, c.y);
                    console.log("carry: exit " + demo.exitNode + " · group " + scene.prefs.exitGroup + " · open " + scene.peekId + " · groups " + JSON.stringify(scene.prefs.groups));
                    scene.pinnedPointer = Qt.point(c.x + 40, c.y + 60);
                    win.grabLater();
                    stop();
                } else if (step === 1) {
                    console.log("carry: group open " + (scene.peekId === g.id));
                    const id = scene.peekMembers.find(m => scene.peerById[m].online);
                    const q = scene.peerPose(id);
                    scene.dragOver(q.x, q.y);
                    console.log("carry: on a member -> " + scene.dropHint + " (focus " + scene.focusId + ")");
                    scene.dropSun(q.x, q.y);
                    console.log("carry: exit is now " + demo.exitNode + ", expected " + scene.peerById[id].name);
                    scene.pinnedPointer = scene.peekCentre;
                    win.grabLater();
                    stop();
                }
                step++;
            }
        }
    }
    function grabLater() {
        shot.interval = 900;
        shot.start();
    }

    // Life at rest, frame by frame: the deep (or an open group) left alone,
    // grabbed every 300 ms, to see tails beat and animals look round
    Timer {
        id: alive
        property int frame: -1
        interval: frame < 0 ? 1600 : 300
        repeat: true
        onTriggered: {
            if (frame < 0 && win.mode === "life-peek") {
                const g = scene.arr.items.find(i => i.type === "group" && !i.asleep && !i.fog);
                if (g)
                    scene.openPeek(g.id);
                scene.pinnedPointer = scene.peekCentre;
                interval = 1200;
                frame = 0;
                return;
            }
            interval = 300;
            const n = ++frame;
            if (n === 13) {
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
