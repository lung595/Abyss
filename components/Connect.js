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
