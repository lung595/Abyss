.pragma library

// What THIS plugin may say. It is the only diagnostics file that differs from
// one plugin to the next; the others are copied as they are. Every code is
// explained in docs/DEBUGGING.md (a test fails when one is missing there).
//
// A code is PREFIX-<level><number>: E error, W warning, I info, D debug.
// Errors and warnings also go to the DMS journal (console.error/warn, the only
// calls DMS keeps); info and debug stay in the memory buffer.

var LABEL = "abyss";
var PLUGIN = "Abyss";

// Every key an event may carry, with the only values it may hold ("int",
// "bool", or a list of words). No key takes free text: a peer name, an
// address, an SSH user or a folder can never be a value.
var FIELDS = {
    "action": ["connect", "disconnect", "ping", "ssh", "send", "wake", "exit", "share_ssh", "join"],
    "reason": ["timeout", "refused", "not_found", "bad_data", "offline", "signed_out", "stopped", "relay", "management", "killed", "unknown"],
    "tool": ["netbird", "ip", "ssh", "scp", "ping", "wakeonlan", "xdg-open", "wl_copy", "dms", "sh"],
    "state": ["off", "on", "missing", "ready", "stopped", "signed_out", "hidden", "visible", "ambient"],
    "surface": ["widget", "controlCenter", "desktop", "daemon", "launcher", "settings"],
    "via": ["button", "ipc", "script"],
    "code": "int",
    "count": "int",
    "ms": "int"
};

var CODES = {
    "ABY-E001": { "text": "Reading the mesh from NetBird failed", "fields": ["reason"] },
    "ABY-E002": { "text": "A peer action failed", "fields": ["action", "reason"] },
    "ABY-E003": { "text": "A helper program stopped unexpectedly", "fields": ["tool", "code"] },
    "ABY-E004": { "text": "Sending a file failed", "fields": ["reason"] },
    "ABY-W010": { "text": "NetBird is not usable", "fields": ["state"] },
    "ABY-W011": { "text": "A helper program is missing", "fields": ["tool"] },
    "ABY-I020": { "text": "A surface was loaded", "fields": ["surface"] },
    "ABY-I021": { "text": "A surface was unloaded", "fields": ["surface"] },
    "ABY-I030": { "text": "A diagnostic report was requested", "fields": ["via"] },
    "ABY-D040": { "text": "The scene changed state", "fields": ["state", "count"] }
};

// The surfaces a report may list as active
var SURFACES = ["widget", "controlCenter", "desktop", "daemon", "launcher", "settings"];

// The settings a report may show: the ones that choose a behaviour. What can
// hold a name, a path or an id of the user's own (sendFolder, links, muted,
// favorites, groups, exitTies, exitGroup) is left out.
var SETTINGS = {
    "source": ["auto", "netbird", "demo"],
    "showOffline": "bool",
    "pulses": "bool",
    "notifications": "bool",
    "terminal": ["auto", "ghostty", "kitty", "foot", "alacritty", "wezterm", "konsole", "ptyxis", "gnome-terminal", "xterm"],
    "shareSsh": "bool",
    "smooth": "bool",
    "drift": "bool",
    "celebrate": "bool",
    "statusDot": "bool",
    "middleToggle": "bool",
    "searchHints": "bool",
    "desktopLive": "bool",
    "maxItems": "int",
    "pill": ["peers", "rate", "icon"],
    "companion": "bool",
    "groupOpen": ["both", "hover", "click"],
    "labMesh": ["home", "work", "crowd", "lab"],
    "labPeers": "int",
    "labLatency": "int",
    "labTrouble": ["none", "silent", "flap", "relay", "management", "signedOut", "stopped"],
    "labTraffic": ["calm", "normal", "rush"],
    "labLazy": "bool"
};

// What the plugin reports about itself at the moment of the report (counts of
// what is alive), never about its surroundings
var FACTS = {
    "peers": "int",
    "groups": "int",
    "timersRunning": "int",
    "processesRunning": "int",
    "sceneVisible": "bool",
    "reduceMotion": "bool"
};
