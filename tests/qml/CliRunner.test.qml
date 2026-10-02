import QtQuick
import "../../components"

// CliRunner: order, outputs going to the right callback even when a
// callback queues more commands, skip(), a program that cannot start, and
// a secret handed over in env: it reaches the program, is not on its
// command line, and is gone for the next command.
// Run: tests/qml/qmltest.py tests/qml/CliRunner.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property var got: []

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    CliRunner {
        id: r
        timeout: 1500
    }
    CliRunner {
        id: secret
    }
    property var secretGot: []

    Component.onCompleted: {
        // A callback that queues two more: each output must reach its own
        r.run(["echo", "a"], out => {
            test.got = test.got.concat(["a:" + out.trim()]);
            r.run(["echo", "b"], out2 => test.got = test.got.concat(["b:" + out2.trim()]));
            r.run(["echo", "c"], out3 => test.got = test.got.concat(["c:" + out3.trim()]));
        });
        r.run(["sh", "-c", "echo oops >&2; exit 3"], (out, err, code) => test.got = test.got.concat(["err:" + err.trim() + ":" + code]));
        r.run(["echo", "skipped"], () => test.got = test.got.concat(["skipped"]), () => true);
        r.run(["abyss-no-such-program"], (out, err, code) => test.got = test.got.concat(["missing:" + code]));

        // The shell prints the variable, then its own command line
        secret.run({
            "argv": ["sh", "-c", "printf '%s|' \"$ABYSS_SECRET\"; tr '\\0' ' ' < /proc/$$/cmdline"],
            "env": {
                "ABYSS_SECRET": "s3cret-key"
            }
        }, out => test.secretGot = test.secretGot.concat([out]));
        secret.run(["sh", "-c", "printf '%s' \"${ABYSS_SECRET:-gone}\""], out => test.secretGot = test.secretGot.concat([out]));
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            test.check("every callback got its own output, in order", JSON.stringify(test.got) === JSON.stringify(["a:a", "err:oops:3", "skipped", "missing:-1", "b:b", "c:c"]), test.got);
            test.check("the queue is empty", !r.busy);
            const first = test.secretGot[0] || "";
            test.check("a secret in env reaches the program", first.indexOf("s3cret-key|") === 0, test.secretGot);
            test.check("a secret in env is not on the command line", first.split("|")[1] !== undefined && first.split("|")[1].indexOf("s3cret-key") < 0, test.secretGot);
            test.check("the next command does not inherit it", test.secretGot[1] === "gone", test.secretGot);
            console.log((test.fails ? "✗" : "✓") + " CliRunner: " + (test.count - test.fails) + "/" + test.count + " passed");
            Qt.exit(test.fails ? 1 : 0);
        }
    }
}
