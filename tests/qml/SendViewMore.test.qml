import QtQuick
import QtQuick.Window
import "../../app/views"
import "../../components"

// What SendView.test.qml leaves out, with real processes: a folder paste, a
// missing wl-paste, Ctrl+V left to a text field, rsync with its meter (a
// meter line or a second drop must not restart a running transfer), files of
// the command line, and the close during a transfer.
// Run: tests/qml/qmltest.py tests/qml/SendViewMore.test.qml
Item {
    id: test

    property int fails: 0

    readonly property var mesh: [
        {
            "id": "1",
            "name": "atlas",
            "fqdn": "atlas.mesh",
            "ip": "100.64.0.1",
            "online": true
        },
        {
            "id": "2",
            "name": "kite",
            "fqdn": "kite.mesh",
            "ip": "100.64.0.2",
            "online": true
        },
        {
            "id": "3",
            "name": "slow",
            "fqdn": "slow.mesh",
            "ip": "100.64.0.3",
            "online": true
        }
    ]

    function check(name, cond, detail) {
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    function until(cond, next, what) {
        let n = 0;
        const t = Qt.createQmlObject("import QtQuick; Timer { interval: 50; repeat: true; running: true }", test);
        t.triggered.connect(() => {
            if (cond()) {
                t.destroy();
                next();
            } else if (++n > 200) {
                t.destroy();
                check(what, false);
                Qt.exit(1);
            }
        });
    }

    function launches(next) {
        sh.run(["sh", "-c", "wc -l < \"$1/rsync.launches\"", "sh", fakeDir], out => next(Number(out.trim())));
    }

    // A real window, so that a text field can hold the focus
    Window {
        visible: true
        width: 900
        height: 500

        SendView {
            id: view

            anchors.fill: parent
            peers: test.mesh

            TextInput {
                id: field
            }
        }
    }

    CliRunner {
        id: sh
    }

    Component.onCompleted: folderPaste()

    function folderPaste() {
        view.toggle("atlas");
        sh.run(["touch", fakeDir + "/paste.dir", fakeDir + "/missing.rsync"], () => {
            view.paste();
            until(() => view.q.jobs.length + view.q.history.length > 0, () => {
                const job = view.q.jobs.concat(view.q.history)[0];
                check("a pasted folder becomes a job", job.path === fakeDir + "/folder", job);
                view.cancelAll();
                // A drop on one device's chip sends to that device alone
                view.addItems([fakeDir + "/a.txt"], "kite");
                check("a drop on a device goes to it alone", view.q.jobs.length === 1 && view.q.jobs[0].device === "kite" && view.chosen.join() === "atlas", view.q.jobs);
                view.cancelAll();
                missingPaste();
            }, "folder pasted");
        });
    }

    function missingPaste() {
        sh.run(["touch", fakeDir + "/missing.wl-paste"], () => {
            view.failure = null;
            view.paste();
            until(() => view.failure !== null, () => {
                check("a missing wl-paste is a guided message", view.failure.kind === "paste" && view.failure.guide.indexOf("#") > 0, view.failure);
                sh.run(["rm", fakeDir + "/missing.wl-paste", fakeDir + "/missing.rsync", fakeDir + "/paste.dir"], textField);
            }, "missing wl-paste explained");
        });
    }

    function textField() {
        field.forceActiveFocus();
        check("a text field keeps its own Ctrl+V", !view.pasteIsOurs, view.pasteIsOurs);
        field.focus = false;
        rsyncTwo();
    }

    function rsyncTwo() {
        view.cancelAll();
        view.toggle("kite");
        view.addItems([fakeDir + "/a.txt"]);
        until(() => view.q.jobs.some(j => j.progress !== null && j.progress > 0), () => {
            launches(n => {
                check("two devices run rsync once each", n === 2 && view.runningCount === 2, n);
                view.addItems([fakeDir + "/b.txt"]);
                until(() => view.q.history.length >= 4 && view.q.jobs.length === 0, () => launches(m => {
                        check("a meter line or a second drop restarts nothing", m === 4, m);
                        commandLine();
                    }), "queue empties");
            });
        }, "rsync meter moves");
    }

    function commandLine() {
        frame.go({
            "ok": true,
            "view": "send",
            "device": "slow",
            "files": [fakeDir + "/a.txt"],
            "category": ""
        });
        until(() => frame.sendView && frame.sendView.runningCount === 1, closeIt, "command-line file sends");
    }

    function closeIt() {
        check("abyss send <device> <file> queues the file", frame.sendView.q.jobs.length === 1 && frame.sendView.chosen.join() === "slow");
        check("no false duplicate notice", frame.sendView.failure === null);
        frame.show("map");
        check("closing from another station brings Send back", frame.confirmClose() === false && frame.station === "send");
        check("the first close only asks", frame.closeAsked);
        check("the view says so", frame.sendView.notice.title.indexOf("still running") > 0);
        check("the second close lets go", frame.confirmClose() === true);
        sh.run(["sh", "-c", "pid=$(cat \"$1/slow.pid\"); sleep 0.5; kill -0 $pid 2>/dev/null && echo alive || echo gone", "sh", fakeDir], out => {
            check("closing leaves no program behind", out.trim() === "gone" && frame.sendView.runningCount === 0, out);
            Qt.exit(test.fails);
        });
    }

    AppFrame {
        id: frame

        width: 900
        height: 600
        peers: test.mesh
        visible: true
    }
}
