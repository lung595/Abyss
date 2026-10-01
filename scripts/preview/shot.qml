import QtQuick
import QtQuick.Window
import QtTest
import qs.Common
import qs.Services
import "../../components"
import "../../components/Bowl.js" as Bowl
import "../../components/MyGroups.js" as MyGroups

// Offscreen renders from the demo mesh (fictional names and addresses).
// Usage: see render.sh. Modes: lab (the test lab), connected, disconnected, connecting,
// needsLogin, stopped, card, relay, find, exit, nets, work, crowd, lens,
// peek, search (these four on the 30-peer crowd mesh), grab, reef (the lamp on the floor), fly / unfly (the card
// opening / closing, as frames out-0.png ... out-11.png), step (the open card
// stepping to the next peer, same frames, 35 ms apart), zoom (the camera
// gliding to a group and back, frames), desk (the frameless desktop view on a
// made-up wallpaper; desk-hover with the pointer over it, desk-sleep awake then left just before the shot, desk-zoom a group opening in the bowl); life / life-peek (frames of the deep, or an open group, left alone); mine, menu, menu-name, carry, carry-crowd, carry-mid, carry-aim, carry-pulse, carry-fade, sun-menu, sun-glide, carry-reopen, sun-regive (groups of mine, the Internet light carried into a group, left on a member or in the middle; held over the middle; just dropped there); a "-light" suffix uses a light theme's accents, "-cc" the Control Center size.
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
    // sun-regive: a real mouse (press, move, release) on the window
    TestCase {
        id: mouse
        when: false
        optional: true
    }
    QtObject {
        id: regive
        property string target
    }
    function find(o, name) {
        return o.objectName === name ? o : (o.children || []).reduce((f, c) => f || find(c, name), null);
    }
    function groupPeek() {
        return find(scene, "groupPeek");
    }
    // sun-glide: where the light is, every 100 ms of its trip
    Timer {
        id: glideLog
        property var sun
        property point from
        property int n: 0
        interval: 100
        repeat: true
        onTriggered: {
            console.log("glide: " + n * 100 + " ms x " + Math.round(sun.shown.x) + " (from " + Math.round(from.x) + " to " + Math.round(sun.home.x) + ") gliding " + sun.gliding);
            if (++n > 8) {
                // Near the left edge its words go to its right
                const words = sun.children.find(c => c.objectName === "sunWords");
                const x0 = sun.x;
                sun.x = 20;
                console.log("glide: label at the edge x " + Math.round(words.x) + ", in the open x " + (sun.x = 300, Math.round(words.x)));
                sun.x = x0;
                stop();
                win.grabLater();
            }
        }
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
        // lab: the test lab's custom mesh (60 peers, +40 ms, a peer silent),
        // flagged as such
        if (mode === "lab") {
            scene.markLab = true;
            demo.labPeers = 60;
            demo.labLatency = 40;
            demo.labTrouble = "silent";
            demo.labMesh = "lab";
        }
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
        if (["mine", "menu", "menu-name", "carry", "carry-crowd", "carry-mid", "carry-aim", "carry-pulse", "carry-fade", "sun-menu", "sun-glide", "carry-reopen", "sun-regive", "refuse"].indexOf(mode) >= 0) {
            if (mode === "carry-crowd")
                demo.setProfile("crowd");
            mine.start();
            return;
        }
        if (mode === "gif-sun" || mode === "gif-refuse") {
            reel.start();
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
        markLab: false
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

    // README GIFs, with a real mouse, one step and one grab every 80 ms:
    // gif-sun carries the light onto a peer that can lend Internet;
    // gif-refuse onto one that cannot (it steps back, the light bounces
    // home and a note explains). Frames out-0.png ... out-<n>.png.
    Timer {
        id: reel
        property int frame: -1
        property var path: []
        interval: frame < 0 ? 1600 : 80
        repeat: true
        onTriggered: {
            if (frame < 0) {
                const sun = find(scene, "surfaceSun");
                const from = sun.mapToItem(win.contentItem, sun.width / 2, sun.height / 2);
                const it = scene.arr.items.find(i => i.type === "peer" && (win.mode === "gif-sun") === !!scene.peerById[i.peerId].exit);
                // The demo reshuffles: wait for such a peer to swim out alone
                if (!it)
                    return;
                const to = scene.mapToItem(win.contentItem, scene.spotOf(it.id).x, scene.spotOf(it.id).y);
                // Hold still, lift, carry (eased), hold over it, let go, watch
                const p = [];
                for (let i = 0; i < 3; i++)
                    p.push({ "at": from });
                p.push({ "at": from, "press": true });
                for (let i = 1; i <= 16; i++) {
                    const k = i / 16, e = k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2;
                    p.push({ "at": Qt.point(from.x + (to.x - from.x) * e, from.y + (to.y - from.y) * e) });
                }
                for (let i = 0; i < 6; i++)
                    p.push({ "at": to });
                p.push({ "at": to, "release": true });
                for (let i = 0; i < 18; i++)
                    p.push({ "at": to, "idle": true });
                path = p;
            }
            const n = ++frame;
            if (n > path.length) {
                stop();
                Qt.quit();
                return;
            }
            const s = path[n - 1];
            if (!s)
                return;
            if (s.press)
                mouse.mousePress(win.contentItem, s.at.x, s.at.y);
            else if (s.release)
                mouse.mouseRelease(win.contentItem, s.at.x, s.at.y);
            else if (!s.idle)
                mouse.mouseMove(win.contentItem, s.at.x, s.at.y, 0);
            win.contentItem.grabToImage(r => r.saveToFile(win.out.replace(/\.png$/, "-" + (n - 1) + ".png")));
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
                if (win.mode === "sun-glide") {
                    // Picked from the light's menu: it glides to the far
                    // lender instead of jumping; logged along the way
                    const find = o => o.objectName === "surfaceSun" ? o : (o.children || []).reduce((f, c) => f || find(c), null);
                    const sun = find(scene);
                    const lenders = demo.view.peers.filter(p => p.online && p.exit);
                    scene.setExit(lenders[0].name, "");
                    const t0 = Date.now();
                    Qt.callLater(() => {
                        const a = sun.shown;
                        scene.setExit(lenders[lenders.length - 1].name, "");
                        glideLog.from = a;
                        glideLog.sun = sun;
                        glideLog.start();
                    });
                    stop();
                    return;
                }
                if (win.mode === "sun-menu") {
                    // A click on the light: where Internet can go
                    // Two groups of mine, one lent Internet: it opens unfolded
                    const ids = n => demo.view.peers.filter(p => n.indexOf(p.name) >= 0).map(p => p.id);
                    scene.prefs.set("groups", [{ "id": "u1", "name": "Busy", "members": ids(["atlas-server", "nook-nas", "harbor-vps"]) }, { "id": "u2", "name": "Quiet", "members": ids(["tern-vps"]) }]);
                    const mg = scene.prefs.groups[0];
                    if (mg)
                        scene.setExit("", mg.id);
                    scene.openMenu("sun", Qt.point(scene.width - 250, 60));
                    console.log("sun: " + JSON.stringify(MyGroups.exitTree(scene.prefs.groups, demo.view.peers, scene.sunOpen, demo.exitNode, scene.prefs.exitGroup)));
                    const q = demo.view.peers.find(p => p.online && p.exit);
                    const it = scene.arr.items.find(i => i.type === "peer" && i.peerId === q.id);
                    if (it)
                        console.log("peer menu: " + scene.menuActions(it.id, scene.prefs.groups).map(a => a.text).join(" | "));
                    scene.dragOver(100, 100);
                    scene.cancelCarry();
                    console.log("escape: carrying " + scene._carrying + " · exit '" + demo.exitNode + "'");
                    shot.interval = 400;
                    shot.start();
                    stop();
                    return;
                }
                if (win.mode === "refuse") {
                    // Dropped on a peer that cannot lend Internet: the light
                    // goes back and a note says why, with the README link
                    const it = scene.arr.items.find(i => i.type === "peer" && !scene.peerById[i.peerId].exit);
                    const at = scene.spotOf(it.id);
                    scene.dragOver(at.x, at.y);
                    scene.dropSun(at.x, at.y);
                    console.log("refuse: note '" + (scene.note ? scene.note.title : "none") + "'");
                    shot.interval = 400;
                    shot.start();
                    stop();
                    return;
                }
                if (win.mode === "carry-fade") {
                    // Carried over open water: what cannot lend Internet steps back;
                    // on such a peer, the light says so and a drop changes nothing
                    const it = scene.arr.items.find(i => i.type === "peer" && !scene.peerById[i.peerId].exit);
                    const at = scene.spotOf(it.id);
                    scene.dragOver(at.x, at.y);
                    console.log("carry: over " + scene.peerById[it.peerId].name + " -> " + scene.dropHint);
                    scene.dropSun(at.x, at.y);
                    console.log("carry: exit after the drop '" + demo.exitNode + "'");
                    scene.dragOver(8, scene.height - 8);
                    shot.interval = 400;
                    shot.start();
                    stop();
                    return;
                }
                if (step === 0) {
                    const at = scene.spotOf(g.id);
                    scene.dragOver(at.x, at.y);
                    console.log("carry: over " + g.label + " -> " + scene.dropHint);
                    interval = (win.mode.indexOf("carry-") === 0 || win.mode === "sun-regive") && win.mode !== "carry-crowd" ? 1500 : 700;
                } else if (step === 1 && win.mode === "carry-aim") {
                    // Held over the middle, not dropped: the ring and the faint tentacles
                    const c = scene.peekCentre;
                    scene.dragOver(c.x + 6, c.y - 4);
                    console.log("carry: aiming at all -> " + scene.aimAll + " · " + scene.dropHint);
                    shot.interval = 400;
                    shot.start();
                    stop();
                } else if (step === 1 && win.mode === "carry-pulse") {
                    // Just dropped in the middle: the pulse on its way out
                    const c = scene.peekCentre;
                    scene.dragOver(c.x, c.y);
                    scene.dropSun(c.x, c.y);
                    console.log("carry: dropped, exit " + demo.exitNode);
                    scene.pinnedPointer = Qt.point(c.x + 40, c.y + 60);
                    shot.interval = 300;
                    shot.start();
                    stop();
                } else if (win.mode === "sun-regive") {
                    // Left in the middle of a group, then taken up again with
                    // a real mouse and dropped on one member of it
                    const c = scene.peekCentre;
                    if (step === 1) {
                        scene.dragOver(c.x, c.y);
                        scene.dropSun(c.x, c.y);
                        scene.pinnedPointer = Qt.point(c.x, c.y);
                        console.log("regive: whole group " + scene.prefs.exitGroup + " via " + demo.exitNode + ", lit " + groupPeek().lit);
                        interval = 900;
                    } else if (step === 2) {
                        const sun = find(scene, "surfaceSun");
                        const at = sun.mapToItem(win.contentItem, sun.width / 2, sun.height / 2);
                        const id = scene.peekMembers.find(m => scene.peerById[m].online && scene.peerById[m].exit && scene.peerById[m].name !== demo.exitNode);
                        const q = scene.mapToItem(win.contentItem, scene.peerPose(id).x, scene.peerPose(id).y);
                        regive.target = scene.peerById[id].name;
                        console.log("regive: sun at " + Math.round(at.x) + "," + Math.round(at.y) + " visible " + sun.visible + "; member " + regive.target + " at " + Math.round(q.x) + "," + Math.round(q.y));
                        mouse.mousePress(win.contentItem, at.x, at.y);
                        for (let i = 1; i <= 12; i++)
                            mouse.mouseMove(win.contentItem, at.x + (q.x - at.x) * i / 12, at.y + (q.y - at.y) * i / 12, 20);
                        console.log("regive: carrying " + scene._carrying + " hint '" + scene.dropHint + "' peek " + scene.peekId);
                        mouse.mouseRelease(win.contentItem, q.x, q.y);
                        console.log("regive: after the drop exit " + demo.exitNode + " (wanted " + regive.target + ") group '" + scene.prefs.exitGroup + "' peek " + scene.peekId);
                        interval = 900;
                    } else if (step === 3 && win.args.indexOf("back") >= 0) {
                        // And from that member back to the middle: all of it again
                        const sun = find(scene, "surfaceSun");
                        const at = sun.mapToItem(win.contentItem, sun.width / 2, sun.height / 2);
                        const m = scene.mapToItem(win.contentItem, c.x, c.y);
                        console.log("regive: sun visible " + sun.visible + " above " + regive.target + " at " + Math.round(at.x) + "," + Math.round(at.y));
                        mouse.mousePress(win.contentItem, at.x, at.y);
                        for (let i = 1; i <= 12; i++)
                            mouse.mouseMove(win.contentItem, at.x + (m.x - at.x) * i / 12, at.y + (m.y - at.y) * i / 12, 20);
                        mouse.mouseRelease(win.contentItem, m.x, m.y);
                        console.log("regive: back in the middle, group '" + scene.prefs.exitGroup + "' via " + demo.exitNode + ", lit " + groupPeek().lit);
                        interval = 900;
                    } else {
                        win.grabLater();
                        stop();
                    }
                } else if (win.mode === "carry-reopen") {
                    const c = scene.peekCentre;
                    if (step === 1) {
                        scene.dragOver(c.x, c.y);
                        scene.dropSun(c.x, c.y);
                        console.log("reopen: dropped; exitGroup " + scene.prefs.exitGroup + " peek " + scene.peekId);
                        scene.pinnedPointer = Qt.point(c.x, c.y);
                        interval = 300;
                    } else if (step === 2 && scene.peekId !== "") {
                        // Glide out, as a hand would
                        scene.pinnedPointer = Qt.point(5, scene.height - 5);
                        step = 1;
                        interval = 1500;
                    } else if (step === 2) {
                        const it = scene.arr.items.find(i => i.mine === scene.prefs.exitGroup);
                        console.log("reopen: peek now '" + scene.peekId + "', my group item " + (it ? it.id : "none"));
                        const at = scene.spotOf(it.id);
                        scene.pinnedPointer = Qt.point(at.x, at.y);
                        interval = 250;
                    } else if (step < 12) {
                        console.log("reopen: t" + step + " peek '" + scene.peekId + "' focus " + scene.focusId + " block " + scene._peekBlock);
                    } else {
                        win.grabLater();
                        stop();
                    }
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
                    const id = scene.peekMembers.find(m => scene.peerById[m].online && scene.peerById[m].exit);
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
