// SendIntent.js tests, and the launcher corpus both ways: Abyss claims none of
// Sands' timer phrases, and Sands finds no timer in Abyss' sentences.
// Run from anywhere: gjs tests/sendIntent.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { GLib } = imports.gi;
const { load, eq, ok, done } = imports.load;
const S = load("components/SendIntent.js");
const C = load("tests/launcher-corpus.js");

const peers = [{ name: "vega" }, { name: "Nas" }, { name: "nova" }, { name: "nomad" }, { name: "my-box" }];

C.SEND.forEach(([phrase, device]) => {
    const r = S.claim(phrase, peers);
    ok("claims: " + phrase, r !== null);
    eq("device of: " + phrase, r ? r.device : "-", device === "nas" ? "Nas" : device);
});
C.PLAIN.forEach(q => ok("stays silent: " + q, S.claim(q, peers) === null));
C.TIMERS.forEach(q => ok("never claims the timer: " + q, S.claim(q, peers) === null));

eq("an ambiguous prefix is no guess", S.claim("send file to no", peers).device, null);
eq("an exact name wins over longer ones", S.claim("send file to nas", [{ name: "nas" }, { name: "nas2" }]).device, "nas");
eq("a name with a dash", S.claim("send file to my box", peers).device, "my-box");
eq("no peers", S.claim("send file to vega", []).device, null);
eq("bad input", S.claim(undefined, peers), null);
eq("too long is ignored", S.claim("send file to " + "v".repeat(100), peers), null);
eq("too many words is ignored", S.claim("send a file to a b c d e f g", peers), null);

ok("fits: send file to anyone", S.fits("send file to zed"));
ok("fits: send to a name", S.fits("envoyer à zed"));
ok("does not fit: a timer", !S.fits("timer 20 min"));
ok("does not fit: a lone verb", !S.fits("send"));
ok("does not fit: a long text", !S.fits("send file " + "x".repeat(100)));

// One device rule for the launcher and the app's command line
const cli = GLib.file_get_contents(GLib.path_get_dirname(imports.system.programPath) + "/../app/components/Cli.js")[1];
const rule = /^const _DEVICE = (.*);$/m;
const sendSrc = GLib.file_get_contents(GLib.path_get_dirname(imports.system.programPath) + "/../components/SendIntent.js")[1];
eq("same device rule as the app's Cli.js", rule.exec(new TextDecoder().decode(sendSrc))[1], rule.exec(new TextDecoder().decode(cli))[1]);

eq("the app command with a device", S.appCommand("vega").join(" "), "abyss send vega");
eq("the app command without a device", S.appCommand(null).join(" "), "abyss");
eq("a name the app refuses is not tried", S.appCommand("-x"), null);
eq("a name with a space is not tried", S.appCommand("my box"), null);

// Sands, read-only, from its installed folder
const sands = GLib.get_home_dir() + "/.config/DankMaterialShell/plugins/Sands/TimeParser.js";
if (!GLib.file_test(sands, GLib.FileTest.EXISTS)) {
    print("- Sands is not installed: the corpus is only checked on Abyss' side");
} else {
    const [, bytes] = GLib.file_get_contents(sands);
    const TP = new Function(new TextDecoder().decode(bytes).replace(/^\.pragma.*$/m, "") + "\nreturn { parse: parse };")();
    const now = Date.UTC(2026, 0, 5, 10, 0, 0);
    C.SEND.forEach(([phrase]) => eq("Sands finds no timer in: " + phrase, TP.parse(phrase, now, { keyword: false }).length, 0));
    C.TIMERS.forEach(q => ok("Sands still reads: " + q, TP.parse(q, now, { keyword: false }).length > 0));
    const t0 = Date.now();
    for (let n = 0; n < 2000; n++)
        S.claim("send a file to vega", peers);
    print("- claim: " + ((Date.now() - t0) * 1000 / 2000).toFixed(1) + " µs per call (matching)");
    const t1 = Date.now();
    for (let n = 0; n < 2000; n++)
        S.claim("firefox browser", peers);
    print("- claim: " + ((Date.now() - t1) * 1000 / 2000).toFixed(1) + " µs per call (other search)");
}
done("sendIntent");
