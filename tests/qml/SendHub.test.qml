import QtQuick
import "../../components"

// SendHub through real processes: scp, wl-paste and zenity are the fakes of
// tests/qml (see qmltest.py). The offline and busy refusals, the three modes
// (grab, instant for Reduce motion, notify with no view), Ctrl+V's clipboard
// read, the picker (chosen, cancelled, missing) and the pending guard.
// Run: tests/qml/qmltest.py tests/qml/SendHub.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property var log: []
    property var wait: null
    readonly property string dir: fakeDir
    readonly property var alpha: ({
            "id": "a1",
            "name": "alpha",
            "fqdn": "ok.mesh",
            "online": true
        })
    readonly property var slow: ({
            "id": "s1",
            "name": "slow",
            "fqdn": "slow.mesh",
            "online": true
        })

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }
    function kinds() {
        return test.log.map(e => e.what);
    }
    function last() {
        return test.log[test.log.length - 1];
    }
    // Calls then() once cond() holds (polled: the processes are real)
    function until(cond, then) {
        test.wait = {
            "cond": cond,
            "then": then,
            "left": 160
        };
    }

    SendHubPrefs {
        id: prefs
    }
    SendHub {
        id: hub
        prefs: prefs
        // A program that cannot start only ends at the timeout
        pasteTimeout: 600
        pickTimeout: 600
        onStarted: (peerId, mode, n) => test.log = test.log.concat([
                {
                    "what": "started",
                    "peerId": peerId,
                    "mode": mode,
                    "n": n
                }
            ])
        onEnded: (peerId, ok, text, failure) => test.log = test.log.concat([
                {
                    "what": "ended",
                    "peerId": peerId,
                    "ok": ok,
                    "text": text,
                    "failure": failure
                }
            ])
        onRefused: (peerId, failure) => test.log = test.log.concat([
                {
                    "what": "refused",
                    "peerId": peerId,
                    "failure": failure
                }
            ])
    }
    CliRunner {
        id: sh
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            const w = test.wait;
            if (!w)
                return;
            if (w.cond()) {
                test.wait = null;
                w.then();
            } else if (--w.left <= 0) {
                test.wait = null;
                test.check("timed out waiting; log " + test.kinds().join(","), false);
                test.finish();
            }
        }
    }

    function sh1(script, then) {
        sh.run(["sh", "-c", script, "sh", dir], () => then());
    }
    // Starts the next scenario with an empty log
    function fresh() {
        test.log = [];
    }

    property int stage: 0
    readonly property var stages: [
        // Offline, then the files to send
        () => {
            check("an offline peer is refused with the reason", hub.sendTo({
                "id": "z",
                "name": "lark",
                "online": false
            }, [dir + "/a.txt"]) === "lark is offline");
            check("... and told once", kinds().join() === "refused" && last().failure.kind === "offline", test.log);
            check("a missing peer is refused too", hub.sendTo(null, []) !== "");
            sh1("printf hi > \"$1/a.txt\"", next);
        },
        // No view open: notify
        () => {
            fresh();
            check("a send with no view open starts as 'notify'", hub.sendTo(alpha, [dir + "/a.txt"]) === "");
            check("busy while it runs", hub.busyPeerId === "a1");
            until(() => kinds().indexOf("ended") >= 0, () => {
                check("notify: started then ended ok", kinds().join() === "started,ended" && log[0].mode === "notify" && last().ok === true, test.log);
                check("it names who it went to", last().text === "Sent to alpha", last().text);
                check("busy ends with the send", hub.busyPeerId === "");
                next();
            });
        },
        // A view is open: grab; then Reduce motion: instant
        () => {
            fresh();
            hub.viewing(true);
            check("a view counts", hub.viewers === 1);
            hub.sendTo(alpha, [dir + "/a.txt", dir + "/b.txt"]);
            check("with a view open the file is carried (grab), counting the items", log[0].mode === "grab" && log[0].n === 2, test.log);
            check("a second send meanwhile is refused as busy", hub.sendTo(alpha, [dir + "/a.txt"]) !== "" && last().failure.kind === "busy", last());
            until(() => kinds().indexOf("ended") >= 0, () => {
                fresh();
                prefs.reduceMotion = true;
                hub.sendTo(alpha, [dir + "/a.txt"]);
                check("Reduce motion goes straight to the progress ('instant')", log[0].mode === "instant", test.log);
                until(() => kinds().indexOf("ended") >= 0, () => {
                    prefs.reduceMotion = false;
                    hub.viewing(false);
                    check("a view that leaves is uncounted, never below 0", hub.viewers === 0 && (hub.viewing(false), hub.viewers === 0));
                    next();
                });
            });
        },
        // cancel
        () => {
            fresh();
            hub.sendTo(slow, [dir + "/a.txt"]);
            until(() => test.log.length >= 1, () => {
                hub.cancel();
                check("cancel frees the hub", hub.busyPeerId === "");
                check("... and a new send can start", hub.sendTo(alpha, [dir + "/a.txt"]) === "");
                until(() => kinds().indexOf("ended") >= 0, next);
            });
        },
        // Ctrl+V: the clipboard
        () => {
            fresh();
            check("paste starts at once", hub.paste(alpha) === "");
            until(() => kinds().indexOf("ended") >= 0, () => {
                check("pasted file is sent", kinds().join() === "started,ended" && last().ok, test.log);
                sh1("cat \"$1/scp.argv\" > \"$1/seen\"", () => sh.run(["cat", dir + "/seen"], out => {
                        check("scp got the copied file after --", out.split("\n").slice(-4).join() === "--," + dir + "/a.txt,ok.mesh:Inbox/," || out.indexOf("\n" + dir + "/a.txt\n") > 0, out);
                        next();
                    }));
            });
        }, () => {
            fresh();
            sh1("touch \"$1/paste.empty\"", () => {
                hub.paste(alpha);
                until(() => test.log.length >= 1, () => {
                    check("nothing copied: refused with the advice", log[0].what === "refused" && log[0].failure.title === "No copied file to send" && log[0].failure.advice !== "", test.log);
                    check("... and nothing started", kinds().join() === "refused");
                    sh1("rm \"$1/paste.empty\"; touch \"$1/missing.wl-paste\"", next);
                });
            });
        }, () => {
            fresh();
            hub.paste(alpha);
            until(() => test.log.length >= 1, () => {
                check("wl-paste missing: refused, says what to install", log[0].what === "refused" && log[0].failure.title === "wl-paste could not run", test.log);
                next();
            });
        },
        // Picker
        () => {
            fresh();
            check("pick starts at once", hub.pick(alpha, true) === "");
            check("a second picker is refused while one is open", hub.pick(alpha, false) !== "" && last().failure.kind === "busy", last());
            until(() => kinds().indexOf("ended") >= 0, () => {
                check("picked item is sent", kinds().join() === "refused,started,ended" && last().ok, test.log);
                sh.run(["cat", dir + "/zenity.argv"], out => {
                    check("folder mode asks for a directory", out.split("\n").indexOf("--directory") > 0, out);
                    sh1("touch \"$1/pick.cancel\"", () => {
                        fresh();
                        hub.pick(alpha, false);
                        pause.restart();
                    });
                });
            });
        }, () => {
            check("a cancelled picker says nothing and sends nothing", test.log.length === 0 && hub.busyPeerId === "", test.log);
            check("... and can be opened again", (hub._asking === false));
            sh1("touch \"$1/missing.zenity\"", () => {
                hub.pick(alpha, false);
                until(() => test.log.length >= 1, () => {
                    check("zenity missing: refused, says what to do", log[0].what === "refused" && log[0].failure.kind === "picker", test.log);
                    finish();
                });
            });
        }]
    function next() {
        if (stage < stages.length)
            stages[stage++]();
        else
            finish();
    }
    // Lets a cancelled picker end
    Timer {
        id: pause
        interval: 700
        onTriggered: test.next()
    }
    function finish() {
        console.log((fails ? "✗" : "✓") + " SendHub: " + (count - fails) + "/" + count + " passed");
        Qt.exit(fails ? 1 : 0);
    }
    Component.onCompleted: next()
}
