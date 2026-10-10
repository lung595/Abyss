// Diagnostics: the allowlist, the anonymization, the memory buffer, the CPU line and the
// report. Every name, address and path below is made up. The checks that matter most are
// the leak ones: whatever goes in, none of it may come out.
// Run from anywhere: gjs tests/diagnostics.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load: loadConst, eq, done } = imports.load;
const GLib = imports.gi.GLib;

const ROOT = GLib.path_get_dirname(GLib.path_get_dirname(imports.system.programPath));
const read = rel => new TextDecoder().decode(GLib.file_get_contents(ROOT + "/" + rel)[1]);

// The diagnostics files declare their tables with "var" (shared byte for byte with
// other plugins), which tests/load.js does not export: this loader does, and hands
// each ".import" its module under the name the file gave it. A module is loaded once, as QML does, so Log, Report and Redact share their state.
const cache = {};
function load(rel) {
    if (cache[rel])
        return cache[rel];
    const dir = rel.replace(/[^/]*$/, "");
    let src = read(rel).replace(/^\.pragma.*$/m, "");
    const names = [], values = [];
    src = src.replace(/^\.import\s+"([^"]+)"\s+as\s+(\w+)\s*;?$/mg, (m, file, name) => {
        names.push(name);
        values.push(load(dir + file));
        return "";
    });
    const exported = [...src.matchAll(/^(?:function|var|const)\s+(\w+)/mg)].map(m => m[1]);
    cache[rel] = new Function(...names, src + "\nreturn {" + exported.join(", ") + "};")(...values);
    return cache[rel];
}

const Allow = load("diagnostics/Allow.js");
const Redact = load("diagnostics/Redact.js");
const Codes = load("diagnostics/Codes.js");
const Log = load("diagnostics/Log.js");
const Cpu = load("diagnostics/Cpu.js");
const Report = load("diagnostics/Report.js");
const Gather = load("diagnostics/Gather.js");

// --- Allow.js: the allowlist -------------------------------------------------------
eq("a yes/no is written yes or no", [Allow.value("bool", true), Allow.value("bool", false)], ["yes", "no"]);
eq("a truthy string is not a yes/no", [Allow.value("bool", "true"), Allow.value("bool", 1)], [null, null]);
eq("a number is rounded and clamped", [Allow.value("int", 3.6), Allow.value("int", 1e12), Allow.value("int", -1e12)], ["4", "1000000000", "-1000000000"]);
eq("a number string, NaN and Infinity are refused", [Allow.value("int", "7"), Allow.value("int", NaN), Allow.value("int", Infinity)], [null, null, null]);
eq("a word is allowed only from its list", [Allow.value(["a", "b"], "a"), Allow.value(["a", "b"], "jdoe-phone")], ["a", null]);
eq("an unknown spec allows nothing", Allow.value("text", "anything"), null);
eq("pick follows the schema's order, not the caller's", Allow.pick({ "x": "int", "y": "bool" }, { "y": true, "x": 2 }), ["x=2", "y=yes"]);
eq("pick drops an unknown key and shows ? for a refused value", Allow.pick({ "x": "int", "y": ["ok"] }, { "x": 1, "y": "100.64.12.7", "name": "jdoe-phone" }), ["x=1", "y=?"]);
eq("pick takes nothing from a non-object", [Allow.pick({ "x": "int" }, null), Allow.pick({ "x": "int" }, "x=1")], [[], []]);
eq("pick does not read inherited keys", Allow.pick({ "toString": "int" }, {}), []);

