// SendFlow.js and GrabMotion.js tests. Run from anywhere: gjs tests/sendflow.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const F = load("components/SendFlow.js");
const M = load("components/GrabMotion.js");

// IPC: dms ipc call abyss send <peer> <path>
eq("a good request", F.ipcRequest("nas", "/mnt/u/a.txt"), { "ok": true, "pair": "nas", "items": ["/mnt/u/a.txt"], "reason": "" });
eq("the peer is trimmed", F.ipcRequest("  nas ", "/a").pair, "nas");
eq("a file URL is accepted", F.ipcRequest("nas", "file:///mnt/My%20Pics").items, ["/mnt/My Pics"]);
ok("no peer is refused, with advice", !F.ipcRequest("", "/a").ok && F.ipcRequest("", "/a").reason.indexOf("abyss send") > 0);
ok("no path is refused", !F.ipcRequest("nas", "").ok && !F.ipcRequest("nas", "   ").ok && !F.ipcRequest("nas").ok);
ok("a relative path is refused", !F.ipcRequest("nas", "a/b").ok);
ok("a parent-of-everything is refused", !F.ipcRequest("nas", "/").ok);
ok("a control character in the peer is refused", !F.ipcRequest("na\ns", "/a").ok && !F.ipcRequest("na\u0000s", "/a").ok);
ok("a very long peer is refused", !F.ipcRequest("n".repeat(300), "/a").ok);
ok("a very long path is refused before decoding", !F.ipcRequest("nas", "/" + "a".repeat(13000)).ok);
ok("a newline in the path is refused", !F.ipcRequest("nas", "/a\n/b").ok);
ok("a refusal always says why", ["", "x"].every(p => F.ipcRequest(p, "").reason.length > 10));

// Ctrl+V: the clipboard as a URI list
eq("the paste command is an argument list", F.pasteCommand(), ["wl-paste", "--no-newline", "--type", "text/uri-list"]);
eq("one URL per line", F.pastedItems("file:///a\r\nfile:///b\n"), ["file:///a", "file:///b"]);
eq("comments and blank lines go", F.pastedItems("# x\n\nfile:///a"), ["file:///a"]);
eq("GNOME's copy word goes", F.pastedItems("copy\nfile:///a"), ["file:///a"]);
eq("cut too", F.pastedItems("cut\nfile:///a"), ["file:///a"]);
eq("nothing copied", F.pastedItems(""), []);
eq("not a string", F.pastedItems(undefined), []);
eq("a long list is cut one past the cap, so it is refused", F.pastedItems(Array(500).fill("file:///a").join("\n")).length, 101);
ok("such a list is then refused by the path check, not shortened", !load("components/Send.js").cleanPaths(F.pastedItems(Array(500).fill("file:///a\n").join(""))).ok);
eq("wl-paste missing", F.pasteFailure(-1, "").kind, "paste");
ok("wl-paste missing says what to install", F.pasteFailure(-1, "").advice.indexOf("wl-clipboard") > 0);
ok("an empty clipboard is explained", F.pasteFailure(1, "").title.indexOf("No copied file") === 0);
eq("a failed read is no file, whatever it printed", F.pasteFailure(1, "file:///a").kind, "paste");
eq("a clipboard with files is no failure", F.pasteFailure(0, "file:///a"), null);
ok("every failure points to the guide", F.pasteFailure(1, "").guide.indexOf("docs/GUIDE.md#") === 0);

// "Send a file…" from the menu
eq("the picker is an argument list, one path per line", F.pickCommand("Nas", false), ["zenity", "--file-selection", "--multiple", "--separator=\n", "--title=Send to Nas"]);
eq("a folder picker adds one flag", F.pickCommand("Nas", true).slice(-1), ["--directory"]);
ok("a peer name with a newline cannot split the title", F.pickCommand("a\nb", false).every(a => a.indexOf("\n") < 0 || a === "--separator=\n"));
ok("a long name is cut", F.pickCommand("n".repeat(200), false)[4].length < 80);
eq("a picker that did not start", F.pickFailure(-1).kind, "picker");
eq("a cancelled picker is no failure", F.pickFailure(1), null);
eq("a chosen file is no failure", F.pickFailure(0), null);

