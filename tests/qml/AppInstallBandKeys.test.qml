import QtQuick
import QtTest
import "../../components"

// Keyboard contract of the install band (design.md 8.4 bis.3): Enter runs the
// primary action, Escape is "Not now" without "don't ask again", and nothing
// fires while the install is busy.
// Run: qmltestrunner-qt6 -platform offscreen -import scripts/preview/imports -input tests/qml/AppInstallBandKeys.test.qml
Item {
    id: host
    width: 600
    height: 400

    Component {
        id: fakeComponent
        QtObject {
            property string phase: "idle"
            property int step: 0
            property string reason: ""
            property var help: ({})
            property int installs: 0
            function install() {
                installs++;
            }
        }
    }
    Component {
        id: bandComponent
        AppInstallBand {
            height: implicitHeight
        }
    }

    TestCase {
        name: "AppInstallBandKeys"
        when: windowShown

        function make(phase) {
            const inst = createTemporaryObject(fakeComponent, host, {
                "phase": phase
            });
            const band = createTemporaryObject(bandComponent, host, {
                "installer": inst,
                "action": "send",
                "deviceName": "demo-laptop"
            });
            band.forceActiveFocus();
            wait(250);
            return {
                "inst": inst,
                "band": band
            };
        }

        function test_enter_installs() {
            const o = make("idle");
            keyClick(Qt.Key_Return);
            compare(o.inst.installs, 1);
            keyClick(Qt.Key_Enter);
            compare(o.inst.installs, 2);
        }
        function test_enter_retries_after_failure() {
            const o = make("failed");
            keyClick(Qt.Key_Return);
            compare(o.inst.installs, 1);
        }
        function test_enter_busy_does_nothing() {
            for (const p of ["checking", "installing"]) {
                const o = make(p);
                keyClick(Qt.Key_Return);
                compare(o.inst.installs, 0, p);
            }
        }
        function test_enter_installed_proceeds() {
            const o = make("installed");
            const spy = createTemporaryObject(spyComponent, host, {
                "target": o.band,
                "signalName": "proceed"
            });
            keyClick(Qt.Key_Return);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], "send");
            compare(o.inst.installs, 0);
        }
        function test_escape_is_not_now() {
            const o = make("idle");
            const spy = createTemporaryObject(spyComponent, host, {
                "target": o.band,
                "signalName": "dismissed"
            });
            keyClick(Qt.Key_Escape);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], false, "Escape never means don't ask again");
        }
        Component {
            id: spyComponent
            SignalSpy {}
        }
    }
}
