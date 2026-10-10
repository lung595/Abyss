// Send.js tests. Run from anywhere: gjs tests/send.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const S = load("components/Send.js");

// The folder on the device
eq("empty means ~/Downloads, relative to the home", S.remoteDir(""), { "ok": true, "dir": "Downloads/", "reason": "" });
eq("a missing setting is the default too", S.remoteDir(undefined).dir, "Downloads/");
eq("~ alone is the home", S.remoteDir("~").dir, "");
eq("an absolute folder stays", S.remoteDir("/srv/drop").dir, "/srv/drop/");
eq("a trailing slash is not doubled", S.remoteDir("~/Pictures/Trip//").dir, "Pictures/Trip/");
ok("spaces and accents are fine", S.remoteDir("~/Mes Photos/été").ok);
ok("a shell metacharacter is refused", !S.remoteDir("~/a;rm -rf x").ok && !S.remoteDir("$(id)").ok && !S.remoteDir("a`b`").ok && !S.remoteDir("a|b").ok && !S.remoteDir("a'b").ok);
ok("a newline is refused", !S.remoteDir("a\nb").ok);
ok("a parent folder is refused", !S.remoteDir("~/../etc").ok && !S.remoteDir("/a/../b").ok);
ok("a ~ in the middle is refused", !S.remoteDir("a/~b").ok);
ok("a very long folder is refused", !S.remoteDir("a".repeat(300)).ok);
ok("a refusal says why", S.remoteDir("a;b").reason.length > 10);

// Local paths
eq("a plain path", S.localPath("/mnt/u/a.txt"), "/mnt/u/a.txt");
eq("a file URL is decoded", S.localPath("file:///mnt/u/My%20Pics"), "/mnt/u/My Pics");
eq("a localhost URL too", S.localPath("file://localhost/mnt/u/x"), "/mnt/u/x");
eq("a trailing slash goes", S.localPath("/mnt/u/dir/"), "/mnt/u/dir");
eq("a relative path is refused", S.localPath("a:b/c"), null);
eq("an option is no path", S.localPath("-oProxyCommand=x"), null);
eq("a newline is refused", S.localPath("/a\nb"), null);
eq("a broken escape is refused", S.localPath("file:///a%E0%A4%A"), null);
eq("nothing is no path", S.localPath(undefined), null);
eq("many paths, duplicates once", S.cleanPaths(["/a", "/b", "/a/"]).paths, ["/a", "/b"]);
eq("one path may come alone", S.cleanPaths("/a").paths, ["/a"]);
ok("an empty pick says nothing to send", !S.cleanPaths([]).ok && S.cleanPaths([]).reason === "Nothing to send");
ok("one bad item refuses the lot", !S.cleanPaths(["/a", "rel"]).ok);
ok("the whole disk is refused", !S.cleanPaths(["/"]).ok);
ok("too many items are refused", !S.cleanPaths(Array.from({ length: 101 }, (_, i) => "/f" + i)).ok);
ok("100 items are fine", S.cleanPaths(Array.from({ length: 100 }, (_, i) => "/f" + i)).ok);

// Sizes
eq("du lists every path as an argument, even one inside another", S.sizeCommand(["/a b", "/c"]), ["du", "-sbl", "--", "/a b", "/c"]);
const sz = S.parseSizes("10\t/a b\n2048\t/c\n", ["/a b", "/c", "/gone"]);
eq("sizes add up, the absent one is named", sz, { "total": 2058, "missing": ["/gone"] });
ok("everything there is ok", S.checkSizes({ "total": 5, "missing": [] }).ok);
ok("a missing item refuses, with a reason", !S.checkSizes(sz).ok && S.checkSizes(sz).reason.indexOf("gone") > 0);
ok("too big is refused", !S.checkSizes({ "total": 201 * 1024 * 1024 * 1024, "missing": [] }).ok);

