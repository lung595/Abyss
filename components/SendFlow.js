.pragma library
.import "Send.js" as Send

// How a send is asked for, whichever way it comes (a drop, the creature's
// menu, Ctrl+V on its card, the launcher, `dms ipc call abyss send`), as
// pure functions tested with gjs in tests/. Every way ends in the same call;
// what differs is only where the items come from, and that is checked here
// before anything is run: shape, size, count (Send.js checks the paths).

// Longest peer name or address an IPC call may carry (a DNS name's limit)
const MAX_PAIR = 253;
// A path as text, before decoding: a file:// URL may spell each byte as %XX
const MAX_RAW = Send.MAX_PATH_LENGTH * 3;
// The clipboard text read for Ctrl+V is cut here: more than this is no list
// of files anyone copied
const MAX_PASTE = 64 * 1024;

const GUIDE = Send.GUIDE;

// --- dms ipc call abyss send <peer> <path> -----------------------------------

// { ok, pair, items, reason } for an IPC send. The peer is only looked up by
// the caller (it needs the mesh); here it must be a plain, short word.
function ipcRequest(pair, path) {
    const who = String(pair === undefined || pair === null ? "" : pair).trim();
    const raw = String(path === undefined || path === null ? "" : path);
    const no = reason => ({ "ok": false, "pair": "", "items": [], "reason": reason });
    if (who === "")
        return no("Say which device to send to: abyss send <device> <path>");
    if (who.length > MAX_PAIR || /[\u0000-\u001f\u007f]/.test(who))
        return no("That is not a device name");
    if (raw.trim() === "")
        return no("Say what to send: abyss send <device> <path>");
    if (raw.length > MAX_RAW)
        return no("That path is too long");
    const paths = Send.cleanPaths([raw.trim()]);
    return paths.ok ? { "ok": true, "pair": who, "items": paths.paths, "reason": "" } : no(paths.reason);
}

// --- Ctrl+V of a copied file ---------------------------------------------------

// What reads the copied files: the Wayland clipboard as a list of URLs, which
// is how every file manager offers files it has copied
function pasteCommand() {
    return ["wl-paste", "--no-newline", "--type", "text/uri-list"];
}

// The items in the clipboard text, one per line: "#" lines are comments in
// a URI list, and GNOME's variant starts with the word copy or cut. At
// most Send.MAX_PATHS + 1 come back, so that a longer list is refused by
// Send.cleanPaths rather than silently shortened.
function pastedItems(text) {
    const lines = String(text || "").slice(0, MAX_PASTE).split(/\r?\n/).map(l => l.trim()).filter(l => l !== "" && l.charAt(0) !== "#");
    if (lines.length && (lines[0] === "copy" || lines[0] === "cut"))
        lines.shift();
    return lines.slice(0, Send.MAX_PATHS + 1);
}

// The send failure for a paste that gave nothing: wl-paste ends with 1 when
// nothing was copied (or not as files), and cannot start when it is missing
function pasteFailure(code, text) {
    const f = (title, advice) => ({ "kind": "paste", "title": title, "advice": advice, "guide": GUIDE });
    if (code === -1)
        return f("wl-paste could not run", "Install wl-clipboard (it provides wl-paste), then press Ctrl+V again.");
    if (pastedItems(text).length === 0)
        return f("No copied file to send", "Copy a file or folder in your file manager, then press Ctrl+V on the card.");
    return null;
}

// --- Seeing it -------------------------------------------------------------------

// What a send shows: "grab" plays the file being carried to the creature,
// "instant" goes straight to the progress (Reduce motion), "notify" is for
// when no view of Abyss is open: a notification says how it went, nothing
// is drawn.
function mode(visible, reduceMotion) {
    return !visible ? "notify" : reduceMotion ? "instant" : "grab";
}
