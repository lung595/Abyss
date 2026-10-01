import QtQuick
import "../../components"

// NetbirdSource against tests/qml/fake-netbird, through real processes.
// Run: tests/qml/qmltest.py tests/qml/NetbirdSource.test.qml
// Each step acts, waits for the reads to land, then checks.
Item {
    id: test

    property int fails: 0
    property int count: 0
    property var notices: []
    property int step: 0

    NetbirdSource {
        id: src
        onNotice: text => test.notices = test.notices.concat([text])
    }

    CliRunner {
        id: sh
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

    function calls() {
        const x = new XMLHttpRequest();
        x.open("GET", "file://" + fakeDir + "/calls.log", false);
        x.send();
        return x.responseText.split("\n").filter(l => l);
    }
    function called(line) {
        return calls().indexOf(line) >= 0;
    }
    function peer(name) {
        return src.view.peers.find(p => p.name === name);
    }
    // Test hook of the fake: changes its state
    function fake(key, value) {
        sh.run(["netbird", "_set", key, JSON.stringify(value)], () => {});
    }

    property var steps: [
        // Opening a view reads networks, profiles and the status
        () => src.watch(true),
        () => {
            check("connected", src.view.state === "connected", src.view.state);
            check("4 peers, 3 online", src.view.total === 4 && src.view.online === 3, [src.view.total, src.view.online]);
            check("profiles", JSON.stringify(src.profiles) === '["default","work"]' && src.profile === "default", [src.profiles, src.profile]);
            check("one cave: the LAN, via nook-nas, on", JSON.stringify(src.networks) === '[{"id":"home-lan","cidr":"192.168.1.0/24","via":"nook-nas","on":true}]', src.networks);
            check("no exit yet", src.exitNode === "");
            check("routes named after peers make them lenders", peer("atlas").exit && peer("harbor-vps").exit && !peer("nook-nas").exit);
            check("the read commands", called("status --json") && called("networks list") && called("profile list"), calls());
            src.setExitNode("atlas");
            check("the light moves at once", src.exitNode === "atlas" && src.busy);
        },
        () => {
            check("select the atlas route", called("networks select -a -- exit-atlas"), calls());
            check("atlas lends Internet", src.exitNode === "atlas" && peer("atlas").lending);
            check("rates measured", peer("atlas").down > 0, peer("atlas").down);
            check("history kept", (src.history[peer("atlas").id] || []).length >= 2);
            src.setExitNode("harbor-vps");
        },
        () => {
            check("the old route is dropped first", called("networks deselect -- exit-atlas") && called("networks select -a -- exit-harbor"), calls());
            check("harbor lends Internet", src.exitNode === "harbor-vps" && peer("harbor-vps").lending && !peer("atlas").lending);
            src.setExitNode("nook-nas");
            check("a peer with no route is refused, saying why", notices.length === 1 && notices[0].indexOf("dashboard") >= 0, notices);
            check("...and the light stays", src.exitNode === "harbor-vps");
            src.setExitNode("");
        },
        () => {
            check("stopping drops the route", called("networks deselect -- exit-harbor"), calls());
            check("Internet goes out directly", src.exitNode === "" && !src.view.peers.some(p => p.lending));
            src.toggleNetwork("home-lan");
        },
        () => {
            check("a cave switched off", called("networks deselect -- home-lan") && src.networks[0].on === false, src.networks);
            fake("fail", "up");
            src.disconnect();
        },
        () => {
            check("disconnected", src.view.state === "disconnected", src.view.state);
            src.connect();
        },
        () => {
            check("a failed up says why", notices.some(n => n.indexOf("Could not connect: Error: up failed") === 0), notices);
            check("...and stays disconnected", src.view.state === "disconnected", src.view.state);
            fake("fail", "");
        },
        () => src.setProfile("work"),
        () => {
            check("profile switched, no up while it was off", src.profile === "work" && called("profile select work") && calls().filter(l => l === "up").length === 1, calls());
            src.connect();
        },
        () => {
            check("connected again", src.view.state === "connected", src.view.state);
            src.setExitNode("harbor-vps");
        },
        () => {
            check("harbor lends Internet again", src.exitNode === "harbor-vps", src.exitNode);
            fake("fail", "networks");
        },
        () => {
            test.before = calls().length;
            src.setExitNode("atlas");
        },
        () => {
            const after = calls().slice(test.before);
            check("a failed deselect skips the select", after.indexOf("networks deselect -- exit-harbor") >= 0 && !after.some(l => l.indexOf("networks select") === 0), after);
            check("...says why", notices.some(n => n.indexOf("Could not go out through atlas: Error: networks failed") === 0), notices);
            check("...and the light goes back", src.exitNode === "harbor-vps", src.exitNode);
            fake("fail", "");
            fake("daemon", "stopped");
        },
        () => {
            check("no daemon: stopped", src.view.state === "stopped", src.view.state);
            check("...with the reason", src.error.indexOf("failed to connect to daemon") >= 0, src.error);
            src.watch(false);
            test.quiet = calls().length;
        },
        () => {
            check("nothing runs while no view watches", calls().length === test.quiet, calls().length - test.quiet);
        }
    ]
    property int quiet: 0
    property int before: 0

    Timer {
        interval: 2600
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (test.step < test.steps.length) {
                test.steps[test.step++]();
                return;
            }
            stop();
            console.log((test.fails ? "✗" : "✓") + " NetbirdSource: " + (test.count - test.fails) + "/" + test.count + " passed");
            Qt.exit(test.fails ? 1 : 0);
        }
    }
}
