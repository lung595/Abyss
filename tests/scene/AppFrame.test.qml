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

            // Real Tab presses from the clicked target: Send -> Map, and back
            keyClick(Qt.Key_Tab);
            win.check("Tab reaches the next target", map.activeFocus, map.activeFocus);
            win.check("focus ring is 2 px", map.ringWidth === 2);
            keyClick(Qt.Key_Backtab);
            win.check("Shift+Tab goes back", send.activeFocus && !map.activeFocus);
            keyClick(Qt.Key_Return);
            win.check("Enter on a focused target keeps it", frame.station === "send");
            settings.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Return);
            win.check("Enter activates Settings", frame.station === "settings", frame.station);
            map.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            win.check("Space activates Map", frame.station === "map", frame.station);

            // The signal line (glyph included) stays inside the 8 px side margins
            for (const st of ["connected", "stopped", "missing", "unknown"]) {
                frame.netbirdState = st;
                win.check("signal line fits the gauge: " + st, frame.signalWidth <= frame.gaugeWidth - 16, frame.signalWidth);
            }
            frame.netbirdState = "unknown";

            // The dive: 200 ms down, 150 ms up, back to rest when it ends
            frame.show("send");
            frame.show("map");
            win.check("descending dive is 200 ms", frame.diveDuration === 200 && frame.diving, frame.diveDuration);
            tryVerify(() => !frame.diving, 1000);
            win.check("the view is back at rest", frame.diveShift === 0, frame.diveShift);
            frame.show("send");
            win.check("ascending dive is 150 ms", frame.diveDuration === 150, frame.diveDuration);
            tryVerify(() => !frame.diving, 1000);
            win.check("rest again", frame.diveShift === 0);
            frame.show("map");
            tryVerify(() => !frame.diving, 1000);

            frame.go({
                "ok": true,
                "view": "settings",
                "device": "",
                "files": [],
                "category": ""
            });
            win.check("settings target lands on Settings", frame.station === "settings");
            frame.go({
                "ok": true,
                "view": "send",
                "device": "atlas",
                "files": [],
                "category": ""
            });
            win.check("send target lands on Send with the device", frame.station === "send" && frame.device === "atlas");
            frame.go({
                "ok": true,
                "view": "map",
                "device": "",
                "files": [],
                "category": ""
            });
            win.check("map target lands on Map", frame.station === "map");

            frame.peers = [
                {
                    "name": "atlas"
                }
            ];
            frame.go({
                "ok": true,
                "view": "peer",
                "device": "atlas",
                "files": [],
                "category": ""
            });
            win.check("known peer: map, card device kept, no message", frame.station === "map" && frame.device === "atlas" && !frame.deviceUnknown);
            frame.go({
                "ok": true,
                "view": "peer",
                "device": "ghost",
                "files": [],
                "category": ""
            });
            win.check("unknown peer: map with the guided message", frame.station === "map" && frame.deviceUnknown);
            frame.peers = null;
            win.check("peers not read yet: nothing is called unknown", !frame.deviceUnknown);

            // Geometry: full size, then the 900 x 600 minimum
            win.check("full size: gauge 72, padding 32, title row 44", frame.gaugeWidth === 72 && frame.pad === 32 && frame.titleHeight === 44);
            win.width = 900;
            win.height = 600;
            tryVerify(() => frame.width === 900, 2000);
            win.check("compact: gauge 56, padding 24, title row 40", frame.compact && frame.gaugeWidth === 56 && frame.pad === 24 && frame.titleHeight === 40);
            win.check("compact: targets stay 44 x 44 inside the gauge", map.width === 44 && map.x >= 0 && map.x + map.width <= 56, map.x);
            win.check("compact: Send keeps 44 px below Settings", send.y - settings.y >= 44, send.y - settings.y);
            mouseClick(send, 22, 22);
            win.check("a click does not draw the keyboard ring", send.activeFocus && !send.focusVisible);
            win.width = 1280;
            win.height = 800;
            tryVerify(() => frame.width === 1280, 2000);
            win.check("full size again", !frame.compact && frame.gaugeWidth === 72);
        }
    }

    Component.onDestruction: console.log((fails === 0 ? "✓ " : "✗ ") + "AppFrame: " + (count - fails) + "/" + count + " passed")
}
