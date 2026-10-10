import QtQuick
import "../../components"

// WakeRunner against tests/qml/fake-wakeonlan and fake-ssh, through real
// processes: a wake from this computer, one through a peer (the real remote
// script runs under the fake ssh), a peer that refuses the login, a peer
// without a wake program, refusals that start nothing, a missing program
// here, and a second wake while one runs. The fakes save their arguments in
// $FAKE_NB/wol.argv and ssh.argv.
// Run: tests/qml/qmltest.py tests/qml/Wake.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property var events: []
    property int stage: 0
    readonly property string dir: fakeDir
    readonly property string lan: "192.168.1.0/24"
    readonly property var target: ({
            "id": "t",
            "mac": "AA-BB-CC-DD-EE-02",
            "lan": lan
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

    function peer(host) {
        return [
            {
                "id": "p",
                "online": true,
                "lan": lan,
                "host": host,
                "name": "Bob",
                "link": {
                    "user": "tom",
                    "port": "8022"
                }
            }
        ];
    }

    WakeRunner {
        id: runner
        commandTimeout: 5000
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

    // Reads a file the fakes saved, then calls back with its lines
    function lines(name, then) {
        sh.run(["sh", "-c", "cat \"$1\" 2>/dev/null; true", "sh", dir + "/" + name], out => then(out.split("\n").filter(l => l !== "")));
    }

    function advance() {
        stage++;
        if (stage === 1) {
            check("a wake from here ends ok", last().ok, last());
            check("it says signal sent, to whom", last().text === "Wake signal sent to Vega", last().text);
            check("the runner rests in done, not busy", runner.state === "done" && !runner.busy && runner._run === null);
            lines("wol.argv", a => {
                check("the program got -- then the normalised MAC", JSON.stringify(a) === JSON.stringify(["--", "aa:bb:cc:dd:ee:02"]), a);
                runner.wake(test.target, "10.0.0.0/24", test.peer("ok.mesh"), "Vega");
            });
        } else if (stage === 2) {
            check("a wake through a peer ends ok", last().ok, last());
            check("it names the peer", last().text === "Wake signal sent to Vega through Bob", last().text);
            lines("ssh.argv", a => {
                check("ssh got the port, then -- user@host", JSON.stringify(a.slice(6, 10)) === JSON.stringify(["-p", "8022", "--", "tom@ok.mesh"]), a);
                check("batch mode: no password prompt", a.indexOf("BatchMode=yes") > 0);
                lines("wol.argv", w => {
                    check("the peer's script ran the program with the MAC", JSON.stringify(w) === JSON.stringify(["--", "aa:bb:cc:dd:ee:02"]), w);
                    sh.run(["rm", "-f", dir + "/wol.argv"], () => runner.wake(test.target, "10.0.0.0/24", test.peer("auth.mesh"), "Vega"));
                });
            });
        } else if (stage === 3) {
            check("a refused login is a failure", !last().ok && last().failure.kind === "peer", last());
            check("it links the guide", last().failure.guide.indexOf("#wake-a-device") > 0);
            check("ssh's own words are not shown", last().text.indexOf("Permission denied") < 0 && last().failure.advice.indexOf("auth.mesh") < 0);
            check("state is failed", runner.state === "failed" && !runner.busy);
            runner.wake(test.target, "10.0.0.0/24", test.peer("nowol.mesh"), "Vega");
        } else if (stage === 4) {
            check("a peer without the program is told so", last().failure.kind === "notool" && last().failure.title.indexOf("Bob") > 0, last());
            sh.run(["rm", "-f", dir + "/ssh.argv", dir + "/wol.argv"], () => runner.wake({
                    "id": "t",
                    "lan": test.lan
                }, test.lan, [], "Vega"));
        } else if (stage === 5) {
            check("no known MAC is explained", last().failure.kind === "nomac" && last().text.indexOf("Vega") > 0, last());
            runner.wake(test.target, "10.0.0.0/24", [], "Vega");
        } else if (stage === 6) {
            check("no online peer is explained", last().failure.kind === "nopeer", last());
            lines("ssh.argv", a => lines("wol.argv", w => {
                    check("nothing was started for the refusals", a.length === 0 && w.length === 0, [a, w]);
                    sh.run(["rm", "-f", dir + "/bin/wakeonlan"], () => runner.wake(test.target, test.lan, [], "Vega"));
                }));
        } else if (stage === 7) {
            check("no program here is told so", last().failure.kind === "notool" && last().failure.title.indexOf("this computer") > 0, last());
            check("nothing is left running", runner._run === null && runner.state === "failed");
            // A second wake while one runs is turned away
            sh.run(["ln", "-s", "/bin/sleep", dir + "/bin/wakeonlan"], () => {
                runner.wake(test.target, test.lan, [], "Vega");
                check("a wake starts checking", runner.state === "checking" && runner.busy);
                check("a second wake is turned away", runner.wake(test.target, test.lan, [], "Vega") === false);
                runner.cancel();
                check("cancel returns to idle at once", runner.state === "idle" && !runner.busy && runner._run === null);
                afterCancel.start();
            });
        }
    }

    Timer {
        id: afterCancel
        interval: 300
        onTriggered: {
            runner.cancel();
            test.check("cancel can be called when idle", runner.state === "idle");
            test.check("cancel reports nothing", test.events.length === 7, test.events.length);
            console.log((test.fails ? "✗" : "✓") + " Wake: " + (test.count - test.fails) + "/" + test.count + " passed");
            Qt.exit(test.fails ? 1 : 0);
        }
    }

    Component.onCompleted: {
        check("nothing exists before the first wake", runner._run === null && runner.state === "idle");
        runner.wake(test.target, test.lan, [], "Vega");
    }
}