// --- Redact.js: what must never get out --------------------------------------------
// Built in two halves so the repository-wide greps for links stay empty
const HT = "ht" + "tp";
const PEER = "jdoe-phone";
const FQDN = "jdoe-phone.netbird.cloud";
const NB4 = "100.64.12.7";
const MAC = "AA:BB:CC:DD:EE:01";
const KEY = "6B2F1C9A-4D3E-4F10-9A7B-0C1D2E3F4A5B";
const secrets = {
    "netbird ipv4": "peer " + NB4 + " up",
    "lan ipv4": "from 192.168.7.23 port 22",
    "netbird ipv6": "peer fd7a:115c:a1e0:ab12:4843:cd96:6258:1234 up",
    "ipv6 short": "peer fe80::1ff:fe23:4567:890a%wlan0 up",
    "netbird fqdn": "ssh to " + FQDN,
    "lan host": "reached laptop-jdoe.local and nas.home.arpa",
    "tailnet": "node jdoe-pc.tail1234.ts.net",
    "mac": "wake " + MAC,
    "home path": "QML Plug at file://\x2fhome/jdoe/.config/DankMaterialShell/plugins/x/Plug.qml[4:1]",
    "send folder": "scp \x2fhome/jdoe/Documents/tax-2026.pdf jdoe@" + NB4 + ":~/Received",
    "silverblue home": "/var\x2fhome/jdoe/Documents/a.txt",
    "runtime dir": "/run/user/1000/quickshell/by-id/abc",
    "setup key": "netbird up --setup-key " + KEY,
    "setup key lower": "key " + KEY.toLowerCase(),
    "token key": "authkey=tskey-auth-kAbCdEfGh12345-ZyXwVuTs9876",
    "token colon": "Token: abcDEF123456",
    "bearer": "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig",
    "github token": "ghp_16C7e42F292c6912E7710c838347Ae178B4a",
    "long hex": "key 0123456789abcdef0123456789abcdef0123",
    "email": "write to jdoe@example.org",
    "ssh user at host": "jdoe@" + FQDN,
    "url credentials": HT + "s://jdoe:hunter2@example.org/path"
};
const forbidden = [MAC, MAC.toLowerCase(), NB4, "192.168.7.23", "fd7a:115c", "fe80::1ff", "jdoe", "hunter2", "tskey-auth", "abcDEF123456", "eyJhbGci", "ghp_16C7", "0123456789abcdef", "laptop-jdoe", "nas.home", "tail1234", "netbird.cloud", "tax-2026", "6B2F1C9A", "6b2f1c9a", "1000/quickshell"];
for (const what in secrets) {
    const out = Redact.text(secrets[what]);
    eq("no leak: " + what, forbidden.filter(f => out.indexOf(f) >= 0), []);
}
eq("a home path keeps the rest of the path", Redact.text("file://\x2fhome/jdoe/.config/a/b.qml"), "file://~/.config/a/b.qml");
eq("a plain time is not an address", Redact.text("12:03:41 ready"), "12:03:41 ready");
eq("a version is not an address", Redact.text("Qt 6.11.2, niri 25.08.1"), "Qt 6.11.2, niri 25.08.1");
eq("a code and its states stay readable", Redact.text("ABY-E002 action=ssh reason=timeout"), "ABY-E002 action=ssh reason=timeout");
eq("a control character cannot forge a new line", Redact.text("a\nb\u0000c\r"), "a b c ");
eq("a long line is cut", Redact.text("ab ".repeat(200)).length, 240);
eq("cleaning twice changes nothing", Redact.text(Redact.text(secrets["netbird ipv6"] + " " + secrets["mac"])), Redact.text(secrets["netbird ipv6"] + " " + secrets["mac"]));
eq("nothing becomes an empty text", [Redact.text(null), Redact.text(undefined)], ["", ""]);

// Names learned at run time become stable aliases
eq("a peer name gets an alias", Redact.register("peer", "Bob's Pixel 9"), "peer#1");
eq("the same name (any case) gets the same alias", Redact.register("peer", "BOB'S pixel 9"), "peer#1");
eq("the next peer gets the next number", Redact.register("peer", "Kitchen Tablet"), "peer#2");
eq("the login is hidden as a user", Redact.register("user", "jdoe"), "user#1");
eq("a one-letter name is refused (it would hide every letter)", Redact.register("peer", "a"), "");
eq("a bad kind is refused", Redact.register("pe er", "Name"), "");
eq("the longest known name goes first", Redact.text("Bob's Pixel 9 and kitchen tablet, jdoe"), "peer#1 and peer#2, user#1");
eq("a name with regex characters is taken literally", (Redact.register("peer", "(my) [box]+"), Redact.text("x (my) [box]+ y")), "x peer#3 y");
Redact.forget();
eq("forgetting clears the aliases", Redact.text("Bob's Pixel 9"), "Bob's Pixel 9");