// The command
const p = S.plan("vega.mesh", { "user": "tom", "port": "8022" }, ["/mnt/u/a.txt", "file:///mnt/u/My%20Pics"], "~/Inbox");
eq("a plan is ok", [p.ok, p.reason], [true, ""]);
eq("scp: login options, port, -- then paths then the target", p.argv.slice(0, 1).concat(p.argv.slice(-6)), ["scp", "-P", "8022", "--", "/mnt/u/a.txt", "/mnt/u/My Pics", "tom@vega.mesh:Inbox/"]);
ok("batch mode, never a prompt", p.argv.indexOf("BatchMode=yes") > 0);
ok("the SFTP protocol is forced", p.argv[1] === "-s");
ok("folders go along", p.argv.indexOf("-r") > 0);
ok("no option follows --", p.argv.indexOf("--") === p.argv.lastIndexOf("--") && p.argv.indexOf("--") > p.argv.indexOf("-P"));
const d = S.plan("vega.mesh", {}, "/x", "");
eq("default login, default folder", d.argv.slice(-3), ["--", "/x", "vega.mesh:Downloads/"]);
eq("an IPv6 peer is bracketed", S.plan("fd00::1", {}, "/x", "/srv").argv.slice(-1), ["[fd00::1]:/srv/"]);
eq("a bad user in a saved link is left out", S.plan("h", { "user": "-oX", "port": "22; ls" }, "/x", "").argv.slice(-1), ["h:Downloads/"]);
ok("an option is no host", !S.plan("-oProxyCommand=x", {}, "/x", "").ok);
ok("a shell line is no host", !S.plan("a; rm -rf ~", {}, "/x", "").ok);
ok("no host, no plan", !S.plan("", {}, "/x", "").ok);
ok("no path, no plan", !S.plan("h", {}, [], "").ok);
ok("a bad folder, no plan", !S.plan("h", {}, "/x", "a;b").ok);
ok("a refused plan has no command", S.plan("h", {}, [], "").argv === null);
ok("no secret option exists", !p.argv.some(a => /pass|key|token|-i$/i.test(a) && a !== "StrictHostKeyChecking=accept-new"));

// Failures
const ex = (code, err) => S.explain(code, err, "Vega");
eq("auth", ex(255, "tom@vega: Permission denied (publickey,password).").kind, "auth");
eq("host key changed", ex(255, "Host key verification failed.").kind, "hostkey");
eq("unreachable by name", ex(255, "ssh: Could not resolve hostname vega: Name or service not known").kind, "unreachable");
eq("unreachable, no route", ex(255, "ssh: connect to host 100.1.1.1 port 22: No route to host").kind, "unreachable");
eq("unreachable, timeout", ex(255, "ssh: connect to host 100.1.1.1 port 22: Connection timed out").kind, "unreachable");
eq("refused is not unreachable", ex(255, "ssh: connect to host h port 22: Connection refused").kind, "refused");
eq("no space", ex(1, "scp: write remote \"x\": No space left on device").kind, "space");
eq("remote folder missing", ex(1, "scp: dest open \"Nope/\": No such file or directory").kind, "path");
eq("write refused", ex(1, "scp: dest open \"/etc/x\": Permission denied").kind, "denied");
eq("silent 255 is unreachable", ex(255, "").kind, "unreachable");
eq("no scp", ex(-1, "").kind, "missing");
eq("anything else", ex(2, "boom").kind, "other");
ok("a failure names the device", ex(255, "Permission denied (publickey)").title.indexOf("Vega") === 0);
ok("a failure gives advice and the guide", ex(1, "No space left on device").advice.length > 10 && ex(1, "x").guide === "docs/GUIDE.md#send-a-file");
ok("stderr is never shown", ex(1, "scp: /mnt/secret/name: No such file or directory").advice.indexOf("secret") < 0 && ex(1, "scp: /mnt/secret/name: No such file or directory").title.indexOf("secret") < 0);
ok("a peer cannot make a link in the title", ex(255, "Permission denied (publickey)", "").title.length > 0 && S.explain(255, "Permission denied (publickey)", "https://x").title.indexOf("://") < 0);
eq("a timed-out send is told apart from a missing scp", [S.explain(-1, "", "Vega", true).kind, S.explain(-1, "", "Vega", false).kind, S.explain(-1, "", "Vega").kind], ["slow", "missing", "missing"]);
eq("sending text", S.sendingText("Vega"), "Sending to Vega");
ok("a peer cannot make a link in the sending text", S.sendingText("https://x.io").indexOf("://") < 0);
eq("done, one item", S.doneText("Vega", 1), "Sent to Vega");
eq("done, several", S.doneText("Vega", 3), "3 items sent to Vega");

done("send");
