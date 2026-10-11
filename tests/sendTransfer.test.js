// SendTransfer.js tests: command choice, rsync meter, names.
// Run from anywhere: gjs tests/sendTransfer.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const T = load("app/components/SendTransfer.js");

eq("rsync needs both sides", T.program(true, true), "rsync");
eq("no rsync on the device means scp", T.program(true, false), "scp");
eq("no rsync here means scp", T.program(false, true), "scp");

let p = T.plan("rsync", "100.64.0.12", { "user": "ana", "port": "2222" }, ["/tmp/a b.txt", "/tmp/dir"], "");
ok("rsync plan ok", p.ok);
eq("program", p.program, "rsync");
eq("starts with rsync -s", p.argv.slice(0, 3).join(), "rsync,-a,-s");
eq("-- before the paths", p.argv[p.argv.indexOf("--") + 1], "/tmp/a b.txt");
eq("target is last", p.argv[p.argv.length - 1], "ana@100.64.0.12:Downloads/");
ok("port inside -e", p.argv[p.argv.indexOf("-e") + 1].endsWith("-p 2222"));
ok("meter asked for", p.argv.indexOf("--info=progress2") > 0);

p = T.plan("scp", "100.64.0.12", {}, ["/tmp/a"], "");
eq("scp fallback is the engine's", p.argv[0], "scp");
eq("scp program", p.program, "scp");

p = T.plan("rsync", "bad host; rm", {}, ["/tmp/a"], "");
ok("bad host refused", !p.ok);
p = T.plan("rsync", "100.64.0.12", {}, ["relative"], "");
ok("relative path refused", !p.ok);
p = T.plan("rsync", "100.64.0.12", {}, ["/tmp/a"], "../x");
ok("dotdot folder refused", !p.ok);

eq("probe ends with a fixed command", T.remoteProbe("100.64.0.12", {}).slice(-3).join("|"), "--|100.64.0.12|command -v rsync");

eq("no meter yet", T.parseProgress("sending incremental file list\n"), null);
let m = T.parseProgress("  1,234,567  42%    3.20MB/s    0:00:03 (xfr#1, to-chk=0/2)\r  2,000,000  47%    3.30MB/s");
eq("last meter wins", m.fraction, 0.47);
eq("rate", m.rate, "3.30MB/s");
eq("100 percent", T.parseProgress("10  100%  1.0kB/s").fraction, 1);
eq("garbage", T.parseProgress(undefined), null);

eq("short name kept", T.middle("a.pdf", 18, 6), "a.pdf");
eq("long name keeps the extension", T.middle("quarterly-report-final-version-2026-signed.pdf", 18, 6), "quarterly-report-f…ed.pdf");
eq("base name", T.baseName("/tmp/x/y.txt"), "y.txt");
eq("age just now", T.age(1000, 1000), "just now");
eq("age minutes", T.age(5 * 60000, 0), "5 min ago");
eq("age hours", T.age(150 * 60000, 0), "2 h ago");
eq("age never negative", T.age(0, 99999), "just now");
done();
