// Health.js tests. Run from anywhere: gjs tests/health.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const H = load("components/Health.js");

const link = (latencyMs, connected = true) => ({ connected, latencyMs });
const st = input => H.evaluate(input).state;

// Nothing wrong, and nothing known
eq("healthy mesh", st({ "relays": { "up": 2, "total": 2 }, "peers": [link(20)], "exit": { "active": true, "up": true } }), "ok");
eq("ok has a reason", H.evaluate({}).reason, "Everything is connected.");
eq("no input at all", [H.evaluate().state, H.evaluate(null).state, H.evaluate({}).state], ["ok", "ok", "ok"]);
eq("empty peer list", st({ "peers": [] }), "ok");
eq("peers is not a list", st({ "peers": "x" }), "ok");
eq("no exit chosen", st({ "exit": { "active": false, "up": false } }), "ok");

// Relays
eq("all relays down", H.evaluate({ "relays": { "up": 0, "total": 3 } }), { "state": "bad", "reason": "No relay server is reachable." });
eq("some relays down", H.evaluate({ "relays": { "up": 1, "total": 3 } }), { "state": "warn", "reason": "Some relay servers are unreachable." });
eq("all relays up", st({ "relays": { "up": 3, "total": 3 } }), "ok");
eq("unknown relay counts", [st({ "relays": {} }), st({ "relays": { "up": "x", "total": 2 } }), st({ "relays": { "up": -1, "total": 2 } }), st({ "relays": { "up": 0, "total": 0 } })], ["ok", "ok", "ok", "ok"]);

// Internet exit
eq("exit down", H.evaluate({ "exit": { "active": true, "up": false } }), { "state": "bad", "reason": "The Internet exit is down." });
eq("exit state unknown", st({ "exit": { "active": true } }), "ok");

// Latency, with the edges
eq("just under the warn threshold", st({ "peers": [link(149)] }), "ok");
eq("exactly the warn threshold", st({ "peers": [link(150)] }), "warn");
eq("just under the bad threshold", st({ "peers": [link(499)] }), "warn");
eq("exactly the bad threshold", st({ "peers": [link(500)] }), "bad");
eq("latency reason carries the worst value", H.evaluate({ "peers": [link(200), link(620.4), link(40)] }), { "state": "bad", "reason": "A device answers very slowly (620 ms)." });
eq("warn reason", H.evaluate({ "peers": [link(200)] }).reason, "A device answers slowly (200 ms).");
eq("offline devices are ignored", st({ "peers": [link(9000, false)] }), "ok");
eq("unknown latency is ignored", st({ "peers": [{ "connected": true }, { "connected": true, "latencyMs": null }, { "connected": true, "latencyMs": NaN }, { "connected": true, "latencyMs": "900" }, null] }), "ok");
eq("custom thresholds", [H.evaluate({ "peers": [link(60)] }, { "warnMs": 50, "badMs": 100 }).state, H.evaluate({ "peers": [link(100)] }, { "warnMs": 50, "badMs": 100 }).state], ["warn", "bad"]);
eq("bad thresholds fall back", st({ "peers": [link(150)] }, { "warnMs": "x" }) , "warn");

// The worst wins, and its reason
eq("bad beats warn", H.evaluate({ "relays": { "up": 1, "total": 2 }, "exit": { "active": true, "up": false } }).reason, "The Internet exit is down.");
eq("warn relay + warn latency: relay first", H.evaluate({ "relays": { "up": 1, "total": 2 }, "peers": [link(200)] }).reason, "Some relay servers are unreachable.");
eq("everything bad: relay first", H.evaluate({ "relays": { "up": 0, "total": 2 }, "exit": { "active": true, "up": false }, "peers": [link(900)] }).reason, "No relay server is reachable.");
eq("bad latency beats warn relay", H.evaluate({ "relays": { "up": 1, "total": 2 }, "peers": [link(900)] }).state, "bad");

// Every sentence is plain: short, English, no dash
const all = [{}, { "relays": { "up": 0, "total": 1 } }, { "relays": { "up": 1, "total": 2 } }, { "exit": { "active": true, "up": false } }, { "peers": [link(200)] }, { "peers": [link(900)] }].map(i => H.evaluate(i).reason);
ok("no em or en dash", all.every(r => !/[–—]/.test(r)));
ok("short sentences", all.every(r => r.length <= 50 && /\.$/.test(r)));

done("health");
