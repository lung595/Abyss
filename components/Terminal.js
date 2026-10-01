.pragma library

// Builds the command that opens `ssh <host>` in a terminal window. Pure
// functions only, tested with gjs in tests/.
//
// Terminals disagree on how to run a program: most take `-e`, some take the
// program right away, a few want `--`. The host is always passed as its own
// argument (never pasted into a shell string), so a strange peer name cannot
// run anything.

// Supported terminals, in the order "auto" tries them
const TERMINALS = ["ghostty", "kitty", "foot", "alacritty", "wezterm", "konsole", "ptyxis", "gnome-terminal", "xterm"];

// What goes between the terminal and the program it runs
const RUN = {
    "ghostty": ["-e"],
    "kitty": [],
    "foot": [],
    "alacritty": ["-e"],
    "wezterm": ["start", "--"],
    "konsole": ["-e"],
    "ptyxis": ["--"],
    "gnome-terminal": ["--"],
    "xterm": ["-e"]
};

// Options for the settings page: "auto" first, then every terminal
function options() {
    return [{
            "label": "Automatic",
            "value": "auto"
        }].concat(TERMINALS.map(t => ({
                "label": t,
                "value": t
            })));
}

// A host ssh can only read as a host: a name or an address, never an
// option. Peer names come from other people's machines, and a name such as
// "-oProxyCommand=..." would run a command on this one.
function validHost(host) {
    return /^[A-Za-z0-9_.:%\[\]][A-Za-z0-9_.:%\[\]-]*$/.test(String(host || ""));
}

// argv for Quickshell.execDetached, or null for a host validHost refuses.
// A known terminal runs directly; "auto" (or anything unknown) asks sh to
// try each installed one in turn, with the host handed over as $1. "--"
// ends ssh's options either way.
function sshCommand(terminal, host) {
    if (!validHost(host))
        return null;
    if (RUN[terminal])
        return [terminal].concat(RUN[terminal], ["ssh", "--", host]);
    const tries = TERMINALS.map(t => "command -v " + t + " >/dev/null && exec " + [t].concat(RUN[t]).join(" ") + " ssh -- \"$1\"");
    return ["sh", "-c", tries.join("; ") + "; exit 1", "sh", host];
}
