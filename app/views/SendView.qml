pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    // The files of `abyss send <device> files...`, already resolved and capped
    property var files: []
    // False sends with scp only, without looking for rsync on either side
    property bool preferRsync: true
    // False while the window is hidden: the indeterminate segment and the
    // meter stop
    property bool shown: true
    // "Now" for the history ages: refreshed when the queue changes and when the
    // window is shown again, so no timer runs for it
    property real clock: Date.now()
    onShownChanged: clock = Date.now()
    // Set by the window after a first close attempt during a transfer
    property bool closeAsked: false
    // The queue state (SendQueue.js); replaced, never edited
    property var q: Queue.empty()
    property var chosen: []
    // Files dropped before any device was ticked, added once one is
    property var pending: []
    // The guided message on the last refusal or failure, or null
    property var failure: null
    // Meter text per job id
    property var rates: ({})
    // rsync/scp per device name, and whether this machine has rsync
    property var programs: ({})
    property var localRsync: null
    // The probes in flight (stopped by cancelAll) and who waits for each
    property var probes: []
    property var waiting: ({})

    // False while a text field has the focus: it keeps its own paste
    readonly property bool pasteIsOurs: !(Window.activeFocusItem && Window.activeFocusItem.hasOwnProperty("selectedText"))
    readonly property bool busy: q.jobs.some(j => j.state === "queued" || j.state === "sending")
    // The height of the "History" heading: a 44 px target like the buttons
    readonly property int headerHeight: 44
    // The job the shown failure belongs to (0 for none): the band's Retry sends that one
    property int failedId: 0
    readonly property var lastFailed: failedId > 0 ? q.history.find(j => j.id === failedId) ?? null : null
    readonly property int runningCount: running.count
    // The scrolling list under the "To" row (queue, band, history)
    readonly property Flickable list: scroller
    readonly property var online: (Array.isArray(peers) ? peers : []).filter(p => p.online)
    readonly property var names: online.map(p => p.name)
    readonly property var notice: closeAsked ? {
        "title": "Transfers are still running",
        "advice": "Close the window again to cancel them, or wait.",
        "guide": Send.GUIDE
    } : failure

    // The one way to set the band: the message and the job its Retry sends (0 for none)
    function say(message, jobId) {
        failure = message;
        failedId = jobId;
    }

    // The job object a row shows, from its model roles
    function rowJob(m) {
        return {
            "id": m.jid,
            "device": m.device,
            "path": m.path,
            "state": m.state,
            "progress": m.progress < 0 ? null : m.progress,
            "reason": m.reason,
            "at": m.at
        };
    }

    function peerOf(name) {
        // `online` is not bound yet when the first property is set at creation
        return (online ?? []).find(p => p.name === name) ?? null;
    }

    // Files and folders (paths or file:// URLs) from a drop, the picker or Ctrl+V
    // `only`: a device name when the files were dropped on its chip
    function addItems(items, only) {
        const clean = Send.cleanPaths(items);
        if (!clean.ok) {
            say(Send.refusal(clean.reason), 0);
            return;
        }
        say(null, 0);
        if (only) {
            _enqueue(clean.paths, [only]);
            return;
        }
        if (chosen.length === 0) {
            // The device choice opens first; the files wait for it
            pending = clean.paths;
            return;
        }
        _enqueue(clean.paths, chosen);
    }

    function toggle(name) {
        const on = chosen.indexOf(name) >= 0;
        chosen = on ? chosen.filter(n => n !== name) : chosen.concat([name]);
        if (pending.length > 0 && chosen.length > 0) {
            const paths = pending;
            pending = [];
            _enqueue(paths, chosen);
        }
    }

    function act(job, kind) {
        if (kind === "cancel")
            q = Queue.cancel(q, job.id, Date.now());
        else if (kind === "retry") {
            q = Queue.retry(q, job.id);
            if (job.id === failedId)
                say(null, 0);
        } else
            q = Queue.dismiss(q, job.id);
        _pump();
    }

    // Window closing: every job ends and no program or probe is left behind
    function cancelAll() {
        _stopProbes();
        q = Queue.cancelAll(q, Date.now());
    }

    // Ctrl+V: the clipboard is read once, here, and nothing of it is kept
    function paste() {
        _ask(Flow.pasteCommand(), 10000, (out, code) => {
            const fail = Flow.pasteFailure(code, out);
            if (fail)
                say(fail, 0);
            else
                addItems(Flow.pastedItems(out));
        });
    }

    function pick() {
        _ask(Flow.pickCommand("", false), 600000, (out, code) => {
            const fail = Flow.pickFailure(code);
            if (fail)
                say(fail, 0);
            else if (out.trim() !== "")
                addItems(out.split("\n").filter(l => l !== ""));
        });
    }

    function _enqueue(paths, devices) {
        const r = Queue.add(q, paths, devices);
        q = r.state;
        if (r.skipped > 0)
            say({
                "kind": "cap",
                "title": r.skipped + " already queued or over the limit",
                "advice": "Wait for the queue to empty, then add them again.",
                "guide": Send.GUIDE
            }, 0);
        _pump();
    }

    // Starts what may start: the first queued job of each idle device
    function _pump() {
        for (const id of Queue.startable(q)) {
            const job = q.jobs.find(j => j.id === id);
            const peer = peerOf(job.device);
            q = Queue.start(q, id);
            if (!peer) {
                q = Queue.fail(q, id, "offline", Date.now());
                continue;
            }
            _program(peer, prog => _plan(id, prog, peer.fqdn || peer.ip, job.path));
        }
    }

    // rsync when both ends have it, else scp; looked up once per device
    function _program(peer, done) {
        const known = programs[peer.name];
        if (known !== undefined) {
            done(known);
            return;
        }
        if (!preferRsync) {
            done("scp");
            return;
        }
        const queue = waiting[peer.name];
        if (queue) {
            queue.push(done);
            return;
        }
        waiting[peer.name] = [done];
        const settle = prog => {
            programs[peer.name] = prog;
            const callbacks = waiting[peer.name] ?? [];
            delete waiting[peer.name];
            callbacks.forEach(cb => cb(prog));
        };
        const remote = () => _ask(Transfer.remoteProbe(peer.fqdn || peer.ip, {}), 15000, (out, code) => settle(Transfer.program(true, code === 0 && out.trim() !== "")), true);
        if (localRsync !== null) {
            localRsync ? remote() : settle("scp");
            return;
        }
        _ask(["which", "rsync"], 5000, (o, code) => {
            localRsync = code === 0;
            localRsync ? remote() : settle("scp");
        }, true);
    }

    function _plan(id, prog, host, path) {
        // Cancelled while the probe ran: nothing to start
        if (!q.jobs.some(j => j.id === id && j.state === "sending"))
            return;
        // Retried while its first probe was still running: already started
        for (let i = 0; i < running.count; i++)
            if (running.get(i).jid === id)
                return;
        const plan = Transfer.plan(prog, host, {}, [path], "");
        if (!plan.ok) {
            q = Queue.fail(q, id, plan.reason, Date.now());
            say(Send.refusal(plan.reason), id);
            _pump();
            return;
        }
        running.append({
            "jid": id,
            "argvJson": JSON.stringify(plan.argv)
        });
    }

    function _ended(id, code, stderr) {
        const job = q.jobs.find(j => j.id === id);
        if (!job)
            return;
        const peer = peerOf(job.device);
        if (code === 0) {
            q = Queue.finish(q, id, Date.now());
        } else {
            const why = Send.explain(code, stderr, peer ? peer.name : job.device, false);
            q = Queue.fail(q, id, why.title, Date.now());
            say(why, id);
        }
        _pump();
    }

    // Keeps the rows, the programs and the meters in step with the queue: a
    // program whose job left the live list (done, failed, cancelled) is
    // removed here, which destroys its delegate and with it the process
    onQChanged: {
        liveRows.sync(q.jobs);
        historyRows.sync(q.history);
        clock = Date.now();
        const sending = new Set(q.jobs.filter(j => j.state === "sending").map(j => j.id));
        for (let i = running.count - 1; i >= 0; i--)
            if (!sending.has(running.get(i).jid))
                running.remove(i);
        const kept = {};
        for (const id in rates)
            if (sending.has(Number(id)))
                kept[id] = rates[id];
        if (Object.keys(kept).length !== Object.keys(rates).length)
            rates = kept;
    }

    // tracked: a probe that cancelAll must stop (ssh may wait up to 15 s)
    function _ask(argv, timeout, done, tracked) {
        const run = runnerC.createObject(view, {
            "timeout": timeout
        });
        if (tracked)
            probes.push(run);
        run.run(argv, (out, err, code) => {
            probes = probes.filter(r => r !== run);
            run.destroy();
            done(out, code);
        });
    }

    function _stopProbes() {
        for (const run of probes) {
            run.stop();
            run.destroy();
        }
        probes = [];
        waiting = {};
    }

    // The device the command line asked for is ticked once the mesh knows it
    function _adopt() {
        if (device !== "" && peerOf(device) && chosen.indexOf(device) < 0)
            toggle(device);
    }

    onDeviceChanged: _adopt()
    onPeersChanged: _adopt()
    onFilesChanged: if (files.length > 0)
        addItems(files)
    // The files arrive through onFilesChanged (it fires at creation too)
    Component.onCompleted: _adopt()

    Shortcut {
        sequence: "Ctrl+V"
        enabled: view.pasteIsOurs
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
        onDroppedOn: (name, urls) => view.addItems(urls, name)
    }

    // Queue, band and history scroll together; the drop zone and the "To"
    // row stay in place. Wheel scroll; a focused row button is brought into
    // view. No animation at rest.
    RevealFlickable {
        id: scroller

        anchors {
            left: parent.left
            right: parent.right
            top: to.bottom
            topMargin: Theme.spacingXL
            bottom: parent.bottom
        }
        contentHeight: list.height
        Column {
            id: list

            // Room for the scroll indicator on the right
            width: scroller.width - 12

            Repeater {
                model: liveRows

                SendJobRow {
                    id: liveRow

                    required property var model

                    width: list.width
                    job: view.rowJob(liveRow.model)
                    rate: view.rates[liveRow.model.jid] ?? ""
                    animate: view.shown
                    onRevealed: item => scroller.reveal(item)
                    onAction: kind => view.act(job, kind)
                }
            }

            Item {
                visible: view.notice !== null
                width: 1
                height: visible ? Theme.spacingS : 0
            }

            GuideBand {
                visible: view.notice !== null
                width: list.width
                error: view.notice !== null && view.notice === view.failure
                actionLabel: error && view.lastFailed !== null ? "Retry" : ""
                message: view.notice ? view.notice.title + ". " + view.notice.advice : ""
                anchor: view.notice ? Flow.anchor(view.notice) : ""
                onActed: view.act(view.lastFailed, "retry")
            }

            Text {
                visible: historyRows.count > 0
                height: visible ? view.headerHeight : 0
                verticalAlignment: Text.AlignVCenter
                text: "History"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
            }

            Repeater {
                model: historyRows

                SendJobRow {
                    id: pastRow

                    required property var model

                    width: list.width
                    history: true
                    now: view.clock
                    onRevealed: item => scroller.reveal(item)
                    job: view.rowJob(pastRow.model)
                    onAction: kind => view.act(job, kind)
                }
            }
        }
    }

    JobList {
        id: liveRows
    }

    JobList {
        id: historyRows
    }

    // One process per sending job, alive only while it sends. The model holds
    // the job id and its command, so a meter line or another job coming and
    // going never recreates a delegate (and never restarts a transfer).
    ListModel {
        id: running
    }

    Repeater {
        model: running

        SendJobProcess {
            id: proc

            required property var model

            argv: JSON.parse(proc.model.argvJson)
            running: true
            onProgressed: (fraction, rate) => {
                // Hidden window: no meter work at all (value 6)
                if (!view.shown)
                    return;
                view.q = Queue.progress(view.q, proc.model.jid, fraction);
                const r = Object.assign({}, view.rates);
                r[proc.model.jid] = rate;
                view.rates = r;
            }
            onEnded: (code, stderr) => view._ended(proc.model.jid, code, stderr)
        }
    }

    Component {
        id: runnerC

        CliRunner {}
    }
}
