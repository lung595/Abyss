import QtQuick
import "GrabMotion.js" as Motion
import "SendFlow.js" as Flow

// What the deep shows of a send, whichever way it was asked for. It reports
// this view to the hub (so a send with no view open comes as a notification
// instead), plays the same GrabFile scene for the drop, the menu, Ctrl+V and
// the launcher, then lets the creature carry the send (its light, the waves
// on its tentacle: AbyssScene reads sendingId), blooms when it went through
// and explains a refusal or a failure with the advice and the guide's link.
// Nothing runs when no send does: the scene's Timers are bound to its state.
Item {
    id: layer

    property var scene
    readonly property var hub: layer.scene.actions && layer.scene.actions.send ? layer.scene.actions.send : null
    readonly property bool watching: !!layer.hub && layer.scene.looking

    // The item (Groups.js id) of the creature a send is going to, once the
    // file has landed on it; "" before, and after
    readonly property string sendingId: layer.hub && layer.hub.busyPeerId !== "" && layer.flying === "" ? layer.scene.itemOfPeer(layer.hub.busyPeerId) : ""
    // The peer the file is being carried to ("" when none)
    property string flying: ""
    // The creature that has just received something, and how bright it is
    property string bloomId: ""
    property real bloomAmount: 0

    // Where the last drop let go, for the file to start from (this view only)
    property var _dropAt: null
    // The outcome that came while the file was still flying
    property var _late: null
    property double _bloomT0: 0

    z: 30

    // --- Starting a send -----------------------------------------------------
    function dropFiles(peer, urls, at) {
        layer._dropAt = at;
        if (layer.hub)
            layer.hub.sendTo(peer, urls.map(u => String(u)));
        layer._dropAt = null;
    }
    function pick(peer, folder) {
        if (layer.hub)
            layer.hub.pick(peer, folder);
    }
    function paste(peer) {
        if (layer.hub)
            layer.hub.paste(peer);
    }

    // --- Following it --------------------------------------------------------
    onWatchingChanged: layer.hub.viewing(layer.watching)
    Component.onCompleted: {
        if (layer.watching)
            layer.hub.viewing(true);
    }
    Component.onDestruction: {
        if (layer.watching)
            layer.hub.viewing(false);
    }

    Connections {
        target: layer.hub
        function onStarted(peerId, mode, count) {
            const it = layer.scene.itemOfPeer(peerId);
            if (!layer.watching || mode !== "grab" || !it) {
                layer._dropAt = null;
                return;
            }
            const to = layer.scene.anchorOfPeer(peerId);
            const from = Motion.startPoint(layer._dropAt, to, {
                "w": layer.scene.width,
                "h": layer.scene.height
            });
            layer._late = null;
            layer.flying = peerId;
            grab.play(from, to, count, layer.scene.tintOf(layer.scene.peerById[peerId].name));
        }
        function onEnded(peerId, ok, text, failure) {
            if (!layer.watching)
                return;
            if (layer.flying !== "")
                layer._late = { "peerId": peerId, "ok": ok, "failure": failure };
            else
                layer._outcome(peerId, ok, failure);
        }
        function onRefused(peerId, failure) {
            if (layer.watching)
                layer._outcome(peerId, false, failure);
        }
    }

    GrabFile {
        id: grab
        scene: layer.scene
        onLanded: {
            layer.flying = "";
            if (layer._late) {
                layer._outcome(layer._late.peerId, layer._late.ok, layer._late.failure);
                layer._late = null;
            }
        }
    }
    // The view closes mid-flight: nothing is left half done
    onWatchingChanged: {
        if (!layer.watching) {
            grab.stop();
            layer.flying = "";
            layer._late = null;
            layer.bloomId = "";
        }
    }

    // --- The outcome -----------------------------------------------------------
    function _outcome(peerId, ok, failure) {
        const at = layer.scene.anchorOfPeer(peerId);
        if (ok) {
            layer.bloomId = layer.scene.itemOfPeer(peerId);
            layer._bloomT0 = Date.now();
            // Reduce motion: a steady glow for the same time, no frames
            layer.bloomAmount = layer.scene.reduceMotion ? 0.8 : 0;
            bloom.restart();
        } else if (failure) {
            layer.scene.explain(failure.title, failure.advice, Flow.anchor(failure), at.x, at.y + 50);
        }
    }

    // The bloom: 30 Hz while it lasts, then gone
    Timer {
        id: bloom
        interval: layer.scene.reduceMotion ? Motion.BLOOM : 33
        repeat: !layer.scene.reduceMotion
        onTriggered: {
            const k = (Date.now() - layer._bloomT0) / Motion.BLOOM;
            layer.bloomAmount = layer.scene.reduceMotion ? 0 : Motion.bloom(k);
            if (k >= 1 || layer.scene.reduceMotion) {
                bloom.stop();
                layer.bloomId = "";
            }
        }
    }
}
