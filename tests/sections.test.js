// Sections.js test. Run from anywhere: gjs tests/sections.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const S = load("components/Sections.js");

const all = {};
for (const s of S.LIST)
    all[s.id] = 1;

const ids = rows => rows.map(r => r.id).join(" ");

// The common order, eight sections
eq("common order", ids(S.shown(all)), "connect appearance effects bar desktop alerts advanced help");
eq("common names", S.LIST.map(s => s.text).join("|"), "Connect|Appearance|Effects & battery|Bar|Desktop|Alerts & sounds|Advanced|Help");

// An empty section is hidden, the order of the others is unchanged
eq("empty hidden", ids(S.shown({ ...all, effects: 0, help: 0 })), "connect appearance bar desktop alerts advanced");
eq("missing counts are none", ids(S.shown({ connect: 1 })), "connect");
eq("nothing at all", S.shown({}).length, 0);

// A remembered section of the old seven-section page maps to the new one
const rows = S.shown(all);
for (const [old, now] of [["connect", "connect"], ["deep", "appearance"], ["effects", "effects"], ["bar", "bar"], ["desktop", "desktop"], ["source", "advanced"], ["help", "help"]])
    eq("legacy " + old, rows[S.indexOf(rows, old)].id, now);
eq("unknown id opens the first", S.indexOf(rows, "nonsense"), 0);
eq("legacy id in a list without the first row", S.indexOf(S.shown({ ...all, connect: 0 }), "deep"), 0);

// Keyboard steps stop at the ends
eq("up at the top", S.step(0, -1, 8), 0);
eq("down at the bottom", S.step(7, 1, 8), 7);
eq("down", S.step(3, 1, 8), 4);

// Every section has the text the page and the rail show
ok("texts present", S.LIST.every(s => s.text && s.title && s.sub));
done("Sections.js");
