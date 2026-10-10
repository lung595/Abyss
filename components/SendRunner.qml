import QtQuick
import "Send.js" as Send

// Sends files and folders to a peer with scp and reports how it went.
// send() looks at the items first (du, so a missing item or a huge drop is
// refused before anything leaves), then runs the transfer. Both are
// CliRunner jobs on a runner made at the first send and dropped at the end:
// nothing exists or runs until someone sends, and nothing after.
// Progress is -1 (indeterminate) while sending: scp prints no meter without
// a terminal, and a guess would be worse than none.
// state: "idle", "checking", "sending", "done" or "failed". When it ends,
// finished(ok, text, failure) carries a short sentence and, on a failure,
// { kind, title, advice, guide } (see Send.explain). Nothing about the
// files, the address or scp's own words is ever logged.
QtObject {
    id: root

    readonly property string state: root._state
    readonly property real progress: root._progress
    readonly property string text: root._text
    readonly property var failure: root._failure
    readonly property bool busy: root.state === "checking" || root.state === "sending"

    signal finished(bool ok, string text, var failure)

    // A transfer is allowed this long at most; a connection gone silent ends
    // far sooner (ssh's keep-alive), this only bounds a stuck program
    property int transferTimeout: 12 * 3600 * 1000
    property int checkTimeout: 30000

    property string _state: "idle"
    property real _progress: -1
    property string _text: ""
    property var _failure: null
    property var _run: null
    // When the transfer started, to tell a timeout from a program that
    // could not start (both end with exit code -1)
    property double _startedAt: 0
    // Bumped by every send and cancel: a callback of an older one is ignored
    property int _round: 0

    // host: the peer's address; link: { user, port } saved for it; items:
    // paths or file:// URLs (the clipboard gives either); folder: the destination
    // setting ("" for the default); name: the device's, for the sentences.
    // False when one is already under way.
    function send(host, link, items, folder, name) {
        if (root.busy)
            return false;
        const round = ++root._round;
        const plan = Send.plan(host, link, items, folder);
        if (!plan.ok) {
            root._end(false, plan.reason, Send.refusal(plan.reason));
            return true;
        }
        root._failure = null;
        root._progress = -1;
        root._state = "checking";
        root._text = "Looking at what to send";
        root._run = runC.createObject(root, {
            "timeout": root.checkTimeout
        });
        root._run.run(Send.sizeCommand(plan.paths), (out, err, code) => {
            if (round !== root._round)
                return;
            if (code === -1) {
                root._end(false, "Abyss could not size up what you want to send", Send.checkTimeout());
                return;
            }
            const sizes = Send.parseSizes(out, plan.paths);
            const verdict = Send.checkSizes(sizes);
            if (!verdict.ok) {
                root._end(false, verdict.reason, Send.refusal(verdict.reason));
                return;
            }
            root._state = "sending";
            root._startedAt = Date.now();
            root._text = Send.sendingText(name);
            root._run.run({
                "argv": plan.argv,
                "timeout": root.transferTimeout
            }, (o, e, c) => {
                if (round !== root._round)
                    return;
                if (c === 0) {
                    root._progress = 1;
                    root._end(true, Send.doneText(name, plan.paths.length), null);
                } else {
                    const why = Send.explain(c, e, name, c === -1 && Date.now() - root._startedAt >= root.transferTimeout - 1000);
                    root._end(false, why.title, why);
                }
            });
        });
        return true;
    }

    // Stops a send under way, quietly: the program is killed, nothing is
    // reported (the caller asked for it)
    function cancel() {
        if (!root.busy)
            return;
        root._round++;
        root._drop();
        root._state = "idle";
        root._progress = -1;
        root._text = "";
    }

    function _end(ok, text, failure) {
        root._drop();
        root._state = ok ? "done" : "failed";
        root._text = text;
        root._failure = failure;
        root.finished(ok, text, failure);
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
