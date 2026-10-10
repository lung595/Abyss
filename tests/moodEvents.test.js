// MoodEvents.js tests. Run from anywhere: gjs tests/moodEvents.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, eq, done } = imports.load;
const E = load("components/MoodEvents.js");

const dev = (id, online) => ({ "id": id, "online": online });
const kinds = evs => evs.map(e => e.kind);

// The first list only seeds: nothing joined, nothing went down
let st = E.create();
eq("first list is silent", E.devices(st, [dev("a", true), dev("b", false)], 0), []);
eq("unchanged list is silent", E.devices(st, [dev("a", true), dev("b", false)], 10), []);

// Down, join, and a device that comes back online
eq("device down", kinds(E.devices(st, [dev("a", false), dev("b", false)], 20)), ["deviceDown"]);
eq("known device back online is not a join", kinds(E.devices(st, [dev("a", true), dev("b", false)], 30)), []);
eq("new device joins", kinds(E.devices(st, [dev("a", true), dev("c", true)], 40)), ["join"]);
eq("new device already offline is not a join", kinds(E.devices(st, [dev("a", true), dev("c", true), dev("d", false)], 50)), []);

// Bursts: many at once give one event per kind
st = E.create();
const many = on => Array.from({ "length": 40 }, (_, i) => dev("p" + i, on));
E.devices(st, many(true), 0);
eq("40 devices down: one event", kinds(E.devices(st, many(false), 5)), ["deviceDown"]);
st = E.create();
E.devices(st, [dev("a", true)], 0);
const swap = [dev("a", false)].concat(Array.from({ "length": 39 }, (_, i) => dev("n" + i, true)));
eq("down and 39 joins: two events", kinds(E.devices(st, swap, 5)), ["deviceDown", "join"]);

// A flapping device is capped by the gap, then allowed again
st = E.create();
E.devices(st, [dev("a", true)], 0);
eq("flap 1", kinds(E.devices(st, [dev("a", false)], 1)), ["deviceDown"]);
E.devices(st, [dev("a", true)], 1.2);
eq("flap 2 inside the gap", E.devices(st, [dev("a", false)], 1.4), []);
E.devices(st, [dev("a", true)], 4);
eq("flap 3 after the gap", kinds(E.devices(st, [dev("a", false)], 5)), ["deviceDown"]);

// Bad input never throws
st = E.create();
eq("not an array", E.devices(st, null, 0), []);
eq("junk entries", E.devices(st, [null, {}, dev("a", true)], 0), []);

// Relay blinks: a storm gives a few events
st = E.create();
let n = 0;
for (let t = 0; t < 10; t += 0.01)
    if (E.relay(st, t, 10, 20))
        n++;
ok("relay storm is rate limited (" + n + ")", n >= 14 && n <= 17);
eq("relay carries the position", E.relay(E.create(), 0, 10, 20), { "kind": "relay", "x": 10, "y": 20 });

// Sends
st = E.create();
eq("send started is a file", E.send(st, "started", 0, 1, 2).kind, "file");
eq("send succeeded is a success", E.send(st, "succeeded", 1).kind, "success");
eq("send failed startles him", E.send(st, "failed", 2).kind, "deviceDown");
eq("unknown phase ignored", E.send(st, "idle", 3), null);
eq("same phase twice inside the gap", E.send(st, "succeeded", 1.2), null);

// An empty list before the first real one does not count as the seed
st = E.create();
E.devices(st, [], 0);
eq("first real list after an empty one is silent", E.devices(st, [dev("a", true)], 5), []);

// A partial or empty list followed by the full one is not a rejoin
st = E.create();
E.devices(st, [dev("a", true), dev("b", true)], 0);
eq("empty list is silent", E.devices(st, [], 10), []);
eq("refill after empty is silent", E.devices(st, [dev("a", true), dev("b", true)], 20), []);
eq("a device missing from one list does not rejoin", E.devices(st, [dev("a", true)], 30).concat(E.devices(st, [dev("a", true), dev("b", true)], 40)), []);
eq("a missing device is not reported down", E.devices(st, [dev("a", true)], 50), []);
eq("an id like __proto__ is just an id", kinds(E.devices(E.create(), [dev("__proto__", true)], 0)), []);

// A clock stepping back must not freeze the cooldowns
st = E.create();
eq("click at 100", E.click(st, 100).kind, "click");
eq("clock back: gate expired", E.click(st, 50).kind, "click");

// Click
st = E.create();
eq("click", E.click(st, 0, 5, 6).kind, "click");
eq("double click inside the gap", E.click(st, 0.1), null);
eq("rush gated", [E.rush(st, 0, 1, 2).kind, E.rush(st, 0.1)], ["rush", null]);
done("moodEvents");
