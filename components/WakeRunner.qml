import QtQuick
import "Wake.js" as Wake
import "Connect.js" as Connect

// Wakes a sleeping device with a Wake-on-LAN magic packet and reports how it
// went. wake() picks the way (Wake.route): from this computer when it is on
// the device's network, otherwise through an online peer of that network over
// ssh. The sending program is looked for first, so a missing one is explained
// instead of failing obscurely. Every step is a CliRunner job on a runner made
// at the first wake and dropped at the end: nothing exists or runs until
// someone wakes a device, and nothing after.
// state: "idle", "checking", "waking", "done" or "failed". When it ends,
// finished(ok, text, failure) carries a short sentence and, on a failure,
// { kind, title, advice, guide[, command] } (see Wake.explain). A sent packet
// is not a woken device, and the sentence says "signal sent", nothing more.
// The address, the name and the command line are never logged.
QtObject {
    id: root

    readonly property string state: root._state
    readonly property string text: root._text
    readonly property var failure: root._failure
    readonly property bool busy: root.state === "checking" || root.state === "waking"

    signal finished(bool ok, string text, var failure)

    // One packet leaves in a blink; this only bounds a stuck program or an
    // ssh that waits on a peer gone silent
    property int commandTimeout: 20000

    property string _state: "idle"
    property string _text: ""
    property var _failure: null
    property var _run: null
    // Bumped by every wake and cancel: a callback of an older one is ignored
    property int _round: 0

    // target: { id, mac, lan } saved for the device; here: this computer's
    // network key (Wake.lanKey); peers: [{ id, online, lan, host, link,
    // name }]; name: the device's, for the sentences. False when one wake is
    // already under way.
    function wake(target, here, peers, name) {
        if (root.busy)
            return false;
        const round = ++root._round;
        const way = Wake.route(target, here, peers);
        if (way.kind === "none") {
            root._end(false, "", Wake.routeNote(way.reason, name));
            return true;
        }
        root._failure = null;
        root._state = "checking";
        root._text = Wake.wakingText(name);
        root._run = runC.createObject(root, {
            "timeout": root.commandTimeout
        });
        if (way.kind === "peer")
            root._viaPeer(round, way.peer, Wake.known(target).mac, name);
        else
            root._direct(round, Wake.known(target).mac, name);
        return true;
    }

    // Stops a wake under way, quietly: the program is killed, nothing is
    // reported (the caller asked for it)
    function cancel() {
        if (!root.busy)
            return;
        root._round++;
        root._drop();
        root._state = "idle";
        root._text = "";
    }

    function _direct(round, mac, name) {
        root._run.run(Wake.toolCommand(), (out, err, code) => {
            if (round !== root._round)
                return;
            const tool = Wake.parseTool(out);
            if (code !== 0 || tool === "") {
                root._noTool(round, "here");
                return;
            }
            root._state = "waking";
            root._run.run(Wake.directCommand(tool, mac), (o, e, c) => {
                if (round !== root._round)
                    return;
                root._result(c, "direct", name, "");
            });
        });
    }

    function _viaPeer(round, peer, mac, name) {
        const peerName = String(peer.name || "");
        const argv = Wake.peerCommand(peer.host, peer.link, mac);
        root._state = "waking";
        root._run.run(argv, (o, e, c) => {
            if (round !== root._round)
                return;
            root._result(c, "peer", name, peerName);
        });
    }

    function _result(code, via, name, peerName) {
        if (code === 0)
            root._end(true, Wake.doneText(name, via, peerName), null);
        else
            root._end(false, "", Wake.explain(code, via, name, peerName));
    }

    // Looks for the package manager so the note can give the install command;
    // the note is the same, without the command, when none is found
    function _noTool(round, where) {
        root._run.run(Connect.packageManagerCommand(), (out, err, code) => {
            if (round !== root._round)
                return;
            root._end(false, "", Wake.toolNote(where, code === 0 ? String(out).trim() : ""));
        });
    }

    function _end(ok, text, failure) {
        root._drop();
        root._state = ok ? "done" : "failed";
        root._text = ok ? text : failure.title;
        root._failure = failure;
        root.finished(ok, root._text, failure);
    }

    function _drop() {
        if (!root._run)
            return;
        root._run.stop();
        root._run.destroy();
        root._run = null;
    }

    property Component _runner: Component {
        id: runC
        CliRunner {}
    }
}
