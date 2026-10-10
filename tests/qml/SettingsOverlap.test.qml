import QtQuick
import QtTest
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "../../components/settings"
import "../.."

// Every settings page at the narrowest real width: no text under a control or
// under another text, nothing elided or truncated, nothing past the page edge.
// The width is the page of the DMS settings window at its narrowest, 366 px
// (a 700 px window minus the section rail and the margins; the same number as
// the `:narrow` previews and P230 in the knowledge base).
// Run: qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/SettingsOverlap.test.qml
Item {
    id: host
    width: 600
    height: 400

    readonly property int narrow: 366
    readonly property var sections: ["connect", "appearance", "effects", "bar", "desktop", "alerts", "advanced", "help"]

    Component {
        id: rowsComponent
        PluginSettings {
            pluginId: "abyss"
            width: 300
            SettingToggleRow {
                settingKey: "rowSwitch"
                label: "A switch"
                defaultValue: true
            }
            SettingChoiceRow {
                settingKey: "rowChoice"
                label: "A choice"
                options: [
                    {
                        "label": "One",
                        "value": "1"
                    },
                    {
                        "label": "Two",
                        "value": "2"
                    }
                ]
                defaultValue: "1"
            }
        }
    }

    Component {
        id: pageComponent
        AbyssSettings {}
    }

    TestCase {
        name: "SettingsOverlap"
        when: windowShown

        // Visible leaves that carry words or are a row's control. What sits
        // inside a control (the pills' labels) belongs to it and is skipped.
        function leaves(item, out, inControl) {
            if (!item.visible || item.opacity === 0)
                return out;
            const isControl = item.objectName === "control";
            if (!inControl && (isControl || (item.text !== undefined && item.contentWidth !== undefined && item.text !== "")))
                out.push(item);
            for (const c of item.children)
                leaves(c, out, inControl || isControl);
            return out;
        }
        // Painted box of a leaf in page coordinates (a text is as wide as its words)
        function box(page, item) {
            const p = item.mapToItem(page, 0, 0);
            const isText = item.contentWidth !== undefined;
            return {
                "x": p.x,
                "y": p.y,
                "w": isText ? Math.min(item.width, item.contentWidth) : item.width,
                "h": isText ? item.contentHeight : item.height
            };
        }
        function name(item) {
            return item.objectName || item.text || "?";
        }

        function check_section(id) {
            const page = createTemporaryObject(pageComponent, host, {
                "width": host.narrow,
                "section": id
            });
            verify(page, id);
            wait(150);
            const all = leaves(page, [], false);
            verify(all.length > 5, id + ": " + all.length + " leaves");
            const boxes = all.map(i => box(page, i));
            const problems = [];
            for (let i = 0; i < all.length; i++) {
                const a = boxes[i];
                // StyledText elides on the right by default (as in DMS): `truncated` is the real cut
                if (all[i].truncated)
                    problems.push("elided: " + name(all[i]));
                if (a.w < 1 || a.h < 1)
                    continue;
                if (a.x + a.w > host.narrow + 0.5)
                    problems.push("past the page edge: " + name(all[i]) + " ends at " + Math.round(a.x + a.w));
                for (let j = i + 1; j < all.length; j++) {
                    const b = boxes[j];
                    if (b.w < 1 || b.h < 1)
                        continue;
                    if (a.x < b.x + b.w - 0.5 && b.x < a.x + a.w - 0.5 && a.y < b.y + b.h - 0.5 && b.y < a.y + a.h - 0.5)
                        problems.push("overlap: " + name(all[i]) + " / " + name(all[j]));
                }
            }
            compare(problems.join("; "), "", id);
        }

        function test_connect() {
            check_section("connect");
        }
        function test_appearance() {
            check_section("appearance");
        }
        function test_effects() {
            check_section("effects");
        }
        function test_bar() {
            check_section("bar");
        }
        function test_desktop() {
            check_section("desktop");
        }
        function test_alerts() {
            check_section("alerts");
        }
        function test_advanced() {
            check_section("advanced");
        }
        function test_help() {
            check_section("help");
        }
    }

    TestCase {
        name: "SettingRows"
        when: windowShown

        // Opening writes nothing; a gesture writes the same key and value as DMS's rows
        function test_rows_save_only_on_a_gesture() {
            SettingsData.pluginSettings = {};
            let saves = [];
            const rec = id => saves.push(JSON.stringify(SettingsData.pluginSettings));
            PluginService.pluginDataChanged.connect(rec);
            const page = createTemporaryObject(rowsComponent, host);
            wait(100);
            compare(saves.length, 0);
            const sw = page.content[0];
            const choice = page.content[1];
            compare(sw.value, true);
            sw.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(sw.value, false);
            choice.forceActiveFocus();
            keyClick(Qt.Key_Right);
            compare(choice.value, "2");
            PluginService.pluginDataChanged.disconnect(rec);
            compare(saves.join("|"), '{"rowSwitch":false}|{"rowSwitch":false,"rowChoice":"2"}');
        }
    }
}
