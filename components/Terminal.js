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

// argv that prints the first of these terminals installed here and exits 0,
// or exits 1 when there is none: the chosen one, or every supported one in
// order for "auto". Run before opening SSH, so a missing terminal is said
// rather than nothing happening. Names go in as arguments, never as code.
function lookupCommand(terminal) {
    const names = RUN[terminal] ? [terminal] : TERMINALS;
    return ["sh", "-c", "for t in \"$@\"; do command -v \"$t\" >/dev/null 2>&1 && { echo \"$t\"; exit 0; }; done; exit 1", "sh"].concat(names);
}

// What to say when lookupCommand found nothing
function missingText(terminal) {
    return RUN[terminal] ? "Not opening SSH: " + terminal + " is not installed. Pick another in Settings > Terminal for SSH" : "Not opening SSH: no terminal found. Install one, or pick yours in Settings > Terminal for SSH";
}

// argv for Quickshell.execDetached, or null for a host validHost refuses.
// A known terminal runs directly; "auto" (or anything unknown) asks sh to
// try each installed one in turn, with the host handed over as $1. "--"
// ends ssh's options either way. link: { user, port } to reach this peer
// as (a phone running Termux: another user, port 8022); only well-formed
// ones count, anything else is left out.
function sshCommand(terminal, host, link) {
    return _inTerminal(terminal, "ssh", host, link);
}

// The same for `sftp`: a file session in a terminal
function sftpCommand(terminal, host, link) {
    return _inTerminal(terminal, "sftp", host, link);
}

// ssh and sftp both read the port as -P/-p, the user as user@host
function _inTerminal(terminal, prog, host, link) {
    if (!validHost(host))
        return null;
    const l = link || {};
    const user = /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}$/.test(String(l.user || "")) ? String(l.user) : "";
    const port = /^\d{1,5}$/.test(String(l.port || "")) && Number(l.port) >= 1 && Number(l.port) <= 65535 ? String(Number(l.port)) : "";
    const opt = port ? [prog === "sftp" ? "-P" : "-p", port] : [];
    const target = (user ? user + "@" : "") + host;
    if (RUN[terminal])
        return [terminal].concat(RUN[terminal], [prog], opt, ["--", target]);
    const tries = TERMINALS.map(t => "command -v " + t + " >/dev/null && exec " + [t].concat(RUN[t]).join(" ") + " " + [prog].concat(opt).join(" ") + " -- \"$1\"");
    return ["sh", "-c", tries.join("; ") + "; exit 1", "sh", target];
}
