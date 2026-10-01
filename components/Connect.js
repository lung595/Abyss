.pragma library

// How Abyss reaches a peer beyond SSH: files (SFTP), a remote desktop (VNC,
// RDP). Pure functions only, tested with gjs in tests/. Like Terminal.js,
// every host is its own argument (never pasted into a shell string) and a
// host that a program could read as an option is refused.

// Programs tried in order for each way in: [program, argv built from the
// URL host]. Whatever is installed first is used.
const PROGRAMS = {
    "files": [["gio", h => ["open", "sftp://" + h + "/"]], ["xdg-open", h => ["sftp://" + h + "/"]]],
    "vnc": [["remmina", h => ["-c", "vnc://" + h]], ["vncviewer", h => [h]], ["krdc", h => ["vnc://" + h]]],
    "rdp": [["xfreerdp3", h => ["/v:" + h]], ["xfreerdp", h => ["/v:" + h]], ["remmina", h => ["-c", "rdp://" + h]], ["krdc", h => ["rdp://" + h]]]
};

const LABELS = { "files": "Files", "vnc": "Screen (VNC)", "rdp": "Desktop (RDP)" };

function kinds() {
    return Object.keys(PROGRAMS);
}
function label(kind) {
    return LABELS[kind] || kind;
}

// A host as a URL wants it (IPv6 in brackets)
function urlHost(host) {
    const h = String(host || "");
    return h.indexOf(":") >= 0 && h.charAt(0) !== "[" ? "[" + h + "]" : h;
}

function validHost(host) {
    return /^[A-Za-z0-9_.:%\[\]][A-Za-z0-9_.:%\[\]-]*$/.test(String(host || ""));
}

// argv that prints the first program installed for this kind and exits 0,
// or exits 1 when there is none; null for an unknown kind
function lookupCommand(kind) {
    if (!PROGRAMS[kind])
        return null;
    return ["sh", "-c", "for t in \"$@\"; do command -v \"$t\" >/dev/null 2>&1 && { echo \"$t\"; exit 0; }; done; exit 1", "sh"].concat(PROGRAMS[kind].map(p => p[0]));
}

// argv for Quickshell.execDetached with the program lookupCommand found, or
// null for an unknown kind or program, or a host validHost refuses
function command(kind, program, host) {
    if (!PROGRAMS[kind] || !validHost(host))
        return null;
    const p = PROGRAMS[kind].find(x => x[0] === program);
    return p ? [p[0]].concat(p[1](urlHost(host))) : null;
}

function missingText(kind) {
    return "Nothing installed to open " + label(kind) + ": install one of " + (PROGRAMS[kind] || []).map(p => p[0]).join(", ");
}

// --- SSH details per peer (user, port): a phone running Termux listens on
// 8022 and has its own user name ---------------------------------------------

function validUser(user) {
    return /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}$/.test(String(user || ""));
}
function validPort(port) {
    const n = Number(port);
    return /^\d{1,5}$/.test(String(port)) && n >= 1 && n <= 65535;
}

// "user", "port" from a saved link, only the valid ones: { user, port }
function cleanLink(link) {
    const l = link || {}, out = { "user": "", "port": "" };
    if (validUser(l.user))
        out.user = String(l.user);
    if (validPort(l.port))
        out.port = String(Number(l.port));
    return out;
}

// What goes after "--" and the options before it, for ssh
function sshTarget(host, link) {
    const l = cleanLink(link);
    return {
        "target": (l.user ? l.user + "@" : "") + host,
        "options": l.port ? ["-p", l.port] : []
    };
}

// --- When it cannot open: say why, and how to fix it ------------------------

// The port each way in listens on (a link's port wins for ssh and sftp)
const PORTS = { "ssh": 22, "sftp": 22, "files": 22, "vnc": 5900, "rdp": 3389 };

function portOf(kind, link) {
    const l = cleanLink(link);
    return (kind === "ssh" || kind === "sftp" || kind === "files") && l.port ? Number(l.port) : PORTS[kind] || 0;
}

// argv that exits 0 when host:port answers within 2 s. Both are arguments
// of the script, never pasted into it; null for a refused host or port
function probeCommand(host, port) {
    if (!validHost(host) || !validPort(port))
        return null;
    const h = String(host).replace(/^\[|\]$/g, "");
    return ["timeout", "2", "bash", "-c", ": </dev/tcp/\"$1\"/\"$2\"", "probe", h, String(port)];
}

// argv printing the package manager found here (pacman, apt…), or nothing
function packageManagerCommand() {
    return ["sh", "-c", "for p in pacman apt dnf zypper xbps-install; do command -v \"$p\" >/dev/null 2>&1 && { echo \"$p\"; exit 0; }; done; exit 1"];
}

// What to install for a way in, per package manager
const PACKAGES = {
    "vnc": { "pacman": "remmina libvncserver", "apt": "remmina remmina-plugin-vnc", "dnf": "remmina remmina-plugins-vnc", "zypper": "remmina", "xbps-install": "remmina" },
    "rdp": { "pacman": "remmina freerdp", "apt": "remmina remmina-plugin-rdp", "dnf": "remmina remmina-plugins-rdp", "zypper": "remmina freerdp", "xbps-install": "remmina freerdp" },
    "files": { "pacman": "gvfs", "apt": "gvfs-backends", "dnf": "gvfs-fuse", "zypper": "gvfs-backends", "xbps-install": "gvfs" }
};
const INSTALL = { "pacman": "sudo pacman -S --needed ", "apt": "sudo apt install ", "dnf": "sudo dnf install ", "zypper": "sudo zypper install ", "xbps-install": "sudo xbps-install " };

// A missing viewer: { title, details, command } for a toast with a copy
// button (command "" when the package manager is unknown)
function installHelp(kind, pm) {
    const pkg = (PACKAGES[kind] || {})[pm] || "";
    const what = kind === "files" ? "file manager support for SFTP" : kind === "vnc" ? "VNC viewer" : "remote desktop (RDP) viewer";
    return {
        "title": "No " + what + " installed",
        "details": pkg ? "Install it with this command, then click " + label(kind) + " again." : "Install Remmina (or " + (PROGRAMS[kind] || []).map(p => p[0]).join(", ") + ") from your software center, then try again.",
        "command": pkg ? INSTALL[pm] + pkg : ""
    };
}

// The device does not answer on that port: { title, details, command }
function closedHelp(kind, name, isPhone, port) {
    if (kind === "vnc")
        return { "title": name + " is not sharing its screen", "details": "Turn on screen sharing (VNC) on " + name + ", port " + port + ". On Linux: install wayvnc or x11vnc and start it.", "command": "" };
    if (kind === "rdp")
        return { "title": name + " does not accept remote desktop", "details": "Turn on Remote Desktop on " + name + " (Windows: Settings › System › Remote Desktop; GNOME: Settings › Sharing).", "command": "" };
    if (isPhone)
        return { "title": name + " does not accept Terminal yet", "details": "On the phone: install Termux, run this once in it, then click \"Use 8022\" on its card here.", "command": "pkg install openssh && passwd && sshd" };
    return { "title": name + " does not accept Terminal (port " + port + ")", "details": "Turn on its SSH server, on " + name + ":", "command": "sudo systemctl enable --now sshd" };
}
