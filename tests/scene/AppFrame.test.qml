import QtQuick
import QtQuick.Window
import QtTest
import "../../app/views"

// The app window content, offscreen: station switching by synthetic click and
// key, routing of parsed command lines, the guided message for an unknown
// peer, and the keyboard path through the targets.
// Run: tests/scene/run.sh
Window {
    id: win

    property int fails: 0
    property int count: 0

    width: 1280
    height: 800
    visible: true

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    function find(item, id) {
        for (const c of item.children) {
            if (c.stationId === id)
                return c;
            const r = find(c, id);
            if (r)
                return r;
        }
        return null;
    }

    AppFrame {
        id: frame

        anchors.fill: parent
    }

    TestCase {
        name: "AppFrame"
        when: win.visible
        windowShown: true

        function test_run() {
            win.check("starts on the map", frame.station === "map", frame.station);
            const settings = win.find(frame, "settings");
            const send = win.find(frame, "send");
            const map = win.find(frame, "map");
            win.check("three targets 44 x 44", settings.width === 44 && send.height === 44 && map.width === 44);
            win.check("only the map is current", map.current && !settings.current && !send.current);

            mouseClick(send, 22, 22);
            win.check("click on Send switches", frame.station === "send", frame.station);
            win.check("the target takes the ring", send.current && !map.current);

            keyClick(Qt.Key_Tab);
            send.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Return);
            win.check("Enter on a focused target keeps it", frame.station === "send");
            settings.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Return);
            win.check("Enter activates Settings", frame.station === "settings", frame.station);
            map.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            win.check("Space activates Map", frame.station === "map", frame.station);

            frame.go({ "ok": true, "view": "settings", "device": "", "files": [], "category": "" });
            win.check("settings target lands on Settings", frame.station === "settings");
            frame.go({ "ok": true, "view": "send", "device": "atlas", "files": [], "category": "" });
            win.check("send target lands on Send with the device", frame.station === "send" && frame.device === "atlas");
            frame.go({ "ok": true, "view": "map", "device": "", "files": [], "category": "" });
            win.check("map target lands on Map", frame.station === "map");

            frame.peers = [{ "name": "atlas" }];
            frame.go({ "ok": true, "view": "peer", "device": "atlas", "files": [], "category": "" });
            win.check("known peer: map, card device kept, no message", frame.station === "map" && frame.device === "atlas" && !frame.deviceUnknown);
            frame.go({ "ok": true, "view": "peer", "device": "ghost", "files": [], "category": "" });
            win.check("unknown peer: map with the guided message", frame.station === "map" && frame.deviceUnknown);
            frame.peers = null;
            win.check("peers not read yet: nothing is called unknown", !frame.deviceUnknown);

            Qt.quit();
            win.check("done", true);
        }
    }

    Component.onDestruction: console.log((fails === 0 ? "✓ " : "✗ ") + "AppFrame: " + (count - fails) + "/" + count + " passed")
}
