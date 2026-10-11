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
    height: 600

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

    property var actions: []
    property var jobs: {
        const r = [];
        for (let i = 0; i < 30; i++)
            r.push({
                id: i,
                path: "/tmp/f" + i,
                device: "atlas",
                state: "queued",
                progress: null,
                at: 0
            });
        return r;
    }

    RevealFlickable {
        id: flick
        x: 0
        y: 400
        width: 400
        height: 150
        contentHeight: col.height
        Column {
            id: col
            Repeater {
                model: host.jobs
                SendJobRow {
                    required property var modelData
                    width: 380
                    job: modelData
                    onAction: kind => host.actions.push(kind)
                    onRevealed: item => flick.reveal(item)
                }
            }
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
        }
        function test_return_on_a_row_button_emits_its_action() {
            const btn = col.children[0].children.find(c => c.activeFocusOnTab);
            btn.forceActiveFocus();
            keyClick(Qt.Key_Return);
            compare(host.actions[0], "cancel");
        }
        function test_focus_scrolls_the_row_into_view_and_back() {
            verify(flick.contentHeight > flick.height, "list is taller than the view");
            const last = col.children[29].children.find(c => c.activeFocusOnTab);
            last.forceActiveFocus();
            verify(flick.contentY > 0, "scrolled down");
            const top = col.children[29].mapToItem(flick.contentItem, 0, 0).y;
            verify(top >= flick.contentY && top + 56 <= flick.contentY + flick.height, "last row inside the view");
            col.children[0].children.find(c => c.activeFocusOnTab).forceActiveFocus();
            compare(flick.contentY, 0);
        }
        function test_click_on_a_chip_toggles_without_a_ring() {
            const chip = picker.children.find(c => c.activeFocusOnTab);
            mouseClick(chip);
            compare(host.toggled[0], "atlas");
            verify(!chip.activeFocus, "no focus after a click");
        }
    }
}
