// Terminal.js tests. Run from anywhere: gjs tests/terminal.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const T = load("components/Terminal.js");

eq("kitty runs ssh directly", T.sshCommand("kitty", "atlas.example"), ["kitty", "ssh", "atlas.example"]);
eq("alacritty needs -e", T.sshCommand("alacritty", "10.0.0.2"), ["alacritty", "-e", "ssh", "10.0.0.2"]);
eq("wezterm needs start --", T.sshCommand("wezterm", "h"), ["wezterm", "start", "--", "ssh", "h"]);
eq("gnome-terminal needs --", T.sshCommand("gnome-terminal", "h"), ["gnome-terminal", "--", "ssh", "h"]);

// "auto": a shell tries each terminal; the host stays a separate argument
const auto = T.sshCommand("auto", "evil; rm -rf ~");
eq("auto goes through sh", auto.slice(0, 2), ["sh", "-c"]);
eq("auto passes the host as $1, untouched", auto.slice(3), ["sh", "evil; rm -rf ~"]);
ok("auto never pastes the host into the script", auto[2].indexOf("evil") < 0);
ok("auto tries every terminal", T.TERMINALS.every(t => auto[2].indexOf("command -v " + t + " ") >= 0));
eq("an unknown terminal falls back to auto", T.sshCommand("nope", "h").slice(0, 2), ["sh", "-c"]);

eq("settings list starts with Automatic", T.options()[0], { "label": "Automatic", "value": "auto" });
eq("settings list has every terminal", T.options().length, T.TERMINALS.length + 1);

done("Terminal.js");
