import QtQuick
import QtTest
import "../../app/components"

// Keyboard paths of the Send controls: Tab shows the focus ring, a click does
// not, Space and Return act, and a focused row button scrolls into view.
// Run (no PySide6 needed; the preview stand-ins supply Theme):
//   qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/SendKeys.test.qml
Item {
    id: host
    width: 600
    height: 300

    property var toggled: []
    property int picks: 0

    Column {
        DropZone {
            id: zone
            width: 500
            onPickRequested: host.picks++
        }
        DevicePicker {
            id: picker
            width: 500
            names: ["atlas", "kite"]
            chosen: []
            onToggled: name => host.toggled.push(name)
        }
    }

    function ringOf(item) {
        for (const c of item.children)
            if (c.hasOwnProperty("target"))
                return c;
        return null;
    }

    TestCase {
        name: "SendKeys"
        when: windowShown

        function init() {
            host.picks = 0;
            host.toggled = [];
        }
        function test_tab_shows_the_ring_and_space_toggles() {
            zone.forceActiveFocus();
            keyClick(Qt.Key_Tab);
            const chip = zone.nextItemInFocusChain();
            verify(chip.activeFocus, "a chip took the focus");
            verify(host.ringOf(chip).visible, "ring shown after Tab");
            keyClick(Qt.Key_Space);
            compare(host.toggled[0], "atlas");
        }
        function test_return_on_the_zone_asks_for_the_picker() {
            zone.forceActiveFocus();
            keyClick(Qt.Key_Return);
            compare(host.picks, 1);
        }
        function test_click_shows_no_ring() {
            mouseClick(zone);
            verify(!zone.activeFocus, "a click does not focus the zone");
            verify(!host.ringOf(zone).visible, "no ring after a click");
            verify(!zone.activeFocus, "a click does not focus the zone");
        }
    }
}
