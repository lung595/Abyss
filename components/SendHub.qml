import QtQuick
import "Send.js" as Send
import "SendFlow.js" as Flow

// Every way of sending ends here: the menu's file picker, Ctrl+V on a card,
// the launcher and `dms ipc call abyss send`. It checks the peer, takes the
// items (from the picker, the clipboard or a path), starts the SendRunner and
// says what happens in three signals, so each open view plays the same
// scene (started), shows the outcome (ended) or explains a refusal (refused).
// The daemon turns them into a notification when no view is open.
// Nothing exists before the first send: the runner, the clipboard reader
// and the picker are each made when needed and dropped when done.
QtObject {
    id: hub

    property var prefs: null
    // How long the clipboard read and a person's choice in the picker may
    // take (a person: as long as they need)
    property int pasteTimeout: 10000
    property int pickTimeout: 10 * 60 * 1000
    // How many views of Abyss are being looked at (each scene reports itself)
    property int viewers: 0
    // The peer a send is going to ("" when none)
    readonly property string busyPeerId: hub._peerId

    // mode: "grab" (play the file being carried), "instant" (Reduce motion) or
    // "notify" (no view is open)
    signal started(string peerId, string mode, int count)
    signal ended(string peerId, bool ok, string text, var failure)
    signal refused(string peerId, var failure)

    property string _peerId: ""
    // The clipboard reader or the picker is open: a second one would ask twice
    property bool _asking: false
    property var _sender: null

    function viewing(on) {
        hub.viewers = Math.max(0, hub.viewers + (on ? 1 : -1));
    }

    // Sends the items to the peer. "" when it is on its way, otherwise the
    // sentence that says why not (also given to refused())
    function sendTo(peer, items) {
        const no = hub._check(peer);
        if (no)
            return no;
        const count = Array.isArray(items) ? items.length : 1;
        hub._peerId = peer.id;
        if (!hub._sender) {
            hub._sender = senderC.createObject(hub);
            hub._sender.finished.connect(hub._onFinished);
        }
        const mode = Flow.mode(hub.viewers > 0, hub.prefs.reduceMotion);
        hub._sender.send(peer.fqdn || peer.ip, hub.prefs.linkOf(peer.id), items, hub.prefs.sendFolder, peer.name);
        // A send refused before it started has already ended (ended())
        if (hub._sender.busy)
            hub.started(peer.id, mode, count);
        return "";
    }

    // The items are the files copied in the file manager (Ctrl+V on a card)
    function paste(peer) {
        const no = hub._check(peer);
        if (no)
            return no;
        hub._ask(Flow.pasteCommand(), hub.pasteTimeout, (out, code) => {
            const fail = Flow.pasteFailure(code, out);
            if (fail)
                hub.refused(peer.id, fail);
            else
                hub.sendTo(peer, Flow.pastedItems(out));
        });
        return "";
    }

    // The items are chosen in a file picker (folder: pick a folder instead)
    function pick(peer, folder) {
        const no = hub._check(peer);
        if (no)
            return no;
        hub._ask(Flow.pickCommand(peer.name, folder), hub.pickTimeout, (out, code) => {
            const fail = Flow.pickFailure(code);
            if (fail)
                hub.refused(peer.id, fail);
            else if (code === 0)
                hub.sendTo(peer, Flow.pastedItems(out));
        });
        return "";
    }

    // Stops a send under way, quietly
    function cancel() {
        if (hub._sender)
            hub._sender.cancel();
        hub._peerId = "";
    }

    // "" when the peer can be sent to now, otherwise why not (and refused())
    function _check(peer) {
        const fail = !peer ? Flow.offlineFailure("") : !peer.online ? Flow.offlineFailure(peer.name) : hub._peerId !== "" || hub._asking ? Flow.busyFailure() : null;
        if (!fail)
            return "";
        hub.refused(peer ? peer.id : "", fail);
        return fail.title;
    }

    // Runs one program to its end and hands back its output and exit code
    function _ask(argv, timeout, done) {
        hub._asking = true;
        const run = runnerC.createObject(hub, {
            "timeout": timeout
        });
        run.run(argv, (out, err, code) => {
            run.destroy();
            hub._asking = false;
            done(out, code);
        });
    }

    function _onFinished(ok, text, failure) {
        const id = hub._peerId;
        hub._peerId = "";
        hub.ended(id, ok, text, failure);
    }

    property Component _senderC: Component {
        id: senderC
        SendRunner {}
    }
    property Component _runnerC: Component {
        id: runnerC
        CliRunner {}
    }
}
