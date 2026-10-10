// Store.js tests (the settings file shared by the widget and the app).
// Run from anywhere: gjs tests/settingsStore.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const S = load("components/settings/Store.js");

const d = S.defaults();
eq("defaults cover every key", Object.keys(d), S.KEYS);
ok("defaults are fresh copies", S.defaults().groups !== d.groups);
eq("empty text parses to defaults", S.parse(""), d);
eq("corrupted file gives defaults", S.parse("{\"settings\": {"), d);
eq("not an object gives defaults", S.parse("[1,2]"), d);
eq("non-string gives defaults", S.parse(undefined), d);
eq("oversize file gives defaults", S.parse(" ".repeat(300000)), d);

// Round trip, with every key changed from its default
const custom = Object.assign(S.defaults(), {
    "source": "netbird", "showOffline": false, "terminal": "kitty", "maxItems": 8, "pill": "rate",
    "groupOpen": "click", "muted": { "a": "Atlas" }, "favorites": { "b": "Boreal" },
    "links": { "a": { "user": "me", "port": "2222" } },
    "groups": [{ "id": "u1", "name": "Home", "members": ["a", "b"] }],
    "exitTies": { "a": "Boreal" }, "exitGroup": "u1", "labMesh": "crowd", "labPeers": 80,
    "labLatency": 200, "labTrouble": "relay", "labTraffic": "rush", "labLazy": true
});
eq("round trip", S.parse(S.serialize(custom)), custom);
eq("serialize is stable", S.serialize(custom), S.serialize(S.parse(S.serialize(custom))));
eq("key order follows the schema", Object.keys(JSON.parse(S.serialize(custom)).settings), S.KEYS);

// Validation
const bad = k => S.parse(JSON.stringify({ "settings": k }));
eq("unknown keys dropped", Object.keys(bad({ "evil": 1, "__proto__": {}, "maxItems": 4 })), S.KEYS);
eq("out-of-range capped high", bad({ "maxItems": 999 }).maxItems, 10);
eq("out-of-range capped low", bad({ "labPeers": -5 }).labPeers, 1);
eq("numeric text accepted", bad({ "labLatency": "120" }).labLatency, 120);
eq("wrong type falls back", bad({ "pulses": "yes" }).pulses, true);
eq("unknown enum falls back", bad({ "pill": "huge" }).pill, "peers");
eq("control chars refused", bad({ "terminal": "a\nb" }).terminal, "auto");
eq("long text refused", bad({ "terminal": "x".repeat(300) }).terminal, "auto");
eq("bad group dropped, good kept", bad({ "groups": [{ "id": 1 }, { "id": "g", "name": "G", "members": ["a", 3] }] }).groups,
    [{ "id": "g", "name": "G", "members": ["a"] }]);
eq("names map keeps strings only", bad({ "muted": { "a": "A", "b": 3 } }).muted, { "a": "A" });
eq("link with a non-text user dropped", bad({ "links": { "a": { "user": 5 }, "b": { "user": "u", "port": 22 } } }).links, { "b": { "user": "u", "port": "22" } });
ok("no secret key exists", !S.KEYS.some(k => /key|token|secret|password/i.test(k)));

// Migration: every existing widget key is carried over
const widget = {
    "source": "demo", "showOffline": false, "pulses": false, "notifications": true, "terminal": "foot",
    "sendFolder": "~/Inbox", "links": { "p": { "user": "u", "port": "1" } }, "shareSsh": true, "smooth": false,
    "drift": false, "celebrate": false, "statusDot": false, "middleToggle": false, "searchHints": false,
    "desktopLive": true, "maxItems": 7, "pill": "icon", "companion": false, "groupOpen": "hover",
    "muted": { "m": "M" }, "favorites": { "f": "F" }, "groups": [{ "id": "u2", "name": "G", "members": ["m"] }],
    "exitTies": { "e": "E" }, "exitGroup": "u2", "labMesh": "work", "labPeers": 10, "labLatency": 50,
    "labTrouble": "flap", "labTraffic": "calm", "labLazy": true
};
eq("migration of every key", S.migrate(widget), widget);
eq("migration covers the whole schema", Object.keys(widget), S.KEYS);
eq("migration of nothing is the defaults", S.migrate(undefined), d);
eq("migration ignores a key it does not know", S.migrate({ "setupKey": "abc" }), d);

done("settingsStore");
