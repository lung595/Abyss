import QtQuick
import QtTest
import qs.Common
import qs.Services
import "../../components"
import "../.."

// The settings page and its section rail: opening the page writes nothing,
// the keys move through the rail, and a rail shorter than its rows scrolls
// under the fixed search field and keeps the pointed row in view.
// Run (no PySide6 needed; the preview stand-ins supply Theme and widgets):
//   qmltestrunner-qt6 -import scripts/preview/imports -input tests/qml/Settings.test.qml
Item {
    id: host
    width: 600
    height: 400

    readonly property var rows: [0, 1, 2, 3, 4, 5, 6, 7].map(i => ({
                "id": ["connect", "appearance", "effects", "bar", "desktop", "alerts", "advanced", "help"][i],
                "text": "Section " + i
            }))

    SectionRail {
        id: rail
        height: 200
        rows: host.rows
    }

    Component {
        id: pageComponent
        AbyssSettings {
            width: 560
        }
    }

    TestCase {
        name: "SectionRail"
        when: windowShown

        function init() {
            rail.sel = 0;
            rail.forceActiveFocus();
            rail.point(0);
        }
        function test_down_up_move_the_pointer_only() {
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Down);
            compare(rail.pointed, 2);
            compare(rail.sel, 0);
            keyClick(Qt.Key_Up);
            compare(rail.pointed, 1);
        }
        function test_ends_hold() {
            keyClick(Qt.Key_Up);
            compare(rail.pointed, 0);
            for (let i = 0; i < 12; i++)
                keyClick(Qt.Key_Down);
            compare(rail.pointed, 7);
        }
        function test_enter_and_space_open() {
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Return);
            compare(rail.sel, 1);
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Space);
            compare(rail.sel, 2);
        }
        function test_scrolls_to_the_pointed_row() {
            const flick = findChild(rail, "rows");
            verify(flick, "rows flickable");
            verify(flick.contentHeight > flick.height, "rows outgrow the height");
            for (let i = 0; i < 7; i++)
                keyClick(Qt.Key_Down);
            const y = rail.pointed * rail.rowHeight;
            verify(y >= flick.contentY && y + rail.rowHeight <= flick.contentY + flick.height, "pointed row in view");
            verify(flick.contentY > 0, "scrolled");
            for (let i = 0; i < 7; i++)
                keyClick(Qt.Key_Up);
            compare(flick.contentY, 0);
        }
        function test_click_gives_focus_for_keys() {
            rail.focus = false;
            rail.parent.forceActiveFocus();
            mouseClick(rail, 40, rail.rowsTop + rail.rowHeight * 2 + 10);
            compare(rail.sel, 2);
            verify(rail.activeFocus);
            keyClick(Qt.Key_Down);
            compare(rail.pointed, 3);
        }
    }

    TestCase {
        name: "Page"
        when: windowShown

        function test_opening_and_browsing_writes_nothing() {
            const before = JSON.stringify(SettingsData.pluginSettings);
            let saves = 0;
            const count = () => saves++;
            PluginService.pluginDataChanged.connect(count);
            const page = createTemporaryObject(pageComponent, host, {
                "section": "deep"
            });
            verify(page);
            wait(50);
            PluginService.pluginDataChanged.disconnect(count);
            compare(saves, 0);
            compare(JSON.stringify(SettingsData.pluginSettings), before);
        }
    }
}
