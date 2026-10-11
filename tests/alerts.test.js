// Alerts.js tests. Run from anywhere: gjs tests/alerts.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const A = load("components/Alerts.js");

const peer = (id, connected, favourite = true) => ({ id, connected, favourite });
const snap = (now, ...peers) => ({ now, peers });
const run = (steps, opts) => {
    let state = {}, all = [];
    steps.forEach(s => {
        const r = A.step(state, s, opts);
        state = r.state;
        all.push(r.events);
    });
    return { state, all };
};
const S = 1000;

// The debounce edges (30 s by default)
eq("up, then just under 30 s down: nothing", run([snap(0, peer("a", false)), snap(29999, peer("a", false))]).all, [[], []]);
eq("exactly 30 s down: down", run([snap(0, peer("a", false)), snap(30 * S, peer("a", false))]).all[1],
    [{ "kind": "down", "id": "a", "since": 0, "duration": 0 }]);
eq("just over 30 s down: down", run([snap(0, peer("a", false)), snap(30001, peer("a", false))]).all[1].length, 1);
eq("down is told once", run([snap(0, peer("a", false)), snap(31 * S, peer("a", false)), snap(60 * S, peer("a", false))]).all.map(e => e.length), [0, 1, 0]);

// Back, with the duration
eq("back after a told outage", run([snap(0, peer("a", false)), snap(40 * S, peer("a", false)), snap(100 * S, peer("a", true))]).all[2],
    [{ "kind": "back", "id": "a", "since": 0, "duration": 100 * S }]);
eq("a drop shorter than the debounce raises nothing", run([snap(0, peer("a", false)), snap(10 * S, peer("a", true))]).all, [[], []]);
eq("a short drop leaves nothing behind", run([snap(0, peer("a", false)), snap(10 * S, peer("a", true))]).state, {});
eq("a second outage restarts the clock", run([snap(0, peer("a", false)), snap(5 * S, peer("a", true)), snap(10 * S, peer("a", false)), snap(39 * S, peer("a", false))]).all.map(e => e.length), [0, 0, 0, 0]);
eq("down, back, down again", run([snap(0, peer("a", false)), snap(30 * S, peer("a", false)), snap(40 * S, peer("a", true)), snap(50 * S, peer("a", false)), snap(80 * S, peer("a", false))]).all.map(e => e.length), [0, 1, 1, 0, 1]);
eq("a connected favourite raises nothing", run([snap(0, peer("a", true)), snap(99 * S, peer("a", true))]).all, [[], []]);

// Favourites only
eq("not a favourite: never", run([snap(0, peer("a", false, false)), snap(99 * S, peer("a", false, false))]).all, [[], []]);
eq("stops being a favourite while down: nothing", run([snap(0, peer("a", false)), snap(20 * S, peer("a", false, false)), snap(99 * S, peer("a", false, false))]).all, [[], [], []]);
eq("stops being a favourite after a told outage: no back", run([snap(0, peer("a", false)), snap(31 * S, peer("a", false)), snap(40 * S, peer("a", true, false))]).all[2], []);
eq("only the favourite is tracked", Object.keys(run([snap(0, peer("a", false), peer("b", false, false))]).state), ["a"]);
eq("two favourites are independent", run([snap(0, peer("a", false), peer("b", false)), snap(20 * S, peer("a", false), peer("b", true)), snap(31 * S, peer("a", false), peer("b", true))]).all.map(e => e.map(x => x.id)), [[], [], ["a"]]);

// Switching off
eq("alerts off: no event", run([snap(0, peer("a", false)), snap(99 * S, peer("a", false))], { "enabled": false }).all, [[], []]);
eq("alerts off: state forgotten", A.step({ "a": { "since": 0, "notified": true } }, snap(5, peer("a", true)), { "enabled": false }), { "state": {}, "events": [] });
eq("alerts off then on: no old outage told", A.step(A.step({}, snap(0, peer("a", false)), { "enabled": false }).state, snap(99 * S, peer("a", false))).events, []);

