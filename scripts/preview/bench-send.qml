import QtQuick
import QtQuick.Window
import "../../app/views"

// CPU bench scene for the Send view, run through the QML test harness
// (real processes: rsync is tests/qml/fake-rsync, four meter lines per job).
// bench-send.sh writes the mode into scripts/preview/mode first.
//   idle:  empty Send view, window shown
//   rsync: four devices always sending, each job re-queued as soon as it ends
//   hidden: the same, with the window hidden (shown = false)
Window {
    id: root

    property string mode: "idle"
    property int sends: 0

    width: 1000
    height: 600
    visible: true

    Component.onCompleted: {
        const x = new XMLHttpRequest();
        x.open("GET", Qt.resolvedUrl("mode"), false);
        x.send();
        root.mode = x.responseText.trim();
        view.shown = root.mode !== "hidden";
        if (root.mode !== "idle")
            refill.start();
    }

    SendView {
        id: view

        anchors.fill: parent
        preferRsync: true
        peers: ["atlas", "reef", "nas", "tab"].map((n, i) => ({
                    "id": String(i),
                    "name": n,
                    "fqdn": n + ".mesh",
                    "ip": "100.64.0." + (i + 1),
                    "online": true
                }))
    }

    // Keeps one job per device alive: when the queue is short, add a file
    Timer {
        id: refill

        interval: 200
        repeat: true
        onTriggered: {
            if (view.q.jobs.length >= 4)
                return;
            view.chosen = [];
            for (const n of view.names)
                view.toggle(n);
            view.addItems(["/tmp/a.txt"]);
            view.q = Object.assign({}, view.q, {
                "history": []
            });
        }
    }
}
