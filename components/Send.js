.pragma library
.import "Connect.js" as Connect

// Sending files and folders to a peer over SSH (scp), as pure functions
// tested with gjs in tests/. Nothing here runs a program: it builds argument
// lists, checks what may go into them, and turns a failure into a sentence.
// Like Terminal.js and Connect.js, every piece of data is its own argument
// (never pasted into a shell string), "--" ends the options before paths, and
// there is no password anywhere: ssh runs in batch mode, so it uses the keys
// or the NetBird SSH access the peer already accepts and fails instead of
// asking.

// The device's folder when the setting is empty (~ is the user's home there)
const DEFAULT_DIR = "~/Downloads";
// Caps that keep a slip (picking a whole disk) from becoming a transfer
const MAX_PATHS = 100;
const MAX_BYTES = 200 * 1024 * 1024 * 1024;
const MAX_PATH_LENGTH = 4096;
const MAX_DIR_LENGTH = 255;

// Where the guide explains each refusal (value 10: say why and how to fix it)
const GUIDE = "docs/GUIDE.md#send-a-file";

// --- The folder on the device ------------------------------------------------

// What a remote folder may hold. scp (its SFTP mode, forced with -s) does not
// give the path to a remote shell, but a folder name the shell would treat
// specially has no business here either: letters, digits, spaces and a few
// harmless marks only (accented letters pass: QML's engine has no \p{L}).
// "~" is the home, allowed first and alone.
const _DIR_OK = /^[A-Za-z0-9_.@%+=, \/\u00a1-\u2027\u202a-\uffff-]+$/;

// { ok, dir, reason }: dir is what goes after "host:" ("" is the home, a
// relative folder starts there). A setting left empty means the default.
function remoteDir(setting) {
    const raw = String(setting === undefined || setting === null || String(setting).trim() === "" ? DEFAULT_DIR : setting).trim();
    if (raw.length > MAX_DIR_LENGTH)
        return { "ok": false, "dir": "", "reason": "That folder name is too long" };
    let dir = raw;
    if (dir === "~")
        dir = "";
    else if (dir.indexOf("~/") === 0)
        dir = dir.slice(2);
    if (dir !== "" && !_DIR_OK.test(dir))
        return { "ok": false, "dir": "", "reason": "A folder on the device may hold letters, digits, spaces and . _ - / @ % + = , only" };
    if (dir.split("/").some(s => s === ".."))
        return { "ok": false, "dir": "", "reason": "A folder with \"..\" in it is refused" };
    // The slash makes scp treat it as a folder, and fail when it is missing
    // rather than save a single file under that name
    return { "ok": true, "dir": dir === "" ? "" : dir.replace(/\/+$/, "") + "/", "reason": "" };
}

// --- The files on this computer ---------------------------------------------

// An absolute path from a path or a file:// URL (what the clipboard gives), or null.
// Absolute only: a relative path starting with "x:" would read as a host.
function localPath(item) {
    let p = String(item === undefined || item === null ? "" : item);
    if (p.indexOf("file://") === 0) {
        try {
            p = decodeURIComponent(p.slice(7));
        } catch (e) {
            return null;
        }
        // file://localhost/mnt/x and file:///mnt/x
        p = p.replace(/^localhost(?=\/)/, "");
    }
    // No control character (a newline would split du's lines), no NUL
    if (p.charAt(0) !== "/" || p.length > MAX_PATH_LENGTH || /[\u0000-\u001f\u007f]/.test(p))
        return null;
    return p.length > 1 ? p.replace(/\/+$/, "") : p;
}

// { ok, paths, reason }: the distinct usable paths, in order. One bad item
// refuses the lot, so nothing is sent that the user did not mean.
function cleanPaths(items) {
    const list = Array.isArray(items) ? items : items === undefined || items === null ? [] : [items];
    if (list.length === 0)
        return { "ok": false, "paths": [], "reason": "Nothing to send" };
    if (list.length > MAX_PATHS)
        return { "ok": false, "paths": [], "reason": "Too many items at once (" + MAX_PATHS + " at most). Put them in a folder and send that" };
    const out = [];
    for (const item of list) {
        const p = localPath(item);
        if (p === null)
            return { "ok": false, "paths": [], "reason": "One of the items is not a path Abyss can send" };
        if (p === "/")
            return { "ok": false, "paths": [], "reason": "The whole disk cannot be sent" };
        if (out.indexOf(p) < 0)
            out.push(p);
    }
    return { "ok": true, "paths": out, "reason": "" };
}

// argv that prints "bytes<TAB>path" for each path that exists (files and
// folders alike) and complains about the others on stderr. -l counts every
// argument: without it du skips an item already counted inside another
// (a folder and a file in it, or hard links) and it would look missing.
function sizeCommand(paths) {
    return ["du", "-sbl", "--"].concat(paths);
}

// { total, missing }: from du's output for those paths. A path du did
// not list does not exist (or cannot be read). A du that ended with an
// error for a folder it could only read in part still lists it.
function parseSizes(out, paths) {
    const sizes = {};
    for (const line of String(out || "").split("\n")) {
        const m = /^(\d+)\t(.+)$/.exec(line);
        if (m)
            sizes[m[2]] = Number(m[1]);
    }
    const missing = paths.filter(p => sizes[p] === undefined);
    const total = paths.reduce((sum, p) => sum + (sizes[p] || 0), 0);
    return { "total": total, "missing": missing };
}

