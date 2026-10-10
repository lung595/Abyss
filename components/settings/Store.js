.pragma library

// The Abyss settings shared by the widget and the app. Pure: no global, no
// side effect. The file is data from outside (the other program, the user's
// editor), so every value is validated and capped here, once; a bad or unknown
// one falls back to the default and never reaches the code.

const VERSION = 1;
// Caps: a settings file is small, anything bigger is not ours
const MAX_TEXT = 256;
const MAX_ENTRIES = 512;
const MAX_GROUPS = 64;
const MAX_MEMBERS = 256;
const MAX_FILE = 262144;

function bool(def) {
    return { "type": "bool", "def": def };
}
function int(def, min, max) {
    return { "type": "int", "def": def, "min": min, "max": max };
}
function oneOf(def, values) {
    return { "type": "enum", "def": def, "values": values };
}
function text(def) {
    return { "type": "text", "def": def };
}
// id -> name maps (muted, favorites, exit ties)
function names() {
    return { "type": "names", "def": {} };
}

// Key order here is the order in the file. Keys and defaults mirror the DMS
// plugin settings of the widget, so the migration is a straight copy.
const SCHEMA = {
    "source": oneOf("auto", ["auto", "netbird", "demo"]),
    "showOffline": bool(true),
    "pulses": bool(true),
    "notifications": bool(false),
    "terminal": text("auto"),
    "sendFolder": text("~/Downloads"),
    "links": { "type": "links", "def": {} },
    "shareSsh": bool(false),
    "smooth": bool(true),
    "drift": bool(true),
    "celebrate": bool(true),
    "statusDot": bool(true),
    "middleToggle": bool(true),
    "searchHints": bool(true),
    "desktopLive": bool(false),
    "maxItems": int(5, 3, 10),
    "pill": oneOf("peers", ["peers", "rate", "icon"]),
    "companion": bool(true),
    "groupOpen": oneOf("both", ["both", "hover", "click"]),
    "muted": names(),
    "favorites": names(),
    "groups": { "type": "groups", "def": [] },
    "exitTies": names(),
    "exitGroup": text(""),
    "labMesh": oneOf("home", ["home", "work", "crowd", "lab"]),
    "labPeers": int(24, 1, 120),
    "labLatency": int(0, 0, 400),
    "labTrouble": oneOf("none", ["none", "silent", "flap", "relay", "management", "signedOut", "stopped"]),
    "labTraffic": oneOf("normal", ["calm", "normal", "rush"]),
    "labLazy": bool(false)
};

const KEYS = Object.keys(SCHEMA);

function _isObject(v) {
    return v !== null && typeof v === "object" && !Array.isArray(v);
}

function _text(v) {
    return typeof v === "string" && v.length <= MAX_TEXT && !/[\u0000-\u001f\u007f]/.test(v) ? v : null;
}

function _copy(def) {
    return JSON.parse(JSON.stringify(def));
}

// One value checked against its rule; undefined when it is not acceptable
function _check(rule, v) {
    switch (rule.type) {
    case "bool":
        return typeof v === "boolean" ? v : undefined;
    case "int":
        if (typeof v === "string" && /^-?\d+$/.test(v))
            v = Number(v);
        if (typeof v !== "number" || !isFinite(v))
            return undefined;
        return Math.min(rule.max, Math.max(rule.min, Math.round(v)));
    case "enum":
        return rule.values.indexOf(v) >= 0 ? v : undefined;
    case "text":
        return _text(v) ?? undefined;
    case "names": {
        if (!_isObject(v))
            return undefined;
        const out = {};
        for (const id of Object.keys(v).slice(0, MAX_ENTRIES)) {
            const name = _text(v[id]);
            if (name !== null && _text(id) !== null && id !== "__proto__")
                out[id] = name;
        }
        return out;
    }
    case "links": {
        if (!_isObject(v))
            return undefined;
        const out = {};
        for (const id of Object.keys(v).slice(0, MAX_ENTRIES)) {
            const l = v[id];
            if (!_isObject(l) || _text(id) === null || id === "__proto__")
                continue;
            const user = _text(l.user ?? "");
            const port = _text(String(l.port ?? ""));
            if (user !== null && port !== null)
                out[id] = { "user": user, "port": port };
        }
        return out;
    }
    case "groups": {
        if (!Array.isArray(v))
            return undefined;
        const out = [];
        for (const g of v.slice(0, MAX_GROUPS)) {
            if (!_isObject(g) || _text(g.id) === null || _text(g.name) === null || !Array.isArray(g.members))
                continue;
            const members = g.members.slice(0, MAX_MEMBERS).filter(m => _text(m) !== null);
            out.push(Object.assign({}, g, { "id": g.id, "name": g.name, "members": members }));
        }
        return out;
    }
    }
    return undefined;
}

// Every key at its default (a fresh copy each time)
function defaults() {
    const out = {};
    for (const k of KEYS)
        out[k] = _copy(SCHEMA[k].def);
    return out;
}

// A plain object checked key by key: unknown keys dropped, bad values replaced
// by the default
function sanitize(obj) {
    const out = defaults();
    if (!_isObject(obj))
        return out;
    for (const k of KEYS) {
        const v = Object.prototype.hasOwnProperty.call(obj, k) ? _check(SCHEMA[k], obj[k]) : undefined;
        if (v !== undefined)
            out[k] = v;
    }
    return out;
}

// The file's text to a settings object; never throws, never partial
function parse(raw) {
    if (typeof raw !== "string" || raw.length > MAX_FILE)
        return defaults();
    let data;
    try {
        data = JSON.parse(raw);
    } catch (e) {
        return defaults();
    }
    return sanitize(_isObject(data) ? data.settings : null);
}

// Stable text: version first, then the keys in schema order, so two writes of
// the same settings are byte-identical (no needless reload on the other side)
function serialize(settings) {
    return JSON.stringify({ "version": VERSION, "settings": sanitize(settings) }, null, 2) + "\n";
}

// The DMS plugin settings of the widget to a settings object. Read only: the
// caller hands in a copy of what DMS holds. Keys the widget never set stay at
// their default.
function migrate(pluginData) {
    return sanitize(pluginData);
}
