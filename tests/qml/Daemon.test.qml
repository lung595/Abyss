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
            check("the real state is known before any view opens", daemon.source.view.state === "connected" && daemon.source.view.online === 3, daemon.source.view.state);
            test.ipc = daemon.data.find(o => o.target === "abyss");
            daemon.source.watch(true);
        },
        () => {
            check("ipc status", test.ipc.status() === "connected · 3/4 online · Internet directly", test.ipc.status());
            check("ipc exit alone says where Internet goes out", test.ipc.exit("") === "Internet goes out directly", test.ipc.exit(""));
            check("ipc copy", test.ipc.copy("nook") === "100.90.0.3" && JSON.stringify(Quickshell.launched[0]) === '["dms","cl","copy","100.90.0.3"]', Quickshell.launched);
            check("ipc copy, unknown peer", test.ipc.copy("zz") === "No peer named zz");
            check("ipc ssh answers at once", test.ipc.ssh("atlas") === "OK");
            check("ipc ping answers at once", test.ipc.ping("atlas") === "Pinging atlas", test.ipc.ping("atlas"));
            check("ipc ping, offline peer", test.ipc.ping("lark") === "lark-phone is offline", test.ipc.ping("lark"));
            check("ipc exit through a peer", test.ipc.exit("harbor-vps") === "Internet through harbor-vps");
        },
        () => {
            check("ipc ssh knocks first: atlas does not answer, the toast says how to turn SSH on", ToastService.warned.some(t => t.indexOf("! atlas does not accept Terminal (port 22)") === 0 && t.indexOf("[sudo systemctl enable --now sshd]") > 0), ToastService.warned);
            check("the exit reached NetBird", daemon.source.exitNode === "harbor-vps" && daemon.source.view.peers.find(p => p.name === "harbor-vps").lending);
            check("ipc exit alone names the peer", test.ipc.exit(" ") === "Internet goes out through harbor-vps", test.ipc.exit(" "));
            check("ipc exit off", test.ipc.exit("off") === "Internet exit off");
            check("ipc vnc answers at once", test.ipc.vnc("atlas") === "OK");
            check("ipc ssh as a user", test.ipc.ssh("tom@atlas") === "OK");
            check("ipc ssh refuses a user that is an option", test.ipc.ssh("-oProxyCommand=x@atlas").indexOf("Refused") === 0, test.ipc.ssh("-oProxyCommand=x@atlas"));
            check("ipc link saves user and port", test.ipc.link("atlas", "tom", "8022").indexOf("atlas") === 0 && daemon.prefs.linkOf(daemon.source.view.peers.find(p => p.name === "atlas").id).port === "8022", daemon.prefs.links);
            check("ipc link refuses a bad port", test.ipc.link("atlas", "-", "99999").indexOf("Refused") === 0);
            // The key itself would stay in the shell history: only a key file
            check("ipc join refuses the key itself", test.ipc.join("A1B2C3D4-E5F6-47A8", "-").indexOf("Refused") === 0);
            check("ipc join points to the guide", test.ipc.join("A1B2C3D4-E5F6-47A8", "-").indexOf("GUIDE.md#join-a-mesh") > 0);
            check("ipc join takes a key file", test.ipc.join("/run/user/1000/nb.key", "-") === "Joining");
            check("ipc share on", test.ipc.share("on") === "SSH in this device: on" && daemon.prefs.shareSsh === true);
            check("ipc share says where it stands", test.ipc.share("") === "Shared with SSH: on");
            check("ipc demo refuses on the real mesh", test.ipc.demo("needsLogin") === "Not in demo mode");
        },
        () => {
            // The knocks run one after the other (2 s each at most)
            check("ssh as a user opens a terminal at once, with user@fqdn", Quickshell.launched.some(l => l.slice(-1)[0] === "tom@atlas.netbird.cloud"), Quickshell.launched);
            check("a device that does not answer says how to fix it", ToastService.warned.some(t => t.indexOf("! atlas is not sharing its screen") === 0), ToastService.warned);
            PluginService.savePluginData("abyss", "source", "demo");
        },
        () => {
            check("the demo setting swaps the source", daemon.source && daemon.source.demo);
            check("ipc demo works there", test.ipc.demo("needsLogin") === "needsLogin");
            check("the ping was announced, then answered", ToastService.shown.some(t => t === "Abyss: Pinging atlas…") && ToastService.shown.some(t => t === "Abyss: atlas: no answer"), ToastService.shown);
            check("nothing went wrong in silence", ToastService.shown.filter(t => t.indexOf("Copied") === 0).length === 1 && !ToastService.shown.some(t => /Could not|Refused|Not /.test(t)), ToastService.shown);
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
