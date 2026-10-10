// Cli.js tests (what `abyss` is asked to open).
// Run from anywhere: gjs tests/cli.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const C = load("app/components/Cli.js");

const p = (args, cwd) => C.parse(args, cwd === undefined ? "/work" : cwd);
const view = args => p(args).view;

// --- Valid targets ---
eq("no word opens the home", p([]), { ok: true, view: "home", device: "", files: [], category: "" });
eq("map", view(["map"]), "map");
eq("peer", p(["peer", "atlas"]), { ok: true, view: "peer", device: "atlas", files: [], category: "" });
eq("settings alone", p(["settings"]).category, "");
eq("settings category", p(["settings", "connect"]).category, "connect");
eq("send with absolute and relative files", p(["send", "atlas", "/tmp/a.txt", "b/c.txt"]).files, ["/tmp/a.txt", "/work/b/c.txt"]);
eq("send without a file still names the device", p(["send", "atlas"]), { ok: true, view: "send", device: "atlas", files: [], category: "" });
eq("dot segments are resolved", p(["send", "atlas", "../x/./y"]).files, ["/x/y"]);
eq(".. cannot climb above the root", p(["send", "atlas", "../../../../etc/x"]).files, ["/etc/x"]);
eq("duplicates are dropped", p(["send", "atlas", "/a", "/a"]).files, ["/a"]);
eq("-- lets a file start with a dash", p(["send", "atlas", "--", "-weird"]).files, ["/work/-weird"]);
eq("a device name with dots and dashes", view(["peer", "my-host.local"]), "peer");
eq("--help", view(["--help"]), "help");
eq("-h", view(["-h"]), "help");
eq("--version", view(["--version"]), "version");
eq("split of the joined words", C.split(["send", "atlas"].join(C.SEPARATOR)), ["send", "atlas"]);
eq("split of nothing", C.split(""), []);
ok("the version is a number", /^\d+\.\d+\.\d+$/.test(C.VERSION));
// One version for the widget and the app: Cli.js must follow plugin.json
const manifest = JSON.parse(new TextDecoder().decode(imports.gi.GLib.file_get_contents(
    imports.gi.GLib.path_get_dirname(imports.system.programPath) + "/../plugin.json")[1]));
eq("VERSION follows plugin.json", C.VERSION, manifest.version);

// --- Refusals carry a short message and the guide anchor ---
let r = p(["frobnicate"]);
ok("unknown command refused", !r.ok && /Unknown command/.test(r.error) && r.guide === "docs/GUIDE.md#app-command-line");
ok("unknown option refused", /Unknown option/.test(p(["--wat"]).error));
ok("send needs a device", !p(["send"]).ok);
ok("peer needs a device", !p(["peer"]).ok);
ok("peer takes only one", !p(["peer", "a", "b"]).ok);
ok("map takes nothing", !p(["map", "x"]).ok);
ok("help takes nothing", !p(["--help", "x"]).ok);
ok("settings takes one category", !p(["settings", "a", "b"]).ok);
ok("category charset", !p(["settings", "Connect;rm"]).ok);
ok("an option among the files is refused", !p(["send", "atlas", "-r", "/a"]).ok);
ok("an empty file name is refused", !p(["send", "atlas", ""]).ok);
ok("a relative file without an absolute cwd is refused", !p(["send", "atlas", "x"], "").ok);
ok("the root cannot be sent", !p(["send", "atlas", "/"]).ok);
ok("..-only path resolving to the root is refused", !p(["send", "atlas", ".."], "/work").ok);

// --- Hostile input ---
for (const bad of ["a b", "a;b", "$(id)", "-x", "a/b", "../x", "a\nb", "é", ".hidden", "a".repeat(64), ""])
    ok("device name refused: " + JSON.stringify(bad), !p(["peer", bad]).ok && !p(["send", bad, "/a"]).ok);
ok("a control character in a file is refused", !p(["send", "atlas", "/a\nb"]).ok);
ok("a NUL byte is refused", !p(["send", "atlas", "/a\u0000b"]).ok);
ok("an overlong argument is refused", !p(["send", "atlas", "/" + "a".repeat(5000)]).ok);

// The working directory arrives over IPC too (control characters, length, relative)
ok("a control character in the cwd is refused", !p(["send", "atlas", "/a"], "/a\nb").ok);
ok("a relative cwd is refused", !p(["map"], "work").ok);
ok("an overlong cwd is refused", !p(["map"], "/" + "a".repeat(5000)).ok);
eq("an empty cwd still opens the home", p([], "").view, "home");

// --- Caps ---
const many = n => Array.from({ length: n }, (_, i) => "/f" + i);
eq("100 files pass", p(["send", "atlas"].concat(many(100))).files.length, 100);
ok("101 files refused", !p(["send", "atlas"].concat(many(101))).ok);
ok("104 arguments refused by count", /Too many arguments/.test(p(["map"].concat(many(103))).error));
ok("too many arguments refused", !p(["send", "atlas"].concat(many(200))).ok);

// --- Not an array ---
eq("undefined argv is the home", p(undefined).view, "home");
ok("a non-string argument is read as text", p([42]).error !== undefined);

done("cli");
