import QtQuick
import QtQuick.Window
import QtTest
import qs.Common
import "../../components"

// The deep's own send paths against a recording hub: the menu's "Send a
// file…" / "Send a folder…", Ctrl+V on the open card, no file drop target in
// the scene, and the view counting itself on the hub exactly once (also when
// the hub is swapped). Rendered offscreen from
// the demo mesh (made-up peers); the real hub is tested by
// tests/qml/SendHub.test.qml.
// Run: tests/scene/run.sh
Window {
    id: win

    property int fails: 0
    property int count: 0
    property int stage: 0

    width: 580
    height: 480
    visible: true
    color: "#141218"

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    // What the real SendHub answers to, recording what it is asked
    component FakeHub: QtObject {
        id: hub
        property string busyPeerId: ""
        property int viewers: 0
        property var calls: []
        function viewing(on) {
            hub.viewers += on ? 1 : -1;
        }
        function sendTo(peer, items) {
            hub.calls = hub.calls.concat([["send", peer.id, items]]);
            return "";
        }
        function pick(peer, folder) {
            hub.calls = hub.calls.concat([["pick", peer.id, folder]]);
            return "";
        }
        function paste(peer) {
            hub.calls = hub.calls.concat([["paste", peer.id]]);
            return "";
        }
        signal started(string peerId, string mode, int count)
        signal ended(string peerId, bool ok, string text, var failure)
        signal refused(string peerId, var failure)
    }
    FakeHub {
        id: hubA
    }
    FakeHub {
        id: hubB
    }
    QtObject {
        id: actions
        property var send: hubA
    }

    DemoSource {
        id: demo
    }
    AbyssScene {
        id: scene
        anchors.fill: parent
        markLab: false
        interacting: true
        source: demo
        actions: actions
    }
    TestCase {
        id: keys
        when: false
        optional: true
        name: "keys"
    }

    function peerItem() {
        return scene.arr.items.find(i => i.type === "peer" && scene.peerById[i.peerId].online);
    }
    // True when any item under `item` is a DropArea (the toString of a
    // QML object starts with its C++ class name)
    function hasDropArea(item) {
        return String(item).indexOf("DropArea") !== -1 || Array.from(item.children).some(hasDropArea);
    }
    function last() {
        return hubA.calls[hubA.calls.length - 1];
    }

    readonly property var stages: [() => {
            const it = peerItem();
            check("the demo mesh has an online creature", !!it);
            check("this view is counted once on the hub", hubA.viewers === 1, hubA.viewers);
            check("the scene has no file drop target (the menu is the way)", !hasDropArea(scene));
            scene.openMenu(it.id, scene.spotOf(it.id));
            const acts = scene.menuActions(it.id, scene.prefs.groups);
            const sends = acts.filter(m => m.act === "send");
            check("both send entries carry their icon and accent", sends.length === 2 && sends[0].icon === "upload_file" && sends[1].icon === "drive_folder_upload" && sends.every(m => m.accent === true), sends);
            check("the send entries come first, file then folder", acts.length > 2 && acts[0].arg === false && acts[1].arg === true && acts[0].act === "send" && acts[1].act === "send", acts);
            check("no other entry carries an icon or accent", acts.filter(m => m.act !== "send").every(m => m.icon === undefined && m.accent === undefined));
            scene.doMenu({
                "act": "send",
                "arg": false
            });
            check("'Send a file…' asks the hub for a file picker", last()[0] === "pick" && last()[1] === it.peerId && last()[2] === false, hubA.calls);
            scene.openMenu(it.id, scene.spotOf(it.id));
            scene.doMenu({
                "act": "send",
                "arg": true
            });
            check("'Send a folder…' asks for a folder picker", last()[0] === "pick" && last()[2] === true, hubA.calls);
            check("the menu closed", scene.menuId === "");
        }, () => {
            const it = peerItem();
            scene.openCard(it.id);
            scene.forceActiveFocus();
            keys.keyClick(Qt.Key_V, Qt.ControlModifier);
        }, () => {
            const it = peerItem();
            check("Ctrl+V on the open card pastes for that peer", last()[0] === "paste" && last()[1] === it.peerId, hubA.calls);
            scene.cardId = "";
            const n = hubA.calls.length;
            keys.keyClick(Qt.Key_V, Qt.ControlModifier);
        }, () => {
            check("Ctrl+V with no card open does nothing", last()[0] === "paste" && hubA.calls.filter(c => c[0] === "paste").length === 1, hubA.calls);
            // The hub is swapped for another: counted there, uncounted here
            actions.send = hubB;
            check("a swapped hub is counted once, the old one released", hubA.viewers === 0 && hubB.viewers === 1, [hubA.viewers, hubB.viewers]);
            scene.active = false;
        }, () => {
            check("a view nobody looks at leaves the count", hubB.viewers === 0 || !scene.looking, [hubB.viewers, scene.looking]);
            finish();
        }]

    function finish() {
        console.log((fails ? "✗" : "✓") + " Send paths: " + (count - fails) + "/" + count + " passed");
        Qt.exit(fails ? 1 : 0);
    }
    Timer {
        // The deep needs a moment to lay the demo peers out
        interval: win.stage === 0 ? 2500 : 400
        running: true
        repeat: true
        onTriggered: {
            if (win.stage < win.stages.length)
                win.stages[win.stage++]();
        }
    }
    Component.onCompleted: scene.forceActiveFocus()
}
