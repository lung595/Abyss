import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import qs.Services
import "../.." as Abyss

// The launcher entry against a fake daemon and a cold source: a send sentence
// reads the peers once and is asked again when they land, other searches read
// nothing, and running the entry opens the app (or the picker without it).
// The `abyss` lookup is a stand-in Process (tests/scene/imports). Not covered
// here: Sands loaded next to Abyss and a real PATH lookup.
// Run: tests/scene/run.sh
Window {
    id: win

    property int fails: 0
    property int count: 0

    width: 100
    height: 100
    visible: true

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    // What AbyssLauncher reads of the NetBird source and the daemon
    QtObject {
        id: daemon
        property var calls: []
        property var source: QtObject {
            property bool demo: false
            property string exitNode: ""
            property int reads: 0
            property var view: ({
                    "state": "connected",
                    "peers": [],
                    "relays": []
                })
            function refresh(now) {
                reads++;
            }
        }
        property var send: QtObject {
            function pick(peer, folder) {
                daemon.calls = daemon.calls.concat([["pick", peer.name]]);
            }
        }
        function findPeer(name) {
            return source.view.peers.find(p => p.name === name) ?? null;
        }
        function open() {
            calls = calls.concat([["open"]]);
        }
    }

    Abyss.AbyssLauncher {
        id: launcher
    }

    property int asked: 0
    Connections {
        target: launcher
        function onItemsChanged() {
            win.asked++;
        }
    }

    readonly property var vega: ({
            "id": "p1",
            "name": "vega",
            "ip": "100.64.0.2",
            "fqdn": "vega.mesh",
            "online": true
        })

    function launch(item, installed) {
        Quickshell.installed = installed;
        Quickshell.launched = [];
        daemon.calls = [];
        launcher.executeItem(item);
    }

    // The picker and the deep open 150 ms after the launcher closed
    Timer {
        id: settle
        interval: 400
        onTriggered: win.steps.shift()()
    }
    property var steps: []
    function then(fn) {
        steps.push(fn);
        settle.restart();
    }

    function run() {
        PluginService.pluginDaemonInstances = {
            "abyss": daemon
        };
        PluginService.launcherTrigger = "";

        // (a) cold source: "send to vega" cannot name a device yet
        check("cold: nothing before the read", launcher.getItems("send to vega").length === 0);
        check("cold: one read asked", daemon.source.reads === 1, daemon.source.reads);
        daemon.source.view = {
            "state": "connected",
            "peers": [vega],
            "relays": []
        };
        check("cold: asked again once the read lands", asked === 1, asked);
        const rows = launcher.getItems("send to vega");
        check("cold: the entry names the device", rows.length === 1 && rows[0].name === "Send a file to vega…", rows);
        check("send entry reuses the upload icon", rows[0].icon === "material:upload_file", rows[0]);

        // (b) a search that is not a send reads nothing and answers nothing
        const reads = daemon.source.reads;
        check("plain search: no row", launcher.getItems("firefox").length === 0);
        check("plain search: no read", daemon.source.reads === reads, daemon.source.reads);

        // (c) the app is on PATH: it opens on sending, the picker stays closed
        launch({
            "action": "send:vega"
        }, true);
        then(() => {
            check("app found: abyss send vega", JSON.stringify(Quickshell.launched) === '[["abyss","send","vega"]]', Quickshell.launched);
            check("app found: the picker stays closed", daemon.calls.length === 0, daemon.calls);
            // ... or not: the picker opens on the peer
            launch({
                "action": "send:vega"
            }, false);
            then(() => {
                check("no app: picker on the peer", JSON.stringify(daemon.calls) === '[["pick","vega"]]', daemon.calls);
                check("no app: nothing launched", Quickshell.launched.length === 0, Quickshell.launched);
                // (d) no device named
                launch({
                    "action": "send:"
                }, true);
                then(() => {
                    check("app, no device: abyss alone", JSON.stringify(Quickshell.launched) === '[["abyss"]]', Quickshell.launched);
                    launch({
                        "action": "send:"
                    }, false);
                    then(() => {
                        check("no app, no device: the deep opens", JSON.stringify(daemon.calls) === '[["open"]]', daemon.calls);
                        finish();
                    });
                });
            });
        });
    }

    function finish() {
        // (e) with a prefix set, DMS has stripped it: every row is ours
        PluginService.launcherTrigger = "abyss";
        check("prefix: all rows", launcher.getItems("").length >= 2);
        PluginService.launcherTrigger = "";
        check("no prefix: the abyss word still answers", launcher.getItems("abyss").length >= 2);
        console.log((fails === 0 ? "✓ " : "✗ ") + "Launcher: " + (count - fails) + "/" + count);
        Qt.exit(fails);
    }

    Component.onCompleted: Qt.callLater(run)
}
