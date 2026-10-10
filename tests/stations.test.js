// Stations.js tests: routing of command lines, readouts, signal, transition.
// Run from anywhere: gjs tests/stations.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const S = load("app/components/Stations.js");
const Cli = load("app/components/Cli.js");

const go = (words) => S.landing(Cli.parse(words, "/tmp"));

eq("three stations, top to bottom", S.STATIONS.map(s => s.id).join(), "settings,send,map");
eq("depths 0 / 200 / 4000", S.STATIONS.map(s => s.depth).join(), "0,200,4000");
eq("home is the map", go([]).station, "map");
eq("abyss map", go(["map"]).station, "map");
eq("abyss settings", go(["settings"]).station, "settings");
eq("abyss settings category", go(["settings", "send"]).category, "send");
eq("abyss send device", go(["send", "atlas"]).station + "/" + go(["send", "atlas"]).device, "send/atlas");
eq("abyss peer opens the map", go(["peer", "atlas"]).station, "map");
eq("abyss peer keeps the device", go(["peer", "atlas"]).device, "atlas");
eq("a refused line lands on the map", S.landing({ "ok": false }).station, "map");

const peers = [{ "name": "Atlas-Server" }, { "name": "kite" }];
eq("findPeer ignores case", S.findPeer(peers, "atlas-server").name, "Atlas-Server");
eq("unknown peer is null", S.findPeer(peers, "ghost"), null);
eq("no peers is null", S.findPeer(undefined, "x"), null);

eq("fraction clamps low", S.fraction(-5), 0);
eq("fraction clamps high", S.fraction(9000), 1);
eq("fraction mid", S.fraction(2000), 0.5);

eq("readouts at 4000 m", JSON.stringify(S.readouts(4000)),
    JSON.stringify({ "depth": "4000 m", "pressure": "401 bar", "temperature": "2 °C" }));
eq("temperature 18 / 6 / 2 at the stations", [0, 200, 4000].map(d => S.readouts(d).temperature).join(), "18 °C,6 °C,2 °C");
eq("readouts at the surface", S.readouts(0).pressure, "1 bar");

eq("depth label groups thousands", S.depthLabel(4000), "4\u202F000 m");
eq("depth label small", S.depthLabel(200), "200 m");

eq("descend 200 ms", S.transitionMs("settings", "map", false), 200);
eq("ascend 150 ms", S.transitionMs("map", "send", false), 150);
eq("same station 0", S.transitionMs("map", "map", false), 0);
eq("reduce motion 0", S.transitionMs("settings", "map", true), 0);

eq("connected is success", S.signal("connected").role, "success");
eq("stopped is warning", S.signal("stopped").role, "warning");
eq("missing is error", S.signal("missing").role, "error");
ok("every state has a glyph", ["connected", "stopped", "missing", "x"].every(s => S.signal(s).glyph.length > 0));
ok("signal labels fit 8 mono chars with the glyph", ["connected", "stopped", "missing", "x"].every(s => S.signal(s).label.length <= 6));
eq("short name kept", S.shortName("atlas"), "atlas");
const long = "workstation-with-a-very-long-name.netbird.cloud";
ok("long name capped, ends kept", S.shortName(long).length === 32 && S.shortName(long).includes("…") && S.shortName(long).endsWith("cloud"));
done("stations");
