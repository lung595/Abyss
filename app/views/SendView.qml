pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../components/SendQueue.js" as Queue
import "../components/SendTransfer.js" as Transfer
import "../components/Send.js" as Send
import "../components/SendFlow.js" as Flow

// The Send station: drop zone, the "To" devices, the queue and the session
// history. All the rules live in SendQueue.js (jobs, states, caps) and
// SendTransfer.js (commands, meter); this file wires them to the window.
// Nothing runs with an empty queue, and nothing is written to disk: the
// history dies with the window.
Item {
    id: view

    // The mesh peers ({ id, name, fqdn, ip, online }); null while unknown
    property var peers: null
    // The device the command line or the peer card asked for; "" for none
    property string device: ""
    property string sendFolder: ""
    // False sends with scp only, without looking for rsync on either side
    property bool preferRsync: true
    // Per-device ssh settings ({ user, port }); the app has none yet
    property var linkOf: id => ({})
    // False while the window is hidden: the indeterminate segment stops
    property bool shown: true
    // The queue state (SendQueue.js); replaced, never edited
    property var q: Queue.empty()
    property var chosen: []
    // Files dropped before any device was ticked, added once one is
    property var pending: []
    // The guided message on the last refusal or failure, or null
    property var failure: null
    // Meter text per job id, and the commands per job id
    property var rates: ({})
    property var argvs: ({})

    readonly property var online: (Array.isArray(peers) ? peers : []).filter(p => p.online)
    readonly property var names: online.map(p => p.name)

    function peerOf(name) {
        return online.find(p => p.name === name) ?? null;
    }

    // Files and folders (paths or file:// URLs) from a drop, the picker or Ctrl+V
    function addItems(items) {
        const clean = Send.cleanPaths(items);
        if (!clean.ok) {
            failure = Send.refusal(clean.reason);
            return;
        }
        failure = null;
        if (chosen.length === 0) {
            // The device choice opens first; the files wait for it
            pending = clean.paths;
            return;
        }
        _enqueue(clean.paths);
    }

    function toggle(name) {
        const on = chosen.indexOf(name) >= 0;
        chosen = on ? chosen.filter(n => n !== name) : chosen.concat([name]);
        if (pending.length > 0 && chosen.length > 0) {
            const paths = pending;
            pending = [];
            _enqueue(paths);
        }
    }

    function act(job, kind) {
        if (kind === "cancel")
            q = Queue.cancel(q, job.id);
        else if (kind === "retry")
            q = Queue.retry(q, job.id);
        else
            q = Queue.clearHistory(q);
        _pump();
    }

    function cancelAll() {
        q = Queue.cancelAll(q);
    }

    // Ctrl+V: the clipboard is read once, here, and nothing of it is kept
    function paste() {
        _ask(Flow.pasteCommand(), 10000, (out, code) => {
            const fail = Flow.pasteFailure(code, out);
            if (fail)
                failure = fail;
            else
                addItems(Flow.pastedItems(out));
        });
    }

    function pick() {
        _ask(Flow.pickCommand("", false), 600000, (out, code) => {
            const fail = Flow.pickFailure(code);
            if (fail)
                failure = fail;
            else if (out.trim() !== "")
                addItems(out.split("\n").filter(l => l !== ""));
        });
    }

    function _enqueue(paths) {
        const r = Queue.add(q, paths, chosen);
        q = r.state;
        if (r.skipped > 0)
            failure = {
                "kind": "cap",
                "title": r.skipped + " already queued or over the limit",
                "advice": "Wait for the queue to empty, then add them again.",
                "guide": Send.GUIDE
            };
        _pump();
    }

    // Starts what may start: the first queued job of each idle device
    function _pump() {
        for (const id of Queue.startable(q)) {
            const job = q.jobs.find(j => j.id === id);
            const peer = peerOf(job.device);
            q = Queue.start(q, id);
            if (!peer) {
                q = Queue.fail(q, id, "offline");
                continue;
            }
            _begin(id, peer, job.path);
        }
    }

    // rsync when both ends have it (checked once per job), else scp
    function _begin(id, peer, path) {
        const host = peer.fqdn || peer.ip;
        const link = linkOf(peer.id);
        if (!preferRsync) {
            _plan(id, "scp", host, link, path);
            return;
        }
        _ask(["which", "rsync"], 5000, (o, localCode) => {
            const go = prog => _plan(id, prog, host, link, path);
            if (localCode !== 0)
                go("scp");
            else
                _ask(Transfer.remoteProbe(host, link), 15000, (out, code) => go(Transfer.program(true, code === 0 && out.trim() !== "")));
        });
    }

    function _plan(id, prog, host, link, path) {
        const plan = Transfer.plan(prog, host, link, [path], sendFolder);
        if (!plan.ok) {
            q = Queue.fail(q, id, plan.reason);
            failure = Send.refusal(plan.reason);
            _pump();
            return;
        }
        const a = Object.assign({}, argvs);
        a[id] = plan.argv;
        argvs = a;
    }

    function _ended(job, code, stderr) {
        const peer = peerOf(job.device);
        if (code === 0) {
            q = Queue.finish(q, job.id);
        } else {
            const why = Send.explain(code, stderr, peer ? peer.name : job.device, false);
            q = Queue.fail(q, job.id, why.title);
            failure = why;
        }
        _pump();
    }

    function _ask(argv, timeout, done) {
        const run = runnerC.createObject(view, {
            "timeout": timeout
        });
        run.run(argv, (out, err, code) => {
            run.destroy();
            done(out, code);
        });
    }

    // The device the command line asked for is ticked once the mesh knows it
    function _adopt() {
        if (device !== "" && peerOf(device) && chosen.indexOf(device) < 0)
            chosen = chosen.concat([device]);
    }

    onDeviceChanged: _adopt()
    onPeersChanged: _adopt()
    Component.onCompleted: _adopt()

    Shortcut {
        sequence: "Ctrl+V"
        // A text field keeps its own paste
        enabled: !(view.Window.activeFocusItem && view.Window.activeFocusItem.hasOwnProperty("selectedText"))
        onActivated: view.paste()
    }

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: view.pick()
    }

    DropZone {
        id: zone

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        onDropped: urls => view.addItems(urls)
        onPickRequested: view.pick()
    }

    DevicePicker {
        id: to

        y: zone.height + Theme.spacingXL
        names: view.names
        chosen: view.chosen
        onToggled: name => view.toggle(name)
    }

    GuideBand {
        id: band

        visible: view.failure !== null
        anchors {
            left: parent.left
            right: parent.right
            top: to.bottom
            topMargin: Theme.spacingM
        }
        message: view.failure ? view.failure.title + ". " + view.failure.advice : ""
        anchor: view.failure ? Flow.anchor(view.failure) : ""
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: band.visible ? band.bottom : to.bottom
            topMargin: Theme.spacingXL
            bottom: parent.bottom
        }
        clip: true

        Repeater {
            model: view.q.jobs

            SendJobRow {
                required property var modelData

                width: view.width
                job: modelData
                rate: view.rates[modelData.id] ?? ""
                animate: view.shown
                onAction: kind => view.act(modelData, kind)
            }
        }

        Text {
            visible: view.q.history.length > 0
            height: visible ? 44 : 0
            verticalAlignment: Text.AlignVCenter
            text: "History"
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.DemiBold
        }

        Repeater {
            model: view.q.history

            SendJobRow {
                required property var modelData

                width: view.width
                job: modelData
                onAction: kind => view.act(modelData, kind)
            }
        }
    }

    // One process per sending job, alive only while it sends; removing the
    // job (cancel) destroys the delegate and with it the program
    Repeater {
        model: view.q.jobs.filter(j => j.state === "sending" && view.argvs[j.id])

        SendJobProcess {
            id: proc

            required property var modelData

            argv: view.argvs[modelData.id]
            running: true
            onProgressed: (fraction, rate) => {
                view.q = Queue.progress(view.q, proc.modelData.id, fraction);
                const r = Object.assign({}, view.rates);
                r[proc.modelData.id] = rate;
                view.rates = r;
            }
            onEnded: (code, stderr) => view._ended(proc.modelData, code, stderr)
        }
    }

    Component {
        id: runnerC

        CliRunner {}
    }
}
