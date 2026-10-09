import QtQuick
import "../../components"

// SendRunner against tests/qml/fake-scp (and the real du), through real
// processes: a send that works, a refused login, a full disk, an item that
// is gone, a bad address, a second send while one runs, and a cancel that
// kills the program. The fake scp saves its arguments in $FAKE_NB/scp.argv.
// Run: tests/qml/qmltest.py tests/qml/Send.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property var events: []
    property int stage: 0
    readonly property string dir: fakeDir
    readonly property var link: ({
            "user": "tom",
            "port": "8022"
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

    SendRunner {
        id: runner
        checkTimeout: 5000
        onFinished: (ok, text, failure) => {
            test.events = test.events.concat([
                {
                    "ok": ok,
                    "text": text,
                    "failure": failure
                }
            ]);
            test.advance();
        }
    }
    CliRunner {
        id: sh
    }

    function last() {
        return events[events.length - 1];
    }

    // Reads the arguments the fake scp saved, then calls back with them
    function argv(then) {
        sh.run(["sh", "-c", "cat \"$1\" 2>/dev/null; true", "sh", dir + "/scp.argv"], out => then(out.split("\n").filter(l => l !== "")));
    }

    function advance() {
        stage++;
        if (stage === 1) {
            check("a send that works ends ok", last().ok, last());
            check("it says what was sent, to whom", last().text === "2 items sent to Vega", last().text);
            check("the runner rests in done, not busy", runner.state === "done" && !runner.busy && runner.progress === 1);
            check("its helper is dropped", runner._run === null);
            argv(a => {
                check("scp got the port, then -- paths target", JSON.stringify(a.slice(-6)) === JSON.stringify(["-P", "8022", "--", dir + "/a.txt", dir + "/dir", "tom@ok.mesh:Inbox/"]), a);
                check("the options are there", a.indexOf("BatchMode=yes") > 0 && a[0] === "-s");
                check("no setup key or password anywhere", !a.some(x => /s3cret/.test(x)));
                runner.send("auth.mesh", test.link, [dir + "/a.txt"], "", "Vega");
            });
        } else if (stage === 2) {
            check("a refused login is a failure", !last().ok && last().failure.kind === "auth", last());
            check("it names the device and links the guide", last().failure.title.indexOf("Vega") === 0 && last().failure.guide.indexOf("#send-a-file") > 0);
            check("scp's own words are not shown", last().text.indexOf("Permission denied (") < 0 && last().failure.advice.indexOf("auth.mesh") < 0);
            check("state is failed", runner.state === "failed" && !runner.busy);
            runner.send("full.mesh", test.link, [dir + "/a.txt"], "", "Vega");
        } else if (stage === 3) {
            check("a full disk is told as such", last().failure.kind === "space", last());
            sh.run(["rm", "-f", dir + "/scp.argv"], () => runner.send("ok.mesh", test.link, [dir + "/a.txt", dir + "/gone"], "", "Vega"));
        } else if (stage === 4) {
            check("a missing item is refused before scp", !last().ok && last().failure.kind === "input", last());
            argv(a => {
                check("scp never ran", a.length === 0, a);
                runner.send("-oProxyCommand=x", test.link, [dir + "/a.txt"], "", "Vega");
            });
        } else if (stage === 5) {
            check("an address that looks like an option is refused", last().failure.kind === "input", last());
            runner.send("ok.mesh", test.link, [dir + "/a.txt"], "a;b", "Vega");
        } else if (stage === 6) {
            check("a folder with a shell character is refused", last().failure.kind === "input", last());
            runner.send("ok.mesh", test.link, [], "", "Vega");
        } else if (stage === 7) {
            check("nothing to send is refused", last().text === "Nothing to send", last());
            // du would skip b.txt as already counted inside dir without -l
            runner.send("ok.mesh", test.link, [dir + "/dir", dir + "/dir/b.txt"], "", "Vega");
        } else if (stage === 8) {
            check("an item inside another item is not taken for missing", last().ok, last());
            test.cancelTest();
        }
    }

    // A send that hangs: a second send is turned away, cancel kills the
    // program, and nothing is reported
    function cancelTest() {
        const before = events.length;
        runner.send("slow.mesh", test.link, [dir + "/a.txt"], "", "Vega");
        check("a send starts checking", runner.state === "checking" && runner.busy);
        waitSending.before = before;
        waitSending.start();
    }

    Timer {
        id: waitSending
        property int before: 0
        property int tries: 0
        interval: 100
        repeat: true
        onTriggered: {
            if (runner.state !== "sending" && ++tries < 30)
                return;
            stop();
            test.check("it reaches sending", runner.state === "sending", runner.state);
            test.check("progress is indeterminate", runner.progress === -1);
            test.check("a second send is turned away", runner.send("ok.mesh", test.link, [test.dir + "/a.txt"], "", "Vega") === false);
            runner.cancel();
            test.check("cancel returns to idle at once", runner.state === "idle" && !runner.busy && runner._run === null);
            test.check("cancel reports nothing", test.events.length === before);
            afterCancel.start();
        }
    }

    Timer {
        id: afterCancel
        interval: 400
        onTriggered: {
            runner.cancel();
            test.check("cancel can be called when idle", runner.state === "idle");
            // kill -0 succeeds while the process lives
            sh.run(["sh", "-c", "kill -0 \"$(cat \"$1\")\" 2>/dev/null", "sh", test.dir + "/slow.pid"], (o, e, code) => {
                test.check("the program was killed", code !== 0, code);
                test.check("still no report from the cancelled send", test.events.length === 8, test.events.length);
                console.log((test.fails ? "✗" : "✓") + " Send: " + (test.count - test.fails) + "/" + test.count + " passed");
                Qt.exit(test.fails ? 1 : 0);
            });
        }
    }

    Component.onCompleted: {
        check("nothing exists before the first send", runner._run === null && runner.state === "idle");
        sh.run(["sh", "-c", "mkdir \"$1/dir\" && printf hi > \"$1/a.txt\" && printf hello > \"$1/dir/b.txt\"", "sh", dir], () => runner.send("ok.mesh", test.link, [dir + "/a.txt", "file://" + dir + "/dir"], "~/Inbox", "Vega"));
    }
}