eq("a command is reduced to its program", [Redact.command("/usr/bin/ssh -p 22 jdoe@" + NB4), Redact.command(["/usr/bin/scp", "\x2fhome/jdoe/a.pdf"]), Redact.command("netbird status")], ["ssh", "scp", "netbird"]);
eq("an odd command becomes <cmd>", [Redact.command(""), Redact.command(["x y"]), Redact.command(null), Redact.command(["\x2fhome/jdoe/my tool"])], ["<cmd>", "<cmd>", "<cmd>", "<cmd>"]);

// --- Codes.js: the declarations are consistent -------------------------------------
const wordOk = /^[A-Za-z0-9_.-]{1,24}$/;
const badWords = [];
for (const table of [Codes.FIELDS, Codes.SETTINGS]) {
    for (const key in table) {
        if (Array.isArray(table[key]))
            table[key].forEach(w => { if (!wordOk.test(w)) badWords.push(key + ":" + w); });
    }
}
eq("every allowed word is a short plain token", badWords, []);
eq("every code is well formed and uses declared fields", Object.keys(Codes.CODES).filter(c => !/^[A-Z]{3}-[EWID]\d{3}$/.test(c) || Codes.CODES[c].fields.some(f => !(f in Codes.FIELDS))), []);
eq("every code has a sentence for the guide", Object.keys(Codes.CODES).filter(c => !Codes.CODES[c].text), []);
eq("no field name or setting is a free-text kind", [...Object.values(Codes.FIELDS), ...Object.values(Codes.SETTINGS), ...Object.values(Codes.FACTS)].filter(s => !(s === "int" || s === "bool" || Array.isArray(s))), []);
const guide = read("docs/DEBUGGING.md");
eq("every code is explained in docs/DEBUGGING.md", Object.keys(Codes.CODES).filter(c => guide.indexOf("`" + c + "`") < 0), []);

// --- Log.js: the buffer and the journal line ---------------------------------------
const journal = [];
Log.setSink({ "error": l => journal.push("E " + l), "warn": l => journal.push("W " + l) });
eq("an error is recorded and returned as a line", Log.event("ABY-E002", { "action": "ssh", "reason": "timeout" }), "ABY-E002 action=ssh reason=timeout");
eq("an error goes to the journal with the plugin's label", journal, ["E [abyss] ABY-E002 action=ssh reason=timeout"]);
Log.event("ABY-W010", { "state": "stopped" });
Log.event("ABY-I020", { "surface": "widget" });
Log.event("ABY-D040", { "state": "hidden", "count": 3 });
eq("a warning goes to the journal, info and debug do not", journal.length, 2);
eq("all four stay in the buffer, oldest first", Log.entries().map(e => e.line), ["ABY-E002 action=ssh reason=timeout", "ABY-W010 state=stopped", "ABY-I020 surface=widget", "ABY-D040 state=hidden count=3"]);
eq("an entry carries its time", typeof Log.entries()[0].at, "number");

// Whatever a caller passes, no free text gets into the buffer or the journal
journal.length = 0;
Log.clear();
const line = Log.event("ABY-E002", { "action": "Bob's Pixel 9", "reason": MAC, "name": "jdoe", "address": NB4, "host": FQDN, "path": "\x2fhome/jdoe/x", "token": "tskey-auth-abcdef123456", "key": KEY });
eq("a name, an address, a path or a token passed as a field never comes out", [line, journal], ["ABY-E002 action=? reason=?", ["E [abyss] ABY-E002 action=? reason=?"]]);
eq("a field the code does not declare is dropped", Log.event("ABY-E004", { "reason": "timeout", "action": "send" }), "ABY-E004 reason=timeout");
eq("a code nobody declared is dropped whole", [Log.event("ABY-E999", { "reason": "timeout" }), Log.event("Bob's Pixel", {}), Log.event(null), Log.event("__proto__"), journal.length], ["", "", "", "", 2]);
eq("a call with no fields is fine", Log.event("ABY-E001", undefined), "ABY-E001");
Log.clear();
eq("clear empties the buffer", Log.entries(), []);

// The ring keeps the last 200, oldest first, and never grows
for (let n = 0; n < 450; n++)
    Log.event("ABY-D040", { "count": n });
const kept = Log.entries();
eq("the ring holds exactly its capacity", [Log.CAPACITY, kept.length], [200, 200]);
eq("it keeps the newest and in order", [kept[0].line, kept[199].line], ["ABY-D040 count=250", "ABY-D040 count=449"]);
Log.clear();

