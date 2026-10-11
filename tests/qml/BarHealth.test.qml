import QtQuick
import QtTest
import qs.Common
import "../../components"

// The bar jellyfish colour wiring: ok/warn/bad pick primary/warning/error
// from the theme, and the setting off or a mesh not connected stays plain.
// Run: qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/BarHealth.test.qml
TestCase {
    name: "BarHealth"

    readonly property var okView: ({
            "relays": [
                {
                    "available": true
                }
            ],
            "peers": [
                {
                    "name": "atlas",
                    "online": true,
                    "latencyMs": 20
                }
            ]
        })

    Component {
        id: factory
        BarHealth {}
    }

    function make(props) {
        return createTemporaryObject(factory, this, props);
    }

    function test_ok() {
        const h = make({
            "active": true,
            "view": okView
        });
        compare(h.state, "ok");
        compare(h.tint, Theme.primary);
    }

    function test_warn() {
        const view = {
            "relays": [
                {
                    "available": true
                },
                {
                    "available": false
                }
            ],
            "peers": okView.peers
        };
        const h = make({
            "active": true,
            "view": view
        });
        compare(h.state, "warn");
        compare(h.tint, Theme.warning);
        verify(h.reason.length > 0);
    }

    function test_bad() {
        const view = {
            "relays": okView.relays,
            "peers": [
                {
                    "name": "atlas",
                    "online": false
                }
            ]
        };
        const h = make({
            "active": true,
            "view": view,
            "exitNode": "atlas"
        });
        compare(h.state, "bad");
        compare(h.tint, Theme.error);
    }

    function test_smoothed_latency_wins() {
        const view = {
            "relays": [],
            "peers": [
                {
                    "name": "a",
                    "online": true,
                    "latencyMs": 400,
                    "steadyMs": 40
                }
            ]
        };
        compare(make({
            "active": true,
            "view": view
        }).state, "ok");
    }

    function test_inactive_is_plain() {
        const view = {
            "relays": [],
            "peers": [
                {
                    "name": "a",
                    "online": true,
                    "latencyMs": 900
                }
            ]
        };
        const h = make({
            "active": false,
            "view": view
        });
        compare(h.state, "ok");
        compare(h.reason, "");
        compare(h.tint, Theme.primary);
    }
}
