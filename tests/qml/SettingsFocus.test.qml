import QtQuick
import QtTest
import "../../components/settingrows"

// The focus ring of the settings rows must sit outside the control's fill
// (primary on primary measured 1:1 before), so it is a separate border item.
// Run: qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/SettingsFocus.test.qml
Item {
    width: 366
    height: 300

    Column {
        width: parent.width
        SettingToggleRow {
            id: toggle
            settingKey: "k"
            label: "A switch"
        }
        SettingChoiceRow {
            id: choice
            settingKey: "c"
            label: "A choice"
            options: ["one", "two"]
            defaultValue: "one"
        }
    }

    TestCase {
        name: "SettingsFocus"
        when: windowShown

        // The ring is the visible child whose border is 2 px and fill transparent
        function rings(item) {
            const out = [];
            for (let i = 0; i < item.children.length; i++) {
                const c = item.children[i];
                if (c.visible && c.border && c.border.width === 2 && c.color.a === 0)
                    out.push(c);
            }
            return out;
        }
        function test_toggle_ring_is_outside_the_track() {
            compare(rings(toggle).length, 0);
            toggle.forceActiveFocus();
            const r = rings(toggle);
            compare(r.length, 1);
            verify(r[0].width > 52 && r[0].height > 30);
        }
        function test_choice_ring_wraps_the_selected_pill() {
            choice.forceActiveFocus();
            let r = [];
            for (let i = 0; i < choice.children.length; i++)
                r = r.concat(rings(choice.children[i]));
            compare(r.length, 1);
            // Geometry of the selected pill (first option), 4 px out, at first focus
            const pill = choice.children[1].children[1].children[0];
            compare(r[0].x, pill.x - 4);
            compare(r[0].y, pill.y - 4);
            compare(r[0].width, pill.width + 8);
            compare(r[0].height, pill.height + 8);
        }
    }
}
