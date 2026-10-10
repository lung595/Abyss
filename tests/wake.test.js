// Wake.js tests. Run from anywhere: gjs tests/wake.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const W = load("components/Wake.js");

// The MAC address
eq("colons, lower case", W.normalizeMac("aa:bb:cc:dd:ee:02"), "aa:bb:cc:dd:ee:02");
eq("upper case is lowered", W.normalizeMac("AA:BB:CC:DD:EE:02"), "aa:bb:cc:dd:ee:02");
eq("dashes become colons", W.normalizeMac("AA-BB-CC-DD-EE-02"), "aa:bb:cc:dd:ee:02");
eq("no separator", W.normalizeMac("aabbccddee02"), "aa:bb:cc:dd:ee:02");
eq("spaces around are trimmed", W.normalizeMac("  aa:bb:cc:dd:ee:02\n"), "aa:bb:cc:dd:ee:02");
for (const bad of ["", "aa:bb:cc:dd:ee", "aa:bb:cc:dd:ee:02:03", "aa:bb:cc:dd:ee:0g", "aa:bb-cc:dd-ee:02", "aa:bb:cc:dd:ee:02; id", "$(id)", "-oProxyCommand=x", "aabbccddee0", "aa:bb:cc:dd:ee:2", "aa.bb.cc.dd.ee.02"])
    eq("refused: " + JSON.stringify(bad), W.normalizeMac(bad), "");
eq("broadcast is refused", W.normalizeMac("ff:ff:ff:ff:ff:ff"), "");
eq("all zero is refused", W.normalizeMac("00:00:00:00:00:00"), "");
eq("multicast is refused", W.normalizeMac("01:00:5e:00:00:01"), "");
eq("undefined and null", [W.normalizeMac(undefined), W.normalizeMac(null)], ["", ""]);

// The network key
eq("a /24", W.lanKey("192.168.1.20", 24), "192.168.1.0/24");
eq("a /16", W.lanKey("10.7.200.9", "16"), "10.7.0.0/16");
eq("a /22 rounds down", W.lanKey("192.168.7.9", 22), "192.168.4.0/22");
eq("high addresses stay unsigned", W.lanKey("255.255.255.200", 24), "255.255.255.0/24");
eq("an octet over 255", W.lanKey("192.168.1.256", 24), "");
eq("not an address", W.lanKey("fe80::1", 64), "");
eq("a prefix too short or too long", [W.lanKey("10.0.0.1", 7), W.lanKey("10.0.0.1", 31), W.lanKey("10.0.0.1", "x")], ["", "", ""]);
eq("nothing", W.lanKey(undefined, 24), "");

// When a MAC may be learned
eq("online with a MAC and a network", W.learn(true, "AA-BB-CC-DD-EE-02", "192.168.1.0/24"), { "mac": "aa:bb:cc:dd:ee:02", "lan": "192.168.1.0/24" });
eq("offline is not learned", W.learn(false, "aa:bb:cc:dd:ee:02", "192.168.1.0/24"), null);
eq("online unknown is not learned", W.learn(undefined, "aa:bb:cc:dd:ee:02", "192.168.1.0/24"), null);
eq("a bad MAC is not learned", W.learn(true, "ff:ff:ff:ff:ff:ff", "192.168.1.0/24"), null);
eq("no network is not learned", W.learn(true, "aa:bb:cc:dd:ee:02", ""), null);
eq("known needs both", [W.known({ "mac": "aa:bb:cc:dd:ee:02" }), W.known({ "lan": "x" }), W.known(null)], [null, null, null]);
eq("known cleans the MAC", W.known({ "mac": "AA:BB:CC:DD:EE:02", "lan": "n" }), { "mac": "aa:bb:cc:dd:ee:02", "lan": "n" });

// The way to send
const LAN = "192.168.1.0/24", OTHER = "10.0.0.0/24";
const target = { "id": "t", "mac": "aa:bb:cc:dd:ee:02", "lan": LAN };
const peers = [
    { "id": "p1", "online": false, "lan": LAN, "host": "p1.example.test" },
    { "id": "p2", "online": true, "lan": OTHER, "host": "p2.example.test" },
    { "id": "t", "online": true, "lan": LAN, "host": "t.example.test" },
    { "id": "p3", "online": true, "lan": LAN, "host": "bad host;x" },
    { "id": "p4", "online": true, "lan": LAN, "host": "p4.example.test" },
    { "id": "p5", "online": true, "lan": LAN, "host": "p5.example.test" }
];
eq("on the same network: direct", W.route(target, LAN, peers).kind, "direct");
eq("direct even with no peer", W.route(target, LAN, []).kind, "direct");
eq("else the first online peer of that network, not the target, not a bad host", W.route(target, OTHER, peers).peer.id, "p4");
eq("the choice is stable", W.route(target, "", peers).peer.id, "p4");
eq("no online peer there", W.route(target, OTHER, peers.slice(0, 2)), { "kind": "none", "peer": null, "reason": "nopeer" });
eq("no peer list at all", W.route(target, OTHER, undefined).reason, "nopeer");
eq("no MAC known", W.route({ "id": "t", "lan": LAN }, LAN, peers), { "kind": "none", "peer": null, "reason": "nomac" });
eq("no target", W.route(undefined, LAN, peers).reason, "nomac");
ok("an unknown here never matches an empty network", W.route({ "mac": "aa:bb:cc:dd:ee:02", "lan": "" }, "", peers).reason === "nomac");

