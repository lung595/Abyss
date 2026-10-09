.pragma library

// What `abyss` was asked to open, from its command line. Pure: no global, no
// side effect, so the launcher, the window and the tests all share one rule.
// Every argument is data from outside: validated and capped here, once.

const VERSION = "0.5.2";

// 100 files plus "send", the device name and "--"
const MAX_ARGS = 103;
const MAX_ARG_LENGTH = 4096;
const MAX_FILES = 100;

// A device name as NetBird and DNS spell it
const _DEVICE = /^[A-Za-z0-9][A-Za-z0-9._-]{0,62}$/;
const _CATEGORY = /^[a-z][a-z-]{0,30}$/;
const _CONTROL = /[\u0000-\u001f\u007f]/;

const GUIDE = "docs/GUIDE.md#app-command-line";

function _fail(error) {
    return { "ok": false, "error": error + " (abyss --help)", "guide": GUIDE };
}

function _target(view, device, files, category) {
    return { "ok": true, "view": view, "device": device, "files": files, "category": category };
}

// An absolute, normalised path from a path given as typed (relative to cwd),
// or null. ".." cannot climb above the root.
function _resolve(item, cwd) {
    if (item.charAt(0) !== "/" && cwd.charAt(0) !== "/")
        return null;
    const parts = [];
    for (const seg of (item.charAt(0) === "/" ? item : cwd + "/" + item).split("/")) {
        if (seg === "" || seg === ".")
            continue;
        if (seg === "..")
            parts.pop();
        else
            parts.push(seg);
    }
    return "/" + parts.join("/");
}

function _device(word) {
    return word !== undefined && _DEVICE.test(word) ? word : null;
}

// argv: the words after `abyss`; cwd: where it was typed (for relative files).
// Returns { ok, view, device, files, category } or { ok: false, error, guide }.
// view: "home" | "send" | "settings" | "map" | "peer" | "help" | "version"
function parse(argv, cwd) {
    const args = Array.isArray(argv) ? argv.map(a => String(a)) : [];
    const dir = String(cwd === undefined || cwd === null ? "" : cwd);
    // The directory comes from the launcher, but the IPC door is open to anyone
    if (dir.length > MAX_ARG_LENGTH || _CONTROL.test(dir) || (dir !== "" && dir.charAt(0) !== "/"))
        return _fail("The working directory is not an absolute path");
    if (args.length > MAX_ARGS)
        return _fail("Too many arguments");
    for (const a of args) {
        if (a.length > MAX_ARG_LENGTH)
            return _fail("An argument is too long");
        if (_CONTROL.test(a))
            return _fail("An argument holds a control character");
    }
    if (args.length === 0)
        return _target("home", "", [], "");

    const word = args[0];
    const rest = args.slice(1);
    if (word === "--help" || word === "-h" || word === "help")
        return rest.length ? _fail("--help takes no argument") : _target("help", "", [], "");
    if (word === "--version" || word === "-V")
        return rest.length ? _fail("--version takes no argument") : _target("version", "", [], "");

    if (word === "map")
        return rest.length ? _fail("map takes no argument") : _target("map", "", [], "");

    if (word === "settings") {
        if (rest.length > 1)
            return _fail("settings takes at most one category");
        if (rest.length === 1 && !_CATEGORY.test(rest[0]))
            return _fail("Not a settings category");
        return _target("settings", "", [], rest.length ? rest[0] : "");
    }

    if (word === "peer") {
        const name = _device(rest[0]);
        if (name === null || rest.length !== 1)
            return _fail("peer needs one device name");
        return _target("peer", name, [], "");
    }

    if (word === "send") {
        const name = _device(rest[0]);
        if (name === null)
            return _fail("send needs a device name");
        let items = rest.slice(1);
        // "--" ends the options: what follows is a file even if it starts with "-"
        if (items[0] === "--")
            items = items.slice(1);
        else if (items.some(i => i.charAt(0) === "-"))
            return _fail("Unknown option; put -- before a file starting with -");
        if (items.length > MAX_FILES)
            return _fail("Too many files (" + MAX_FILES + " at most)");
        const files = [];
        for (const item of items) {
            const path = item === "" ? null : _resolve(item, dir);
            if (path === null)
                return _fail("A file is not a path Abyss can find");
            if (path === "/")
                return _fail("The whole disk cannot be sent");
            if (files.indexOf(path) < 0)
                files.push(path);
        }
        return _target("send", name, files, "");
    }

    return _fail(word.charAt(0) === "-" ? "Unknown option" : "Unknown command");
}

// One string for the launcher to pass the words on (environment or IPC): the
// parser rejects control characters, so the unit separator cannot be inside.
const SEPARATOR = "\u001f";

function split(joined) {
    const text = String(joined === undefined || joined === null ? "" : joined);
    return text === "" ? [] : text.split(SEPARATOR);
}
