.pragma library

// Decisions around installing the Abyss app from the widget. Pure functions
// only, tested with gjs in tests/appinstall.test.js. The widget never installs
// anything by itself: it runs the repository's own install-app.sh, shipped in
// the plugin folder, so nothing is downloaded and nothing needs root.

// "1.2.3" -> [1, 2, 3]; null when the text is not a plain dotted version
function parseVersion(text) {
    const m = /^\s*(\d+(?:\.\d+){0,3})\s*$/.exec(String(text ?? ""));
    return m ? m[1].split(".").map(Number) : null;
}

// What the widget must do about the app, given what `abyss --version` printed
// (empty when the command is absent) and the widget's own version.
// "ok" -> open it; "install" -> offer the install; "update" -> a different
// version is installed, the same offer reinstalls from the plugin folder.
function appState(installedVersion, widgetVersion) {
    const installed = parseVersion(installedVersion);
    const widget = parseVersion(widgetVersion);
    if (!installed)
        return "install";
    if (!widget)
        return "ok";
    const n = Math.max(installed.length, widget.length);
    for (let i = 0; i < n; i++)
        if ((installed[i] ?? 0) !== (widget[i] ?? 0))
            return "update";
    return "ok";
}

// What an app-opening action does once the state is known: "ready" opens the
// app, "fallback" keeps the in-widget path, "invite" offers the install.
// An installed app of another version still opens when the user asked not to
// be asked again.
function askOutcome(state, dontAsk) {
    if (state === "ok" || (state === "update" && dontAsk))
        return "ready";
    return dontAsk ? "fallback" : "invite";
}

// A plugin folder that is safe to hand to `sh` as an argument: absolute, no
// control character. It travels as its own argument, never inside a string.
function validDir(dir) {
    return typeof dir === "string" && dir.charAt(0) === "/" && !/[\u0000-\u001f\u007f]/.test(dir);
}

// The install (or uninstall) command as an argument list; null for a bad folder
function installCommand(pluginDir, uninstall) {
    if (!validDir(pluginDir))
        return null;
    const script = pluginDir.replace(/\/+$/, "") + "/install-app.sh";
    // The widget records itself as the installer so that removing the plugin removes the app
    return uninstall ? ["sh", "--", script, "--uninstall"] : ["sh", "--", script, "--by-widget"];
}

// Run when the plugin is unloaded: if plugin.json is gone the plugin was uninstalled,
// so the app copy that the widget installed is swept (a standalone install is kept).
// The copy of the script inside the app folder is used since the plugin folder is gone.
function sweepCommand(pluginDir, dataHome, home) {
    if (!validDir(pluginDir))
        return null;
    const data = validDir(dataHome) ? dataHome : validDir(home) ? home + "/.local/share" : "";
    if (!data)
        return null;
    return ["sh", "-c", "[ -f \"$1\" ] || exec sh -- \"$2\" --sweep", "sh",
        pluginDir.replace(/\/+$/, "") + "/plugin.json", data.replace(/\/+$/, "") + "/abyss/install-app.sh"];
}

// KEY=value lines of /etc/os-release -> { ID, ID_LIKE: [..] }
function parseOsRelease(text) {
    const out = { id: "", like: [] };
    for (const line of String(text ?? "").split("\n")) {
        const m = /^(ID|ID_LIKE)=(.*)$/.exec(line.trim());
        if (!m)
            continue;
        const value = m[2].replace(/^["']|["']$/g, "").toLowerCase();
        if (m[1] === "ID")
            out.id = value;
        else
            out.like = value.split(/\s+/).filter(Boolean);
    }
    return out;
}

// The command that gets Quickshell, by distribution family. Shown to copy,
// never run. Distributions differ in how Quickshell is packaged, so an
// unknown one gets no command, only the guide link.
const COMMANDS = {
    fedora: { name: "Fedora", command: "sudo dnf install quickshell" },
    arch: { name: "Arch", command: "sudo pacman -S quickshell" },
    nixos: { name: "NixOS", command: "nix profile install nixpkgs#quickshell" },
    gentoo: { name: "Gentoo", command: "sudo emerge --ask gui-apps/quickshell" },
    debian: { name: "Debian / Ubuntu", command: null },
};
const FAMILY = { ubuntu: "debian", linuxmint: "debian", pop: "debian", rhel: "fedora", nobara: "fedora", manjaro: "arch", endeavouros: "arch", cachyos: "arch" };

// { family, name, command } for an os-release text; command is null when no
// package line is known (the guide explains it)
function quickshellHelp(osReleaseText) {
    const rel = parseOsRelease(osReleaseText);
    for (const id of [rel.id, ...rel.like]) {
        const family = COMMANDS[id] ? id : FAMILY[id];
        if (family)
            return { family, name: COMMANDS[family].name, command: COMMANDS[family].command };
    }
    return { family: "unknown", name: "", command: null };
}

// One sentence for the failure band, from what install-app.sh printed on
// stderr: its last line, with the home folder shortened to "~" and capped.
function failureReason(stderr, home) {
    const lines = String(stderr ?? "").split("\n").map(l => l.trim()).filter(Boolean);
    if (!lines.length)
        return "The installer stopped.";
    let line = lines[lines.length - 1];
    if (home && home.length > 1)
        line = line.split(home.replace(/\/+$/, "")).join("~");
    return line.length > 120 ? line.slice(0, 119) + "…" : line;
}
