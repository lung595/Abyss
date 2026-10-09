import QtQuick
import Quickshell.Io

// Runs commands one after the other. run(cmd, done[, skip]) queues cmd
// and calls done(stdout, stderr, exitCode) once the process has ended and
// both streams are read, whichever comes last. When skip() is true at its
// turn, the command does not run and done gets ("", "", 0).
// cmd is an argv list, never a shell line, or {argv, env, timeout}: env
// adds variables for that process only, which is how a secret is handed
// over (the command line is readable by every local user in ps and /proc,
// the environment only by this user), and timeout replaces the default
// for a command that waits for the user. A command still running after
// its timeout is stopped and ends with exit code -1 (so does a program
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

    function run(cmd, done, skip) {
        const plain = Array.isArray(cmd);
        runner._queue = runner._queue.concat([{
                "argv": plain ? cmd : cmd.argv,
                "env": plain ? null : (cmd.env || null),
                "timeout": plain ? 0 : (cmd.timeout || 0),
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
            runner._proc.environment = job.env || {};
            runner._proc.command = job.argv;
            runner._proc.running = true;
            runner._limit.interval = job.timeout || runner.timeout;
            runner._limit.restart();
        }
        runner._starting = false;
    }

    // Gives up on everything: drops the queue and kills the running program,
    // without calling its callback. The runner is not meant to be used again
    // (a late end of the killed program would be taken for the next one's).
    function stop() {
        runner._queue = [];
        runner._limit.stop();
        runner._cur = null;
        runner._proc.environment = {};
        runner._proc.running = false;
    }

    function _finish() {
        if (!runner._cur || runner._code === null || !runner._outDone || !runner._errDone)
            return;
        runner._limit.stop();
        const job = runner._cur;
        runner._cur = null;
        // Forget a secret handed over in env as soon as it has served
        runner._proc.environment = {};
        job.env = null;
        runner._call(job, outText.text, errText.text, runner._code);
        runner._next();
    }

    function _call(job, out, err, code) {
        try {
            job.done(out, err, code);
        } catch (e) {
            // Only the program name: the arguments may hold a peer name,
            // an address or a user, and the journal is not ours to fill
            console.warn("Abyss: a callback for", job.argv[0], "failed:", e);
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
