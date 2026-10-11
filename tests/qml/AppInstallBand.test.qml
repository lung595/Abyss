import QtQuick
import QtTest
import "../../components"

// The install band in each state at the popout's widths: no text under another
// text or a button, nothing elided, nothing past the band edge.
// Run: qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/AppInstallBand.test.qml
Item {
    id: host
    width: 600
    height: 600

    Component {
        id: fakeComponent
        QtObject {
            property string phase: "idle"
            property int step: 0
            property string reason: "Could not copy the app"
            property var help: ({
                    "name": "Fedora",
                    "command": "sudo dnf install quickshell",
                    "anchor": "quickshell-is-missing"
                })
        }
    }
    Component {
        id: bandComponent
        AppInstallBand {
            height: implicitHeight
        }
    }

    TestCase {
        name: "AppInstallBand"
        when: windowShown

        function leaves(item, out) {
            if (!item.visible || item.opacity === 0)
                return out;
            if (item.text !== undefined && item.contentWidth !== undefined && item.text !== "")
                out.push(item);
            for (const c of item.children)
                leaves(c, out);
            return out;
        }
        function box(band, item) {
            const p = item.mapToItem(band, 0, 0);
            return {
                "x": p.x,
                "y": p.y,
                "w": Math.min(item.width, item.contentWidth),
                "h": item.contentHeight
            };
        }

        function check_state(phase, action, width) {
            const inst = createTemporaryObject(fakeComponent, host, {
                "phase": phase,
                "step": 2
            });
            const holder = createTemporaryObject(holderComponent, host, {
                "width": width
            });
            const band = bandComponent.createObject(holder, {
                "installer": inst,
                "action": action,
                "deviceName": "A very long device name indeed"
            });
            verify(band, phase);
            wait(350);
            const all = leaves(band, []);
            const boxes = all.map(i => box(band, i));
            const problems = [];
            for (let i = 0; i < all.length; i++) {
                if (all[i].truncated)
                    problems.push("elided: " + all[i].text);
                const a = boxes[i];
                if (a.x + a.w > band.width + 0.5)
                    problems.push("past the edge: " + all[i].text);
                for (let j = i + 1; j < all.length; j++) {
                    const b = boxes[j];
                    if (a.w < 1 || b.w < 1)
                        continue;
                    if (a.x < b.x + b.w - 0.5 && b.x < a.x + a.w - 0.5 && a.y < b.y + b.h - 0.5 && b.y < a.y + a.h - 0.5)
                        problems.push("overlap: " + all[i].text + " / " + all[j].text);
                }
            }
            compare(problems.join("; "), "", phase + "/" + action + "/" + width);
            holder.destroy();
        }

        Component {
            id: holderComponent
            Item {
                height: 300
            }
        }

        function test_states_data() {
            const rows = [];
            for (const p of ["idle", "checking", "installing", "installed", "failed", "missing"])
                for (const a of ["send", "expand", "settings"])
                    for (const w of [360, 580])
                        rows.push({
                            "tag": p + "/" + a + "/" + w,
                            "p": p,
                            "a": a,
                            "w": w
                        });
            return rows;
        }
        // Primary and secondary share one row when they fit; the command is never cut mid-word
        function test_row_and_command_data() {
            return [
                {
                    "tag": "failed/580",
                    "p": "failed",
                    "w": 580,
                    "a": "Try again",
                    "b": "Not now"
                },
                {
                    "tag": "failed/360",
                    "p": "failed",
                    "w": 360,
                    "a": "Try again",
                    "b": "Not now"
                },
                {
                    "tag": "idle/580",
                    "p": "idle",
                    "w": 580,
                    "a": "Install the Abyss app",
                    "b": "Not now"
                },
                {
                    "tag": "missing/360",
                    "p": "missing",
                    "w": 360,
                    "a": "Check again",
                    "b": "Not now"
                }
            ];
        }
        function test_row_and_command(d) {
            const inst = createTemporaryObject(fakeComponent, host, {
                "phase": d.p,
                "step": 2
            });
            const holder = createTemporaryObject(holderComponent, host, {
                "width": d.w
            });
            const band = bandComponent.createObject(holder, {
                "installer": inst,
                "action": "settings",
                "deviceName": "x"
            });
            wait(350);
            const all = leaves(band, []);
            const a = all.find(i => i.text === d.a);
            const b = all.find(i => i.text === d.b);
            verify(a && b, "buttons found");
            compare(Math.round(box(band, a).y), Math.round(box(band, b).y), "same row");
            for (const t of all.filter(i => i.font.family === "monospace"))
                verify(t.wrapMode === Text.WordWrap, "command wraps at spaces only");
            holder.destroy();
        }
        function test_states(d) {
            check_state(d.p, d.a, d.w);
        }
    }
}
