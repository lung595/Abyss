// Slow.js tests. Run from anywhere: gjs tests/slow.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const W = load("components/Slow.js");
const v = (l, t) => W.verdict(l, t);

// Latency levels and their boundaries (defaults 50 and 150 ms)
eq("direct and quick", v({ direct: true, latencyMs: 12 }).level, "good");
eq("just under fair", v({ direct: true, latencyMs: 49.9 }).level, "good");
eq("fair boundary", v({ direct: true, latencyMs: 50 }).level, "fair");
eq("just under slow", v({ direct: true, latencyMs: 149 }).level, "fair");
eq("slow boundary", v({ direct: true, latencyMs: 150 }).level, "slow");
eq("very slow", v({ direct: true, latencyMs: 900 }).level, "slow");

// Throughput (defaults 50 and 10 Mbit/s, lower is worse)
eq("fast transfer", v({ direct: true, latencyMs: 5, mbps: 400 }).level, "good");
eq("just above fair", v({ direct: true, latencyMs: 5, mbps: 50.1 }).level, "good");
eq("fair transfer boundary", v({ direct: true, latencyMs: 5, mbps: 50 }).level, "fair");
eq("slow transfer boundary", v({ direct: true, latencyMs: 5, mbps: 10 }).level, "slow");
eq("worst of the two wins", v({ direct: true, latencyMs: 200, mbps: 900 }).level, "slow");
eq("throughput alone", v({ mbps: 3 }).level, "slow");

// Relay
const r = v({ direct: false, relayReason: "no direct route", latencyMs: 10 });
eq("relay is never good", r.level, "fair");
ok("relay and reason said", r.text.indexOf("relay (no direct route)") > 0);
ok("relay without reason", v({ direct: false, latencyMs: 10 }).text.indexOf("relay.") > 0);
eq("relay and slow stays slow", v({ direct: false, latencyMs: 400 }).level, "slow");
ok("direct is said", v({ direct: true, latencyMs: 10 }).text.indexOf("direct") > 0);
ok("reason flattened", v({ direct: false, relayReason: "a—b\nc–d" }).text.indexOf("(a-b c-d)") > 0);
ok("reason capped", v({ direct: false, relayReason: "x".repeat(500) }).text.length < 200);

// Missing and odd fields
eq("nothing", v({}).level, "unknown");
eq("no argument", v().level, "unknown");
eq("null", v(null).level, "unknown");
eq("direct known, no latency", v({ direct: true }).level, "good");
eq("junk numbers ignored", v({ direct: true, latencyMs: "fast", mbps: -4 }).level, "good");
eq("string number accepted", v({ direct: true, latencyMs: "200" }).level, "slow");

// Thresholds as parameters
eq("custom latency", v({ direct: true, latencyMs: 20 }, { fairLatencyMs: 10, slowLatencyMs: 30 }).level, "fair");
eq("custom throughput", v({ mbps: 80 }, { fairMbps: 100, slowMbps: 90 }).level, "slow");
eq("bad threshold falls back", v({ direct: true, latencyMs: 60 }, { fairLatencyMs: "x" }).level, "fair");

// Sentences
ok("slow sentence", v({ latencyMs: 300 }).text.endsWith("This is slow."));
ok("good sentence", v({ direct: true, latencyMs: 5 }).text.endsWith("This looks healthy."));
ok("numbers shown", v({ direct: true, latencyMs: 12.4, mbps: 94.6 }).text.indexOf("12 ms") > 0 && v({ mbps: 94.6 }).text.indexOf("95 Mbit/s") > 0);
ok("small speed keeps a decimal", v({ mbps: 2.34 }).text.indexOf("2.3 Mbit/s") > 0);
const all = [{}, { direct: false, relayReason: "r—s", latencyMs: 99, mbps: 4 }, { direct: true, latencyMs: 1 }, { mbps: 1 }];
ok("no dash character in any sentence", all.every(l => !/[–—]/.test(v(l).text)));
ok("level is always listed", all.every(l => W.LEVELS.indexOf(v(l).level) >= 0));

done("slow");
