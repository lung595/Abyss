// SendQueue.js tests: every transition and the caps.
// Run from anywhere: gjs tests/sendQueue.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const Q = load("app/components/SendQueue.js");

const ids = (s) => s.jobs.map(j => j.id).join();
const st = (s, id) => (s.jobs.concat(s.history).find(j => j.id === id) || {}).state;

let r = Q.add(Q.empty(), ["a", "b"], ["atlas", "kite"]);
eq("files x devices", r.state.jobs.length, 4);
eq("drop order is device then file", r.state.jobs.map(j => j.device + j.path).join(), "atlasa,atlasb,kitea,kiteb");
eq("nothing skipped", r.skipped, 0);
eq("all start queued", r.state.jobs.every(j => j.state === "queued"), true);

let s = r.state;
eq("one per device, devices in parallel", Q.startable(s).join(), "1,3");
s = Q.start(s, 1);
eq("a busy device does not start another", Q.startable(s).join(), "3");
s = Q.start(s, 3);
eq("nothing else while both are busy", Q.startable(s).length, 0);
eq("start on a sending job is a no-op", Q.start(s, 1), s);

s = Q.progress(s, 1, 0.4);
eq("rsync fraction", s.jobs[0].progress, 0.4);
eq("fraction clamps high", Q.progress(s, 1, 7).jobs[0].progress, 1);
eq("fraction clamps low", Q.progress(s, 1, -1).jobs[0].progress, 0);
eq("scp stays indeterminate", Q.progress(s, 1, null).jobs[0].progress, null);
eq("NaN is indeterminate", Q.progress(s, 1, NaN).jobs[0].progress, null);
eq("progress of a queued job is ignored", Q.progress(s, 2, 0.5), s);

s = Q.finish(s, 1);
eq("done stays in the queue until dismissed", st(s, 1), "done");
s = Q.dismiss(s, 1);
eq("dismissed goes to the history", s.history[0].state, "done");
eq("dismissed is no longer in the queue", s.jobs.some(j => j.id === 1), false);
eq("next job of the device can start", Q.startable(s).join(), "2");
eq("finish on a queued job is a no-op", Q.finish(s, 2), s);

s = Q.start(s, 2);
s = Q.fail(s, 2, "Permission denied");
eq("failed", st(s, 2), "failed");
eq("failure reason kept", s.history[0].reason, "Permission denied");
eq("newest first", s.history.map(j => j.id).join(), "2,1");

s = Q.cancel(s, 3);
eq("cancel a sending job", st(s, 3), "cancelled");
s = Q.cancel(s, 4);
eq("cancel a queued job", st(s, 4), "cancelled");
eq("cancel a closed job is a no-op", Q.cancel(s, 1), s);

s = Q.retry(s, 3);
eq("retry puts it back queued", st(s, 3), "queued");
eq("retry leaves the history", s.history.some(j => j.id === 3), false);
eq("retry resets the reason", s.jobs[0].reason, "");
eq("a done job cannot be retried", Q.retry(s, 1), s);
s = Q.start(s, 3);
s = Q.cancelAll(Q.add(s, ["c"], ["atlas"]).state);
eq("cancel all empties the live list", s.jobs.length, 0);
eq("clear history", Q.clearHistory(s).history.length, 0);

// Caps
r = Q.add(Q.empty(), Array.from({ length: 150 }, (_, i) => "f" + i), ["a", "b"]);
eq("live jobs are capped", r.state.jobs.length, 200);
eq("the overflow is counted", r.skipped, 100);
eq("a double drop sends once", Q.add(r.state, ["f0"], ["a"]).skipped, 1);
let h = Q.add(Q.empty(), Array.from({ length: 80 }, (_, i) => "g" + i), ["a"]).state;
for (let i = 1; i <= 80; i++)
    h = Q.fail(Q.start(h, i), i, "x");
eq("history is capped", h.history.length, 50);
eq("history keeps the newest", h.history[0].id, 80);
eq("input state is never mutated", Q.empty().jobs.length, 0);
done();