// The debounce is a parameter
eq("custom debounce 5 s", run([snap(0, peer("a", false)), snap(5 * S, peer("a", false))], { "debounceMs": 5 * S }).all[1].length, 1);
eq("custom debounce 0: told at once", run([snap(0, peer("a", false))], { "debounceMs": 0 }).all[0].length, 1);
eq("bad debounce falls back to 30 s", run([snap(0, peer("a", false)), snap(29 * S, peer("a", false))], { "debounceMs": "x" }).all[1], []);
eq("negative debounce falls back to 30 s", run([snap(0, peer("a", false)), snap(29 * S, peer("a", false))], { "debounceMs": -1 }).all[1], []);

// Unknown, missing and empty
eq("empty list", A.step({}, snap(0), {}), { "state": {}, "events": [] });
eq("empty list forgets a pending drop", A.step({ "a": { "since": 0, "notified": false } }, snap(5)).state, {});
eq("no snapshot keeps the state", A.step({ "a": { "since": 0, "notified": true } }, undefined).state, { "a": { "since": 0, "notified": true } });
eq("no peers array keeps the state", A.step({ "a": { "since": 0, "notified": true } }, { "now": 5 }).events, []);
eq("no time keeps the state", A.step({}, { "peers": [peer("a", false)] }).state, {});
eq("undefined state", A.step(undefined, snap(0, peer("a", false))).state, { "a": { "since": 0, "notified": false } });
eq("unknown link state: no tracking", A.step({}, snap(0, { "id": "a", "favourite": true })).state, {});
eq("missing id and null entries are skipped", A.step({}, snap(0, { "favourite": true, "connected": false }, null, peer("", false))).state, {});
eq("favourite flag must be exactly true", A.step({}, snap(0, { "id": "a", "favourite": "yes", "connected": false })).state, {});
eq("time going backwards never gives a negative duration", run([snap(100 * S, peer("a", false)), snap(131 * S, peer("a", false)), snap(50 * S, peer("a", true))]).all[2][0].duration, 0);
eq("the input state is not changed", (() => { const s = { "a": { "since": 0, "notified": false } }; A.step(s, snap(40 * S, peer("a", false))); return s; })(), { "a": { "since": 0, "notified": false } });

// Duration formatting
eq("seconds", [A.formatDuration(0), A.formatDuration(999), A.formatDuration(45 * S), A.formatDuration(59999)], ["0 s", "0 s", "45 s", "59 s"]);
eq("minutes", [A.formatDuration(60 * S), A.formatDuration(179 * S), A.formatDuration(59 * 60 * S)], ["1 min", "2 min", "59 min"]);
eq("hours", [A.formatDuration(3600 * S), A.formatDuration(3900 * S), A.formatDuration(23 * 3600 * S)], ["1 h", "1 h 5 min", "23 h"]);
eq("days", [A.formatDuration(86400 * S), A.formatDuration(100800 * S), A.formatDuration(3 * 86400 * S)], ["1 d", "1 d 4 h", "3 d"]);
eq("unusable durations", [A.formatDuration(undefined), A.formatDuration(null), A.formatDuration(-5), A.formatDuration("x"), A.formatDuration(NaN)], ["0 s", "0 s", "0 s", "0 s", "0 s"]);

// The sentences
eq("down sentence", A.message({ "kind": "down" }, "Harbor"), "Harbor is offline.");
eq("back sentence", A.message({ "kind": "back", "duration": 125 * S }, "Harbor"), "Harbor is back after 2 min.");
eq("no name", A.message({ "kind": "down" }, ""), "A favourite is offline.");
eq("no event, unknown kind", [A.message(null, "x"), A.message({ "kind": "?" }, "x")], ["", ""]);
ok("no dash in a sentence", !/[–—]/.test(A.message({ "kind": "back", "duration": 1 }, "x") + A.message({ "kind": "down" })));

done("alerts");
