// Connect.js tests. Run from anywhere: gjs tests/connect.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const C = load("components/Connect.js");

eq("three ways in besides SSH", C.kinds(), ["files", "vnc", "rdp"]);
eq("files go through gio first", C.command("files", "gio", "vega.netbird.cloud"), ["gio", "open", "sftp://vega.netbird.cloud/"]);
eq("vnc in remmina", C.command("vnc", "remmina", "100.92.0.7"), ["remmina", "-c", "vnc://100.92.0.7"]);
eq("vncviewer takes the host", C.command("vnc", "vncviewer", "100.92.0.7"), ["vncviewer", "100.92.0.7"]);
eq("rdp in xfreerdp", C.command("rdp", "xfreerdp", "pc.mesh"), ["xfreerdp", "/v:pc.mesh"]);
eq("an IPv6 host is bracketed in a URL", C.command("vnc", "krdc", "fd00::1"), ["krdc", "vnc://[fd00::1]"]);
eq("a program that is not listed is refused", C.command("rdp", "rm", "h"), null);
eq("an unknown kind is refused", C.command("nope", "gio", "h"), null);
eq("an option is no host", C.command("vnc", "vncviewer", "-via=evil"), null);
eq("a shell line is no host", C.command("files", "gio", "a; rm -rf ~"), null);
eq("no lookup for an unknown kind", C.lookupCommand("nope"), null);
eq("the lookup lists the programs as arguments", C.lookupCommand("vnc").slice(4), ["remmina", "vncviewer", "krdc"]);
ok("a missing viewer names what to install", C.missingText("rdp").indexOf("xfreerdp") > 0);

ok("a user name", C.validUser("u0_a123") && C.validUser("tom.dev"));
ok("no option as a user", !C.validUser("-oProxyCommand=x") && !C.validUser("a b") && !C.validUser(""));
ok("ports", C.validPort("8022") && C.validPort(22) && !C.validPort("0") && !C.validPort("70000") && !C.validPort("22; ls") && !C.validPort(""));
eq("only well-formed parts of a link stay", C.cleanLink({ "user": "-x", "port": "8022" }), { "user": "", "port": "8022" });
eq("a link becomes user@host and -p", C.sshTarget("phone.mesh", { "user": "u0", "port": "8022" }), { "target": "u0@phone.mesh", "options": ["-p", "8022"] });

done("Connect.js");
