import QtQuick
import QtTest
import "../../components"

// The peer card's link verdict: direct, relayed (tip and mark), offline and
// mesh down (hidden), unknown latency, and a long relay name at the narrow
// card width (text wraps, the mark is never overlapped).
// Run: qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/LinkVerdict.test.qml
Item {
    id: host
    width: 300
    height: 300

    readonly property var scene: ({
            "inkDim": "gray"
        })

    LinkVerdict {
        id: v
        width: 220
        scene: host.scene
        peer: ({
                "relayed": false,
                "relay": "",
                "latencyMs": 12
            })
        live: true
    }

    TestCase {
        name: "LinkVerdict"
        when: windowShown

        function init() {
            v.live = true;
            v.peer = {
                "relayed": false,
                "relay": "",
                "latencyMs": 12
            };
        }

        function test_direct() {
            verify(v.visible);
            compare(v.verdict.text, "Direct link, 12 ms: this looks healthy.");
            compare(v.tip, "");
            verify(!v.children[1].visible);
        }

        function test_relayed_shows_tip_and_mark() {
            v.peer = {
                "relayed": true,
                "relay": "relay-eu",
                "latencyMs": 80
            };
            verify(v.verdict.text.indexOf("Relayed link (via relay-eu)") === 0);
            verify(v.tip.length > 0);
            verify(v.children[1].visible);
        }

        function test_offline_or_mesh_down_hidden() {
            v.live = false;
            verify(!v.visible);
            compare(v.verdict.level, "unknown");
        }

        function test_unknown_latency() {
            v.peer = {
                "relayed": false,
                "relay": "",
                "latencyMs": 0
            };
            compare(v.verdict.text, "Direct link: this looks healthy.");
        }

        function test_long_relay_wraps_and_mark_not_overlapped() {
            v.peer = {
                "relayed": true,
                "relay": "a-very-long-relay-name-that-keeps-going-and-going-and-going-and-going-past-the-end",
                "latencyMs": 200
            };
            const sentence = v.children[0];
            const row = v.children[1];
            const tip = row.children[0];
            const mark = row.children[1];
            verify(sentence.implicitHeight > sentence.font.pixelSize * 2, "sentence wraps");
            verify(sentence.width <= v.width);
            verify(tip.x + tip.width <= mark.x, "tip stays left of the mark");
            verify(mark.x + mark.width <= row.width, "mark inside the card");
            compare(mark.width, 24);
        }
    }
}
