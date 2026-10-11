pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "Services.js" as Services

// Looks for the web services a peer runs, only while asked to: active goes
// true when a card is open on an online peer (and the setting allows it) and
// false the moment it closes. Each well-known port gets its own short probe
// (Services.probePlan), all started together, so the whole scan lasts about
// one second; nothing runs before or after, and closing the card kills the
// probes still waiting. The only traffic is a connection attempt to the
// chosen peer's own ports. Neither the address nor the command is logged.
// services: [{ id, name, url }] once every probe has answered, [] otherwise.
QtObject {
    id: root

    property bool active: false
    property string ip: ""
    readonly property var services: root._services

    property var _services: []
    property var _probes: []
    property var _answers: []
    // Bumped by every start and stop: a late answer of an older scan is ignored
    property int _round: 0

    // The address being scanned, "" while nothing should run: one change here
    // is one restart, even when active and ip change together
    readonly property string _target: root.active ? root.ip : ""
    on_TargetChanged: {
        root._stop();
        if (root._target !== "")
            root._start();
    }

    function _start() {
        const plan = Services.probePlan(root._target);
        if (!plan.ok)
            return;
        const round = root._round;
        root._answers = [];
        root._probes = plan.probes.map(p => probeC.createObject(root, {
                "command": p.argv,
                "probeId": p.id,
                "round": round
            }));
        root._probes.forEach(p => p.running = true);
    }

    function _stop() {
        root._round++;
        root._probes.forEach(p => {
            p.running = false;
            p.destroy();
        });
        root._probes = [];
        root._answers = [];
        root._services = [];
    }

    function _answer(round, id, open) {
        if (round !== root._round)
            return;
        root._answers = root._answers.concat([
            {
                "id": id,
                "open": open
            }
        ]);
        if (root._answers.length < root._probes.length)
            return;
        root._services = Services.servicesFrom(root._target, root._answers);
        // Done: the finished processes are not kept
        root._probes.forEach(p => p.destroy());
        root._probes = [];
    }

    property Component _probe: Component {
        id: probeC
        Process {
            required property string probeId
            required property int round
            // Exit 0 = the port accepted; a timeout or a refusal counts as
            // closed. A program that cannot start never exits: every probe
            // uses the same one, so nothing could be tested and no section
            // shows (the next stop destroys the waiting probes)
            onExited: (code, status) => root._answer(round, probeId, code === 0)
        }
    }
}