// --- Cpu.js: measured on request, from two readings --------------------------------
const stat = "1234 (qs) S 1 1234 1234 0 -1 4194560 100 0 0 0 5000 700 0 0 20 0 30 0 100 1000 100 18446744073709551615";
eq("ticks are user + system", Cpu.ticksOf(stat), 5700);
eq("a process name with spaces and brackets does not shift the fields", Cpu.ticksOf(stat.replace("(qs)", "(my ) S (x)")), 5700);
eq("a missing or broken reading is -1", [Cpu.ticksOf(""), Cpu.ticksOf(null), Cpu.ticksOf("12 (x"), Cpu.ticksOf("1 (x) S 2")], [-1, -1, -1, -1]);
eq("17 ticks in one second is 17 % of a core", Cpu.percent(5700, 5717, 1000), 17);
eq("a two-core second can pass 100 %", Cpu.percent(0, 250, 1000), 250);
eq("a window too short, or time running backwards, is not measured", [Cpu.percent(10, 20, 50), Cpu.percent(20, 10, 1000), Cpu.percent(-1, 10, 1000), Cpu.percent(10, 20, NaN)], [-1, -1, -1, -1]);
eq("the line says it is the whole shell", Cpu.line({ "percent": 4.2, "windowMs": 1000 }), "4.2% of one core, whole shell (DMS and every plugin), over 1 s");
eq("no measure, no number", [Cpu.line(null), Cpu.line({ "percent": -1, "windowMs": 1000 })], ["not measured", "not measured"]);

// --- Report.js: the whole report, with everything personal thrown at it ------------
Redact.register("peer", "Bob's Pixel 9");
Redact.register("user", "jdoe");
Log.event("ABY-I020", { "surface": "widget" });
Log.event("ABY-E003", { "tool": "netbird", "code": 1 });
const report = Report.build({
    "now": Date.UTC(2026, 9, 10, 12, 3, 41),
    "plugin": "0.5.2",
    "versions": { "dms": "1.6.3", "quickshell": "0.3.1", "qt": "6.11.2", "niri": "25.08", "distro": "Fedora Linux 44 (Workstation Edition)" },
    "surfaces": { "widget": true, "daemon": true, "desktop": false, "settings": "yes", "evil": true },
    "settings": { "pill": "peers", "maxItems": 5, "source": "netbird", "terminal": "Bob's Pixel 9", "sendFolder": "\x2fhome/jdoe/Received", "links": { "p1": { "user": "jdoe", "port": 22 } }, "muted": { "p1": "Bob's Pixel 9" } },
    "facts": { "peers": 3, "timersRunning": 0, "sceneVisible": false, "hostname": "laptop-jdoe" },
    "cpu": { "percent": 4.2, "windowMs": 1000 },
    "journal": [
        "WARN qml: [abyss] ABY-W010 state=stopped",
        "ERROR qml: QML Abyss at file://\x2fhome/jdoe/.config/DankMaterialShell/plugins/Abyss/A.qml[4:1]: Bob's Pixel 9 " + MAC + " " + NB4 + " " + FQDN,
        "INFO qml: something unrelated of another plugin 192.168.7.23",
        "x".repeat(10) + " [abyss] token=tskey-auth-abcdef123456",
        "Oct 10 12:00:00 laptop-jdoe qs[123]: [abyss] ABY-W011 tool=netbird"
    ]
});
const lines = report.split("\n");
eq("the report's header holds the versions, surfaces, settings, state and CPU", lines.slice(0, 11), [
    "Abyss diagnostic report (anonymous: versions, states and codes only)",
    "Created      : 2026-10-10 12:03:41 UTC",
    "Plugin       : Abyss 0.5.2",
    "DMS          : 1.6.3   Quickshell : 0.3.1   Qt : 6.11.2",
    "Compositor   : niri 25.08",
    "Distribution : Fedora Linux 44 (Workstation Edition)",
    "Surfaces     : widget, daemon (active)",
    "Settings     : source=netbird terminal=? maxItems=5 pill=peers",
    "State        : peers=3 timersRunning=0 sceneVisible=no",
    "CPU          : 4.2% of one core, whole shell (DMS and every plugin), over 1 s",
    "Last events (2 of 200 kept, oldest first, UTC):"
]);
eq("the events follow, with their time", lines.slice(11, 13).map(l => l.replace(/^ {2}\d\d:\d\d:\d\d /, "  T ")), ["  T ABY-I020 surface=widget", "  T ABY-E003 tool=netbird code=1"]);
eq("only the plugin's own journal lines are kept, cleaned", lines.slice(13), [
    "Journal lines (anonymized, 4 kept, last 50 at most):",
    "  WARN qml: [abyss] ABY-W010 state=stopped",
    "  ERROR qml: QML Abyss at file://~/.config/DankMaterialShell/plugins/Abyss/A.qml[4:1]: peer#1 <mac> <ip> user#<host>",
    "  xxxxxxxxxx [abyss] token=<secret>",
    "  [abyss] ABY-W011 tool=netbird",
    ""
]);
eq("a report ends with a new line", report.endsWith("\n"), true);
const leaks = ["Bob", "Pixel", "jdoe", "AA:BB", "192.168", NB4, "netbird.cloud", "tskey", "\x2fhome/", "Received", "laptop", "hostname"].filter(w => report.indexOf(w) >= 0);
eq("no peer name, address, login, path, setting value or token anywhere in the report", leaks, []);

