import QtQuick
import qs.Services
import "../.."
import "../../components"

// The test lab: DemoSource follows each lab setting, and the daemon hands
// the saved settings to it. Run: tests/qml/qmltest.py tests/qml/Lab.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property var events: []

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    DemoSource {
        id: src
        labMesh: "lab"
        labPeers: 12
        labTrouble: "silent"
        onPeerEvent: (name, online) => test.events.push(name + (online ? " up" : " down"))
    }

    function omen(kind) {
        return src.view.omens.some(o => o.kind === kind);
    }

    // After every object here is complete (the order of onCompleted is not set)
    Component.onCompleted: Qt.callLater(run)

    function run() {
        check("starts on the lab mesh at its size", src.profile === "lab" && src.view.total === 12, [src.profile, src.view.total]);
        check("the trouble applies from the start", omen("silent") && src.silentPeer !== "", src.view.omens);
        check("priming tells nobody", test.events.length === 0, test.events);

        src.labPeers = 60;
        check("a new size rebuilds the mesh", src.view.total === 60 && src.view.peers.every(p => !p.name.startsWith("heron")), src.view.total);

        const near = src.view.peers.find(p => p.online).latencyMs;
        src.labLatency = 100;
        check("added latency shows at once", Math.abs(src.view.peers.find(p => p.online).latencyMs - near - 100) < 1e-6);

        src.labTrouble = "relay";
        check("a relay goes down", omen("relay") && src.relayDown !== "" && !omen("silent"), src.view.omens);
        src.labTrouble = "management";
        check("management unreachable", omen("management") && src.relayDown === "", src.view.omens);
        src.labTrouble = "signedOut";
        check("signed out", src.view.state === "needsLogin");
        src.labTrouble = "stopped";
        check("service stopped", src.view.state === "stopped");
        src.labTrouble = "none";
        check("none brings the mesh back", src.view.state === "connected" && src.view.omens.length === 0, [src.view.state, src.view.omens]);

        src.labTrouble = "flap";
        const who = src.flappingPeer;
        for (let i = 0; i < 12; i++)
            src._step(Date.now() + i * 1000);
        check("the flapping peer drops out and comes back", who !== "" && test.events.indexOf(who + " down") >= 0 && test.events.indexOf(who + " up") >= 0, test.events);
        src.labTrouble = "none";

        src.labTraffic = "calm";
        src._counters = {};
        src._step(Date.now() + 20000);
        const calm = Object.values(src._counters).reduce((a, c) => a + c.rx, 0);
        src.labTraffic = "rush";
        src._counters = {};
        src._step(Date.now() + 21000);
        const rush = Object.values(src._counters).reduce((a, c) => a + c.rx, 0);
        check("rush hour moves far more than calm", rush > calm * 8, [calm, rush]);

        src.labMesh = "work";
        check("another mesh", src.profile === "work" && src.view.total === 5);

        // The daemon passes the saved settings on
        PluginService.savePluginData("abyss", "source", "demo");
        PluginService.savePluginData("abyss", "labMesh", "crowd");
        PluginService.savePluginData("abyss", "labTrouble", "management");
        daemonLoader.active = true;
    }

    Loader {
        id: daemonLoader
        active: false
        sourceComponent: AbyssDaemon {}
        onLoaded: Qt.callLater(test.finish)
    }

    function finish() {
        const s = daemonLoader.item.source;
        check("the daemon uses the lab's settings", !!s && s.demo && s.profile === "crowd" && s.view.omens.some(o => o.kind === "management"), s ? [s.profile, s.view.omens] : null);
        PluginService.savePluginData("abyss", "labTrouble", "none");
        check("and follows them", s.view.omens.length === 0, s.view.omens);
        console.log((test.fails ? "✗" : "✓") + " Test lab: " + (test.count - test.fails) + "/" + test.count + " passed");
        Qt.exit(test.fails ? 1 : 0);
    }
}
