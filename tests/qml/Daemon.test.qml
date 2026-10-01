import QtQuick
import Quickshell
import qs.Services
import "../.."

// AbyssDaemon with the fake NetBird on the PATH: it picks the NetBird
// source, answers the IPC, refuses what it must and switches to the demo.
// Run: tests/qml/qmltest.py tests/qml/Daemon.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property int step: 0
    property var ipc: null

    AbyssDaemon {
        id: daemon
    }

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    property var steps: [
        () => {
            check("NetBird is found and used", daemon.hasNetbird && daemon.source && !daemon.source.demo, [daemon.hasNetbird, !!daemon.source]);
            test.ipc = daemon.data.find(o => o.target === "abyss");
            daemon.source.watch(true);
        },
        () => {
            check("ipc status", test.ipc.status() === "connected · 3/4 online", test.ipc.status());
            check("ipc copy", test.ipc.copy("nook") === "100.90.0.3" && JSON.stringify(Quickshell.launched[0]) === '["dms","cl","copy","100.90.0.3"]', Quickshell.launched);
            check("ipc copy, unknown peer", test.ipc.copy("zz") === "No peer named zz");
            check("ipc ssh opens a terminal with the fqdn", test.ipc.ssh("atlas") === "OK" && Quickshell.launched[1].slice(-1)[0] === "atlas.netbird.cloud", Quickshell.launched);
            check("ipc exit through a peer", test.ipc.exit("harbor-vps") === "Internet through harbor-vps");
        },
        () => {
            check("the exit reached NetBird", daemon.source.exitNode === "harbor-vps" && daemon.source.view.peers.find(p => p.name === "harbor-vps").lending);
            check("ipc exit off", test.ipc.exit("off") === "Internet exit off");
            check("ipc demo refuses on the real mesh", test.ipc.demo("needsLogin") === "Not in demo mode");
            PluginService.savePluginData("abyss", "source", "demo");
        },
        () => {
            check("the demo setting swaps the source", daemon.source && daemon.source.demo);
            check("ipc demo works there", test.ipc.demo("needsLogin") === "needsLogin");
            check("nothing went wrong in silence", ToastService.shown.length === 1 && ToastService.shown[0].indexOf("Copied") === 0, ToastService.shown);
        }
    ]

    Timer {
        interval: 2600
        running: true
        repeat: true
        onTriggered: {
            if (test.step < test.steps.length) {
                test.steps[test.step++]();
                return;
            }
            stop();
            console.log((test.fails ? "✗" : "✓") + " AbyssDaemon: " + (test.count - test.fails) + "/" + test.count + " passed");
            Qt.exit(test.fails ? 1 : 0);
        }
    }
}
