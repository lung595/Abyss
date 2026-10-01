import QtQuick
import Quickshell.Io

// Runs commands one after the other. run(argv, done[, skip]) queues argv
// and calls done(stdout, stderr, exitCode) once the process has ended and
// both streams are read, whichever comes last. When skip() is true at its
// turn, the command does not run and done gets ("", "", 0).
// argv is a list, never a shell line. A command still running after
// `timeout` ms is stopped and ends with exit code -1 (so does a program
// that cannot start).
QtObject {
    id: runner

    property int timeout: 15000
    readonly property bool busy: runner._cur !== null

    property var _queue: []
    property var _cur: null
    property var _code: null
    property bool _outDone: false
    property bool _errDone: false

    function run(argv, done, skip) {
        runner._queue = runner._queue.concat([{
                "argv": argv,
                "done": done,
                "skip": skip || null
            }]);
        runner._next();
    }

    // Starts the next job unless one runs. A callback may queue more jobs
    // (run() calls back in here): _starting keeps that from starting a
    // second process over the first, whose output would then go to the
    // wrong callback
    property bool _starting: false
    function _next() {
        if (runner._cur || runner._starting)
            return;
        runner._starting = true;
        while (!runner._cur && runner._queue.length) {
            const job = runner._queue[0];
            runner._queue = runner._queue.slice(1);
            if (job.skip && job.skip()) {
                runner._call(job, "", "", 0);
                continue;
            }
            runner._cur = job;
            runner._code = null;
            runner._outDone = false;
            runner._errDone = false;
            runner._proc.command = job.argv;
            runner._proc.running = true;
            runner._limit.restart();
        }
        runner._starting = false;
    }

    function _finish() {
        if (!runner._cur || runner._code === null || !runner._outDone || !runner._errDone)
            return;
        runner._limit.stop();
        const job = runner._cur;
        runner._cur = null;
        runner._call(job, outText.text, errText.text, runner._code);
        runner._next();
    }

    function _call(job, out, err, code) {
        try {
            job.done(out, err, code);
        } catch (e) {
            console.warn("Abyss:", job.argv.join(" "), e);
        }
    }

    property Process _proc: Process {
        stdout: StdioCollector {
            id: outText
            onStreamFinished: {
                runner._outDone = true;
                runner._finish();
            }
        }
        stderr: StdioCollector {
            id: errText
            onStreamFinished: {
                runner._errDone = true;
                runner._finish();
            }
        }
        onExited: (exitCode, exitStatus) => {
            runner._code = exitCode;
            runner._finish();
        }
    }

    property Timer _limit: Timer {
        interval: runner.timeout
        onTriggered: {
            if (runner._proc.running)
                runner._proc.running = false;
            if (runner._code === null)
                runner._code = -1;
            runner._outDone = true;
            runner._errDone = true;
            runner._finish();
        }
    }
}
