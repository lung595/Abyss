// AppInstall.js tests. Run from anywhere: gjs tests/appinstall.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const A = load("components/AppInstall.js");

eq("absent command -> install", A.appState("", "0.5.2"), "install");
eq("same version -> ok", A.appState("0.5.2\n", "0.5.2"), "ok");
eq("trailing zero is the same version", A.appState("0.5", "0.5.0"), "ok");
eq("older app -> update", A.appState("0.5.1", "0.5.2"), "update");
eq("newer app -> update too", A.appState("0.6.0", "0.5.2"), "update");
eq("garbage output -> install", A.appState("abyss: not found", "0.5.2"), "install");
eq("unreadable widget version leaves the app alone", A.appState("0.5.2", ""), "ok");

eq("install command", A.installCommand("/p/Abyss", false), ["sh", "--", "/p/Abyss/install-app.sh", "--by-widget"]);
eq("uninstall command", A.installCommand("/p/Abyss/", true), ["sh", "--", "/p/Abyss/install-app.sh", "--uninstall"]);
eq("sweep command", A.sweepCommand("/p/Abyss/", "/d/", "/h")[5], "/d/abyss/install-app.sh");
eq("sweep falls back to HOME", A.sweepCommand("/p/Abyss", "", "/h")[5], "/h/.local/share/abyss/install-app.sh");
eq("sweep refuses a bad folder", A.sweepCommand("x", "/d", "/h"), null);
eq("relative folder refused", A.installCommand("Abyss", false), null);
eq("control character refused", A.installCommand("/p/a\nb", false), null);
eq("no folder refused", A.installCommand(undefined, false), null);

const os = (id, like) => `NAME="x"\nID=${id}\n` + (like ? `ID_LIKE="${like}"\n` : "");
eq("Fedora", A.quickshellHelp(os("fedora")).family, "fedora");
ok("Fedora has a command", A.quickshellHelp(os("fedora")).command.indexOf("quickshell") > 0);
eq("Arch", A.quickshellHelp(os("arch")).family, "arch");
eq("Manjaro via ID_LIKE", A.quickshellHelp(os("manjaro", "arch")).family, "arch");
eq("NixOS", A.quickshellHelp(os("nixos")).family, "nixos");
eq("Gentoo", A.quickshellHelp(os("gentoo")).family, "gentoo");
eq("Ubuntu", A.quickshellHelp(os("ubuntu", "debian")).family, "debian");
eq("Debian has no package line", A.quickshellHelp(os("debian")).command, null);
eq("Nobara via ID_LIKE", A.quickshellHelp(os("nobara", "rhel centos fedora")).family, "fedora");
eq("unknown", A.quickshellHelp(os("plan9")).family, "unknown");
eq("empty file", A.quickshellHelp("").family, "unknown");
eq("failure reason: last line, home shortened", A.failureReason("x\n/h/u/.local/bin/abyss already exists\n", "/h/u"), "~/.local/bin/abyss already exists");
eq("failure reason: silent installer", A.failureReason("", "/h/u"), "The installer stopped.");
eq("failure reason: capped", A.failureReason("a".repeat(300), ""). length, 120);
eq("ask: ok opens", A.askOutcome("ok", false), "ready");
eq("ask: ok opens with dont-ask", A.askOutcome("ok", true), "ready");
eq("ask: update invites", A.askOutcome("update", false), "invite");
eq("ask: update with dont-ask opens", A.askOutcome("update", true), "ready");
eq("ask: install invites", A.askOutcome("install", false), "invite");
eq("ask: install with dont-ask falls back", A.askOutcome("install", true), "fallback");
done("appinstall");
