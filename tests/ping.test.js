// Ping.js tests. Run from anywhere: gjs tests/ping.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const P = load("components/Ping.js");

eq("three echoes, as argv", P.command("100.92.14.3"), ["ping", "-c", "3", "-W", "2", "100.92.14.3"]);
eq("an IPv6 address is fine", P.command("fd00::1")[5], "fd00::1");
eq("an option is no address", P.command("-f"), null);
eq("a name is not taken for an address", P.command("atlas; rm -rf ~"), null);
eq("nothing is no address", P.command(""), null);

const ok3 = "PING 100.92.14.3 (100.92.14.3) 56(84) bytes of data.\n64 bytes from 100.92.14.3: icmp_seq=1 ttl=64 time=3.9 ms\n\n--- 100.92.14.3 ping statistics ---\n3 packets transmitted, 3 received, 0% packet loss, time 2003ms\nrtt min/avg/max/mdev = 3.912/4.215/4.801/0.41 ms\n";
eq("an answer says the average", P.summary("atlas", ok3, 0), "atlas: 4.2 ms (min 3.912 · max 4.801, 3/3 replies)");
const part = "--- x ping statistics ---\n3 packets transmitted, 1 received, 66% packet loss, time 2003ms\nrtt min/avg/max/mdev = 9.1/9.1/9.1/0 ms\n";
eq("lost echoes are counted", P.summary("vega", part, 0), "vega: 9.1 ms (min 9.1 · max 9.1, 1/3 replies)");
const none = "--- x ping statistics ---\n3 packets transmitted, 0 received, 100% packet loss, time 2051ms\n";
eq("no answer says so", P.summary("lark", none, 1), "lark: no answer (0/3 replies)");
ok("ping missing says so", P.summary("a", "", -1).indexOf("is it installed") > 0);
eq("busybox's wording", P.summary("b", "3 packets transmitted, 3 packets received, 0% packet loss\nround-trip min/avg/max = 1.0/2.0/3.0 ms\n", 0), "b: 2 ms (min 1.0 · max 3.0, 3/3 replies)");

done("Ping.js");
