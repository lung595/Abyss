// Terminal.js tests. Run from anywhere: gjs tests/terminal.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const T = load("components/Terminal.js");

eq("kitty runs ssh directly", T.sshCommand("kitty", "atlas.example"), ["kitty", "ssh", "--", "atlas.example"]);
eq("alacritty needs -e", T.sshCommand("alacritty", "10.0.0.2"), ["alacritty", "-e", "ssh", "--", "10.0.0.2"]);
eq("wezterm needs start --", T.sshCommand("wezterm", "h"), ["wezterm", "start", "--", "ssh", "--", "h"]);
eq("gnome-terminal needs --", T.sshCommand("gnome-terminal", "h"), ["gnome-terminal", "--", "ssh", "--", "h"]);

// "auto": a shell tries each terminal; the host stays a separate argument
const auto = T.sshCommand("auto", "evil.example");
eq("auto goes through sh", auto.slice(0, 2), ["sh", "-c"]);
eq("auto passes the host as $1, untouched", auto.slice(3), ["sh", "evil.example"]);
ok("auto never pastes the host into the script", auto[2].indexOf("evil") < 0);
ok("auto ends ssh's options before the host", auto[2].indexOf("ssh -- \"$1\"") >= 0);

// Hosts that ssh would read as something else are refused
eq("an option is no host", T.sshCommand("kitty", "-oProxyCommand=touch /tmp/x"), null);
eq("an option is no host for auto either", T.sshCommand("auto", "-oProxyCommand=x"), null);
eq("a shell line is no host", T.sshCommand("auto", "evil; rm -rf ~"), null);
eq("no host at all", T.sshCommand("kitty", ""), null);
eq("a space is no host", T.sshCommand("kitty", "a b"), null);
ok("a NetBird name is a host", T.validHost("vega.netbird.cloud"));
ok("an IPv4 address is a host", T.validHost("100.92.0.7"));
ok("an IPv6 address is a host", T.validHost("fd00::1"));
ok("a dash inside a name is fine", T.validHost("lark-phone.mesh.example"));
ok("auto tries every terminal", T.TERMINALS.every(t => auto[2].indexOf("command -v " + t + " ") >= 0));
eq("an unknown terminal falls back to auto", T.sshCommand("nope", "h").slice(0, 2), ["sh", "-c"]);

// The lookup run before SSH, run for real with a PATH holding only a fake
// kitty: the chosen terminal or the first installed one, else exit 1
const { GLib } = imports.gi;
const bin = GLib.dir_make_tmp("abyss-term-XXXXXX");
GLib.file_set_contents(bin + "/kitty", "#!/bin/sh\n");
GLib.spawn_command_line_sync("chmod +x " + bin + "/kitty");
function lookup(t) {
    const env = ["PATH=" + bin + ":/usr/bin:/bin"];
    const [, out, , status] = GLib.spawn_sync(null, T.lookupCommand(t), env, GLib.SpawnFlags.SEARCH_PATH_FROM_ENVP, null);
    return [new TextDecoder().decode(out).trim(), status === 0];
}
eq("auto finds the installed terminal", lookup("auto"), ["kitty", true]);
eq("the chosen terminal when installed", lookup("kitty"), ["kitty", true]);
eq("a chosen terminal that is missing is said", lookup("wezterm"), ["", false]);
ok("names are arguments, never code", T.lookupCommand("auto").slice(4).join(",") === T.TERMINALS.join(","));
ok("a missing chosen terminal is named", T.missingText("foot").indexOf("foot is not installed") > 0);
ok("no terminal at all says where to choose", T.missingText("auto").indexOf("Terminal for SSH") > 0);
GLib.spawn_command_line_sync("rm -r " + bin);

eq("settings list starts with Automatic", T.options()[0], { "label": "Automatic", "value": "auto" });
eq("settings list has every terminal", T.options().length, T.TERMINALS.length + 1);

done("Terminal.js");