// Refusals before a send
ok("offline names the device and says what to do", F.offlineFailure("Nas").title === "Nas is offline" && F.offlineFailure("Nas").advice.length > 20);
ok("offline copes with no name", F.offlineFailure("").title === "This device is offline");
ok("busy says wait", F.busyFailure().advice.indexOf("Wait") === 0);
eq("the guide anchor", F.anchor(F.offlineFailure("x")), "send-a-file");
eq("no failure, still an anchor", F.anchor(null), "send-a-file");
ok("each refusal points to the guide", [F.offlineFailure("x"), F.busyFailure(), F.pickFailure(-1)].every(f => f.guide.indexOf("docs/GUIDE.md#") === 0));

// What the send shows
eq("no view: a notification", F.mode(false, false), "notify");
eq("no view and reduced motion: still a notification", F.mode(false, true), "notify");
eq("a view: the file is carried", F.mode(true, false), "grab");
eq("reduced motion: straight to the progress", F.mode(true, true), "instant");

// The grab scene
const from = { "x": 100, "y": 100 }, to = { "x": 300, "y": 200 };
eq("it starts invisible at the start point", [M.pose(0, from, to).opacity, M.pose(0, from, to).x, M.pose(0, from, to).phase], [0, 100, "appear"]);
eq("it ends invisible on the creature", [M.pose(1, from, to).opacity, M.pose(1, from, to).x, M.pose(1, from, to).y], [0, 300, 200]);
eq("the phases come in order", [0.1, 0.3, 0.6, 0.95].map(t => M.pose(t, from, to).phase), ["appear", "grab", "carry", "drop"]);
eq("the tentacle holds the file while carrying", M.pose(0.6, from, to).reach, 1);
eq("the tentacle is back at the end", M.pose(1, from, to).reach, 0);
ok("the file is lifted on the way", M.pose(0.625, from, to).y < (from.y + to.y) / 2);
ok("time outside 0..1 is held", M.pose(-1, from, to).opacity === 0 && M.pose(5, from, to).opacity === 0);
ok("opacity and scale stay in range all along", Array.from({ length: 101 }, (_, i) => M.pose(i / 100, from, to)).every(p => p.opacity >= 0 && p.opacity <= 1 && p.scale > 0 && p.scale <= 1.1 && p.reach >= 0 && p.reach <= 1));
ok("x moves forward, never back, while carrying", Array.from({ length: 40 }, (_, i) => M.pose(0.4 + i * 0.011, from, to).x).every((x, i, a) => i === 0 || x >= a[i - 1]));
eq("the tip is at the creature with no reach", M.tip(to, from, 0), to);
eq("the tip is at the file with full reach", M.tip(to, from, 1), from);
eq("a drop starts where the pointer let go", M.startPoint({ "x": 80, "y": 90 }, to, { "w": 600, "h": 400 }), { "x": 80, "y": 90 });
eq("another way starts beside the creature", M.startPoint(null, to, { "w": 600, "h": 400 }), { "x": 190, "y": 110 });
eq("the start is kept inside the scene", M.startPoint({ "x": -50, "y": 999 }, to, { "w": 600, "h": 400 }), { "x": 24, "y": 376 });
eq("a start near the corner is kept in", M.startPoint(null, { "x": 20, "y": 20 }, { "w": 600, "h": 400 }), { "x": 24, "y": 24 });
eq("the bloom is dark outside its time", [M.bloom(-0.1), M.bloom(0), M.bloom(1), M.bloom(2)], [0, 0, 0, 0]);
eq("the bloom peaks in the middle", M.bloom(0.5), 1);
done("sendflow");
