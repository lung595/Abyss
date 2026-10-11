import QtQuick
import Quickshell.Io
import "../../components"

// ServiceScan: all closed -> no service, some open -> the right buttons, an
// invalid address starts nothing, closing the card mid-scan drops the probes
// and their late answers, and a program that cannot start leaves no section.
// The probes go through tests/qml/fake-timeout (the address picks the answer).
// Run: tests/qml/qmltest.py tests/qml/ServiceScan.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property string step: "closed"

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    function ids() {
        return scan.services.map(s => s.id);
    }

    ServiceScan {
        id: scan
    }

    // Makes timeout "missing" for the last step (see qmltest.py)
    Process {
        id: hide
        command: ["sh", "-c", "touch \"$1/missing.timeout\"", "sh", fakeDir]
    }

    // One step per tick, so every scan has time to answer
    Timer {
        id: tick
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            if (test.step === "closed") {
                test.check("nothing before a card is open", test.ids().length === 0);
                scan.ip = "10.0.0.2";
                scan.active = true;
                test.step = "none";
            } else if (test.step === "none") {
                test.check("every port closed -> no service", test.ids().length === 0, scan.services);
                scan.active = false;
                scan.ip = "10.0.0.1";
                scan.active = true;
                test.step = "some";
            } else if (test.step === "some") {
                test.check("open ports -> their buttons, in table order", JSON.stringify(test.ids()) === JSON.stringify(["jellyfin", "homeassistant"]), scan.services);
                test.check("the button carries the URL", scan.services[0].url === "http://10.0.0.1:8096/", scan.services);
                scan.active = false;
                test.check("closing the card clears the buttons", test.ids().length === 0);
                scan.ip = "not an address";
                scan.active = true;
                test.step = "invalid";
            } else if (test.step === "invalid") {
                test.check("an invalid address starts nothing", test.ids().length === 0, scan.services);
                scan.active = false;
                scan.ip = "10.9.9.9";
                scan.active = true;
                test.step = "hang";
            } else if (test.step === "hang") {
                test.check("probes still waiting -> no service yet", test.ids().length === 0);
                // Close mid-scan, then scan another peer: the first scan's
                // probes are gone and cannot add anything
                scan.active = false;
                scan.ip = "10.0.0.1";
                scan.active = true;
                test.step = "after";
            } else if (test.step === "after") {
                test.check("a scan after a cancelled one is clean", JSON.stringify(test.ids()) === JSON.stringify(["jellyfin", "homeassistant"]), scan.services);
                scan.active = false;
                hide.running = true;
                test.step = "gone";
            } else if (test.step === "gone") {
                // timeout cannot start: the probes never exit, nothing is shown
                scan.ip = "10.0.0.1";
                scan.active = true;
                test.step = "end";
            } else {
                test.check("a program that cannot start -> no section", test.ids().length === 0, scan.services);
                console.log((test.fails ? "✗" : "✓") + " ServiceScan: " + (test.count - test.fails) + "/" + test.count + " passed");
                Qt.exit(test.fails ? 1 : 0);
            }
        }
    }
}
