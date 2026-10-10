import QtQuick
import "../../app/views"
import "../../components"
import "../../app/components/SendQueue.js" as Queue

// The Send view against the fake scp and wl-paste, with real processes: two
// devices ticked for one paste, a paste with nothing copied, a refused login
// that is retried, and a cancel that leaves no program behind.
// Run: tests/qml/qmltest.py tests/qml/SendView.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property int stage: 0

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    SendView {
        id: view

        width: 900
        height: 500
        preferRsync: false
        peers: [
            {
                "id": "1",
                "name": "atlas",
                "fqdn": "atlas.mesh",
                "ip": "100.64.0.1",
                "online": true
            },
            {
                "id": "2",
                "name": "reef",
                "fqdn": "auth.mesh",
                "ip": "100.64.0.2",
                "online": true
            },
            {
                "id": "3",
                "name": "slow",
                "fqdn": "slow.mesh",
                "ip": "100.64.0.3",
                "online": true
            },
            {
                "id": "4",
                "name": "asleep",
                "fqdn": "off.mesh",
                "ip": "100.64.0.4",
                "online": false
            }
        ]
    }

    // Waits for cond, then runs next; fails the test after 8 s
    function until(cond, next, what) {
        let n = 0;
        const t = Qt.createQmlObject("import QtQuick; Timer { interval: 50; repeat: true; running: true }", test);
        t.triggered.connect(() => {
            if (cond()) {
                t.destroy();
                next();
            } else if (++n > 160) {
                t.destroy();
                check(what, false);
                Qt.exit(1);
            }
        });
    }

    Component.onCompleted: {
        check("only online devices are offered", view.names.join() === "atlas,reef,slow");
        // Nothing ticked: the files wait, the device choice is what the user sees
        view.addItems([fakeDir + "/a.txt"]);
        check("a drop with no device waits for one", view.q.jobs.length === 0 && view.pending.length === 1);
        view.toggle("atlas");
        check("ticking the device sends the waiting files", view.q.jobs.length === 1 && view.pending.length === 0);
        view.q = Queue.clearHistory(Queue.cancelAll(view.q));
        view.toggle("reef");
        view.addItems([fakeDir + "/a.txt"]);
        check("two devices ticked give two jobs", view.q.jobs.length === 2 && view.pending.length === 0, view.q);
        until(() => view.q.history.length === 2, afterFirst, "two jobs end");
    }

    function afterFirst() {
        const done = view.q.history.filter(j => j.state === "done").map(j => j.device);
        const failed = view.q.history.filter(j => j.state === "failed").map(j => j.device);
        check("atlas arrived", done.join() === "atlas", view.q.history);
        check("reef was refused", failed.join() === "reef");
        check("the refusal is a guided message", view.failure !== null && view.failure.guide.indexOf("send-a-file") > 0, view.failure);
        const reef = view.q.history.find(j => j.state === "failed");
        view.act(reef, "retry");
        check("retry queues it again", view.q.jobs.length === 1 || view.q.history.length >= 1);
        until(() => view.q.jobs.length === 0, afterRetry, "retry ends");
    }

    function afterRetry() {
        check("the retry ends in the history", view.q.history.filter(j => j.device === "reef").length === 1);
        // Paste: the fake wl-paste offers a.txt; one device ticked is enough
        view.toggle("reef");
        view.q = Object.assign({}, view.q, {
            "history": []
        });
        view.failure = null;
        view.paste();
        until(() => view.q.history.length === 1, afterPaste, "a paste is sent");
    }

    function afterPaste() {
        check("paste sends the copied file", view.q.history[0].device === "atlas" && view.q.history[0].state === "done", view.q.history);
        view.q = Object.assign({}, view.q, {
            "history": []
        });
        // The fake wl-paste ends with 1 when this marker exists
        sh.run(["touch", fakeDir + "/paste.empty"], () => {
            view.paste();
            until(() => view.failure !== null, afterEmpty, "empty paste is explained");
        });
    }

    function afterEmpty() {
        check("an empty clipboard is a guided message", view.failure.kind === "paste" && view.q.jobs.length === 0, view.failure);
        view.failure = null;
        view.toggle("atlas");
        view.toggle("slow");
        view.addItems([fakeDir + "/a.txt"]);
        until(() => view.q.jobs.length === 1 && view.q.jobs[0].state === "sending" && view.runningCount === 1, cancelIt, "slow job sends");
    }

    function cancelIt() {
        view.act(view.q.jobs[0], "cancel");
        check("cancel moves it to the history", view.q.jobs.length === 0 && view.q.history[0].state === "cancelled");
        until(() => true, () => {
            sh.run(["sh", "-c", "pid=$(cat \"$1/slow.pid\"); sleep 0.5; kill -0 $pid 2>/dev/null && echo alive || echo gone", "sh", fakeDir], out => {
                check("the cancelled program is gone", out.trim() === "gone", out);
                Qt.exit(test.fails);
            });
        }, "");
    }

    CliRunner {
        id: sh
    }
}