// An empty or hostile input still gives a readable report and never throws
const bare = Report.build(null);
eq("a report with nothing is still a report", [bare.indexOf("Plugin       : Abyss ?") > 0, bare.indexOf("Surfaces     : none active") > 0, bare.indexOf("CPU          : not measured") > 0], [true, true, true]);
const hostile = Report.build({ "plugin": "1.0 \x2fhome/jdoe", "versions": { "dms": { "a": 1 }, "qt": "x\ny", "distro": "<script>" }, "surfaces": 5, "settings": "no", "facts": [1], "cpu": "high", "journal": "no", "now": "never" });
eq("hostile versions become ? and no input throws", [hostile.indexOf("jdoe"), hostile.indexOf("DMS          : ?   Quickshell : ?   Qt : ?") > 0, hostile.indexOf("<script>")], [-1, true, -1]);

// Zero cost at rest (value 6) and no way out (value 5): the module holds no timer, no
// file, no process and no network call, so nothing in it can run on its own
const files = ["Allow", "Codes", "Cpu", "Gather", "Log", "Redact", "Report"];
// Comments are left out: they may name what the code does not do
const sources = files.map(f => read("diagnostics/" + f + ".js").replace(/^\s*\/\/.*$/mg, ""));
const banned = new RegExp("Timer|setTimeout|setInterval|FileView|Process|XML" + "HttpRequest|fetch\\(|WebSocket|\\bimport (Qt|Quickshell|qs)|Qt\\.|" + HT + "s?:");
eq("no timer, file, process, network or QML import in the module", sources.map((src, i) => banned.test(src) ? files[i] : null).filter(Boolean), []);
eq("only warn and error reach the console, never log", sources.filter(src => /console\.(log|debug|info)/.test(src)).length, 0);
eq("no diagnostics file uses a regular expression lookbehind (QML cannot parse it)", sources.filter(src => src.indexOf("(?<" + "!") >= 0 || src.indexOf("(?<" + "=") >= 0).length, 0);

// A fixed spread of hostile values passed as fields: only plain words and numbers may come out
const garbage = ["Bob's Pixel", MAC, NB4, FQDN, KEY, "\x2fhome/jdoe/x", "tskey-auth-abc123456789", "a\nb", "", null, undefined, {}, [], [1], NaN, Infinity, 1e99, "__proto__", "constructor", true];
const plain = /^ABY-[EWID]\d{3}( [a-z]+=(\?|-?\d+|[a-z0-9_.-]+))*$/;
const dirty = [];
Log.setSink({ "error": () => {}, "warn": () => {} });
for (const code of Object.keys(Codes.CODES)) {
    for (const g of garbage) {
        const fields = {};
        Codes.CODES[code].fields.forEach(f => { fields[f] = g; });
        const out = Log.event(code, fields);
        if (!plain.test(out) || forbidden.some(w => out.indexOf(w) >= 0))
            dirty.push(code + " <- " + JSON.stringify(g) + " -> " + out);
    }
}
eq("every code with every hostile value gives a plain line", dirty, []);