// The commands
eq("tool lookup passes names as arguments", W.toolCommand(), ["sh", "-c", "for t in \"$@\"; do command -v \"$t\" >/dev/null 2>&1 && { echo \"$t\"; exit 0; }; done; exit 1", "sh", "wakeonlan", "etherwake"]);
eq("a known tool", W.parseTool("etherwake\n"), "etherwake");
eq("anything else is no tool", [W.parseTool("rm"), W.parseTool(""), W.parseTool(undefined), W.parseTool("wakeonlan\nrm")], ["", "", "", ""]);
eq("direct argv", W.directCommand("wakeonlan", "AA-BB-CC-DD-EE-02"), ["wakeonlan", "--", "aa:bb:cc:dd:ee:02"]);
eq("direct refuses another program", W.directCommand("rm", "aa:bb:cc:dd:ee:02"), null);
eq("direct refuses a bad MAC", W.directCommand("wakeonlan", "x"), null);
const argv = W.peerCommand("p4.example.test", { "user": "me", "port": "8022" }, "AA:BB:CC:DD:EE:02");
eq("peer argv", argv.slice(0, 11), ["ssh", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=10", "-p", "8022", "--", "me@p4.example.test"]);
ok("the remote command ends with the checked MAC as its own parameter", argv[11].endsWith("' sh aa:bb:cc:dd:ee:02") && argv.length === 12);
ok("the remote script is single-quoted and takes the MAC as $1", argv[11].indexOf("sh -c 'for t in wakeonlan etherwake;") === 0 && argv[11].indexOf("\"$1\"") > 0);
ok("no data inside the remote script", argv[11].indexOf("me") < 0 && argv[11].indexOf("example") < 0);
eq("peer without a link", W.peerCommand("p4.example.test", null, "aa:bb:cc:dd:ee:02").slice(7, 9), ["--", "p4.example.test"]);
eq("peer refuses a bad host", W.peerCommand("-oProxyCommand=x y", null, "aa:bb:cc:dd:ee:02"), null);
eq("peer refuses a bad MAC", W.peerCommand("p4.example.test", null, "aa:bb:cc:dd:ee:02; id"), null);
ok("a bad user in the link is dropped", W.peerCommand("p4.example.test", { "user": "a b;c" }, "aa:bb:cc:dd:ee:02").indexOf("--") === 7);

// The notes
for (const n of [W.routeNote("nomac", "Alice"), W.routeNote("nopeer", "Alice"), W.toolNote("here", ""), W.explain(255, "peer", "Alice", "Bob"), W.explain(-1, "direct", "Alice", ""), W.explain(1, "direct", "Alice", "")]) {
    ok("note " + n.kind + " has a title, advice and the guide link", n.title.length > 10 && n.advice.length > 10 && n.guide === "docs/GUIDE.md#wake-a-device");
}
ok("no MAC says why and how it is learned", /does not know how to wake Alice/.test(W.routeNote("nomac", "Alice").title) && /online/.test(W.routeNote("nomac", "Alice").advice));
ok("no peer names the device", /Alice/.test(W.routeNote("nopeer", "Alice").title));
eq("the missing tool gives the command", W.toolNote("here", "dnf").command, "sudo dnf install wakeonlan");
eq("an unknown package manager gives none", W.toolNote("here", "").command, "");
ok("a peer without the tool is named", /Bob/.test(W.toolNote("Bob", "").title));
eq("a peer's exit 127 is its missing tool", W.explain(127, "peer", "Alice", "Bob").kind, "notool");
eq("a direct 127 is not a peer's", W.explain(127, "direct", "Alice", "").kind, "other");
eq("ssh failing", W.explain(255, "peer", "Alice", "Bob").kind, "peer");
eq("a program that could not start", W.explain(-1, "direct", "Alice", "").kind, "stuck");
ok("a URL-like name is broken up", W.routeNote("nomac", "https://x.test").title.indexOf("://") < 0);
eq("done, direct", W.doneText("Alice", "direct", ""), "Wake signal sent to Alice");
eq("done, through a peer", W.doneText("Alice", "peer", "Bob"), "Wake signal sent to Alice through Bob");

done("wake");