// { ok, reason } once the sizes are known: all there, and not too big
function checkSizes(sizes) {
    if (sizes.missing.length)
        return { "ok": false, "reason": sizes.missing.length === 1 ? "An item to send is gone or cannot be read" : sizes.missing.length + " items to send are gone or cannot be read" };
    if (sizes.total > MAX_BYTES)
        return { "ok": false, "reason": "That is more than " + Math.round(MAX_BYTES / (1024 * 1024 * 1024)) + " GB. Send it in parts" };
    return { "ok": true, "reason": "" };
}

// --- The transfer --------------------------------------------------------------

// What goes in front of the paths: ssh options for a transfer that must
// never wait for a person. BatchMode: no password prompt (it fails instead);
// accept-new: a first meeting is remembered, a changed key still refuses;
// the alive pair ends a connection that went silent after about a minute.
function _options(link) {
    const l = Connect.cleanLink(link);
    return ["-s", "-r", "-B", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=10", "-o", "ServerAliveInterval=15", "-o", "ServerAliveCountMax=3"].concat(l.port ? ["-P", l.port] : []);
}

// The result of checking everything a send needs before it starts:
// { ok, reason, argv }. host: the peer's address; link: { user, port } as
// saved for the peer; items: paths or file:// URLs; setting: the destination
// folder setting. The sizes are checked apart (sizeCommand), they need the disk.
function plan(host, link, items, setting) {
    if (!Connect.validHost(host))
        return { "ok": false, "reason": "This device has no address Abyss can send to", "argv": null };
    const paths = cleanPaths(items);
    if (!paths.ok)
        return { "ok": false, "reason": paths.reason, "argv": null };
    const dir = remoteDir(setting);
    if (!dir.ok)
        return { "ok": false, "reason": dir.reason, "argv": null };
    const l = Connect.cleanLink(link);
    const target = (l.user ? l.user + "@" : "") + Connect.urlHost(host) + ":" + dir.dir;
    return { "ok": true, "reason": "", "argv": ["scp"].concat(_options(link), ["--"], paths.paths, [target]), "paths": paths.paths };
}

// --- When it fails: say why, and how to fix it ---------------------------------

// { kind, title, advice, guide } for an ended send, from scp's exit code and
// what it wrote on stderr (matched here, never shown: it holds names and
// paths). name is the device's. Exit code -1 is a program that could not
// start or was stopped for taking too long (CliRunner's convention): the
// caller says which with timedOut.
function explain(code, stderr, name, timedOut) {
    const e = String(stderr || "");
    const who = Connect.plainText(name || "this device");
    const f = (kind, title, advice) => ({ "kind": kind, "title": title, "advice": advice, "guide": GUIDE });
    if (/Host key verification failed|REMOTE HOST IDENTIFICATION HAS CHANGED/i.test(e))
        return f("hostkey", who + " presented a different key", "Its SSH key changed since the last time. If you reinstalled it, run ssh-keygen -R with its address, then send again.");
    if (/Permission denied \((publickey|password|keyboard)|Too many authentication failures|Authentication failed/i.test(e))
        return f("auth", who + " refused the login", "Send with the right user on its card, or let it accept your key (ssh-copy-id), or turn on SSH in NetBird for it.");
    if (/No space left on device|Disk quota exceeded/i.test(e))
        return f("space", who + " has no space left", "Free some space on it, or pick another folder in Settings.");
    if (/Connection refused/i.test(e))
        return f("refused", who + " does not accept SSH", "Turn on its SSH server (sshd), or use its port from the card, then send again.");
    if (/Could not resolve hostname|No route to host|Network is unreachable|timed out|Connection closed|Connection reset|Broken pipe/i.test(e) || (code === 255 && e === ""))
        return f("unreachable", who + " does not answer", "Check that it is online and connected to the same mesh, then send again.");
    if (/Permission denied/i.test(e))
        return f("denied", who + " would not let Abyss write there", "Pick a folder you own on it in Settings (Downloads is the default).");
    if (/No such file or directory/i.test(e) || /not a regular file/i.test(e))
        return f("path", "A folder or file was not found", "Create the destination folder on " + who + ", or change it in Settings. Check the files still exist here.");
    if (code === -1 && timedOut)
        return f("slow", "The send to " + who + " took too long", "It was stopped. Send fewer items at once, or check the connection, then send again.");
    if (code === -1)
        return f("missing", "scp could not run", "Install the OpenSSH client (it provides scp), then send again.");
    return f("other", "The send to " + who + " did not finish", "Try again. If it keeps failing, the guide lists what to check.");
}

// A send refused before it started (nothing was run): the reason is the title
function refusal(reason) {
    return { "kind": "input", "title": reason, "advice": "The guide says what can be sent.", "guide": GUIDE };
}

// Looking at the items took longer than a moment: too many or too large
function checkTimeout() {
    return { "kind": "input", "title": "Abyss could not size up what you want to send", "advice": "Send fewer items, or a smaller folder.", "guide": GUIDE };
}

// What the runner says while the transfer runs
function sendingText(name) {
    return "Sending to " + Connect.plainText(name || "this device");
}

// A sentence for a send that went through
function doneText(name, count) {
    return (count === 1 ? "Sent to " : count + " items sent to ") + Connect.plainText(name || "this device");
}