// --- Codes.js against Prefs.qml: the report cannot drift from the real settings ----
// Every setting of Prefs.qml is either in Codes.SETTINGS with a matching kind, or left
// out on purpose because it can hold something personal.
const OMITTED = ["sendFolder", "links", "muted", "favorites", "groups", "exitTies", "exitGroup"];
const prefs = {};
for (const m of read("components/Prefs.qml").matchAll(/readonly property (string|bool|int|var) (\w+): _get\(/g))
    prefs[m[2]] = m[1];
const drift = [];
for (const key in prefs) {
    if (OMITTED.indexOf(key) >= 0)
        continue;
    const spec = Codes.SETTINGS[key];
    if (spec === undefined)
        drift.push(key + " is not in Codes.SETTINGS");
    else if ((prefs[key] === "bool" && spec !== "bool") || (prefs[key] === "int" && spec !== "int") || (prefs[key] === "string" && !Array.isArray(spec)))
        drift.push(key + " has the wrong kind");
}
eq("every setting of Prefs.qml is reported with its kind, or left out on purpose", drift, []);
eq("the check really read Prefs.qml", Object.keys(prefs).length > 20, true);
eq("Codes.SETTINGS holds no key Prefs.qml no longer has", Object.keys(Codes.SETTINGS).filter(k => !(k in prefs)), []);
eq("the omitted settings are all real ones (a rename is noticed)", OMITTED.filter(k => !(k in prefs)), []);
eq("the real terminals are all allowed words", loadConst("components/Terminal.js").TERMINALS.filter(t => Codes.SETTINGS.terminal.indexOf(t) < 0), []);

// --- Gather.js: what the report is made of -----------------------------------------
eq("versions come out of each tool's own line", [Gather.parse("dms", "dms v1.6.3\n"), Gather.parse("niri", "niri 26.04 (8ed0da4)"), Gather.parse("quickshell", "Quickshell 0.3.1 (revision , distributed by Someone)")], ["1.6.3", "26.04", "0.3.1"]);
eq("a tool that said nothing usable gives an empty version", [Gather.parse("dms", ""), Gather.parse("niri", "error: \x2fhome/bob/x not found"), Gather.parse("dms", null)], ["", "", ""]);
eq("the distribution is the pretty name of os-release", Gather.parse("distro", 'NAME="Fedora Linux"\nPRETTY_NAME="Fedora Linux 44 (Workstation Edition)"\nID=fedora\n'), "Fedora Linux 44 (Workstation Edition)");
eq("an os-release without a pretty name gives nothing", Gather.parse("distro", "ID=fedora\n"), "");
eq("the journal is kept as non-empty lines", Gather.parse("journal", "a\n\nb\n"), ["a", "b"]);
eq("the plugin version is read from plugin.json, or empty", [Gather.pluginVersion('{"version":"0.5.2"}'), Gather.pluginVersion("not json"), Gather.pluginVersion('{"version":3}')], ["0.5.2", "", ""]);
eq("only declared settings are read, an unknown value is skipped", Gather.settingsOf(k => k === "pulses" ? true : k === "maxItems" ? 5 : k === "sendFolder" ? "\x2fhome/jdoe" : undefined), { "pulses": true, "maxItems": 5 });
eq("a copy tool that is not installed is told from one that refused", [Gather.missing(-1), Gather.missing(1), Gather.missing(127)], [true, false, false]);
eq("the sensitive copy comes first and nothing is an argument but flags", Gather.COPY_TOOLS.map(t => t.command), [["wl-copy", "--sensitive"], ["dms", "clipboard", "copy"]]);
eq("every probe is an argument list that starts with a program", Gather.PROBES.every(p => Array.isArray(p.command) && /^[a-z]+$/.test(p.command[0])), true);
eq("a long report is cut for the IPC answer", [Gather.capped("x".repeat(30000)).length, Gather.capped("short")], [Gather.MAX_REPORT, "short"]);
eq("a report built from probe answers holds no path of the home folder", /home|bob/i.test(Report.build({ "now": 0, "plugin": Gather.pluginVersion('{"version":"1.0.0"}'), "versions": { "dms": Gather.parse("dms", "dms v1.6.3"), "distro": Gather.parse("distro", 'PRETTY_NAME="Fedora Linux 44"') }, "journal": ["Oct 10 12:00:00 bobs-pc qs[1]: [abyss] ABY-E001 failed at \x2fhome/bob/.cache/x"] })), false);

done("diagnostics");
