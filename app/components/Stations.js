.pragma library

// The three stations of the depth gauge and the pure rules around them: where
// a command line lands, what the instruments read at a depth, how the NetBird
// state shows. No QML here, so gjs tests it (tests/stations.test.js).

const MAX_DEPTH = 4000;

// Top to bottom. `title` is the view heading, `mark` the short depth text inside its target (as in the mockup).
const STATIONS = [
    { "id": "settings", "depth": 0, "title": "Settings", "mark": "0" },
    { "id": "send", "depth": 200, "title": "Send", "mark": "200" },
    { "id": "map", "depth": 4000, "title": "Map", "mark": "4k" }
];

function byId(id) {
    return STATIONS.find(s => s.id === id) ?? null;
}

function indexOf(id) {
    return STATIONS.findIndex(s => s.id === id);
}

// Where a parsed command line (Cli.parse) lands: { station, device, files,
// category }. `peer` is the map with that device's card open. Anything the
// views do not know yet falls back to the map, the home station.
function landing(target) {
    const view = target && target.ok ? target.view : "home";
    const station = view === "peer" ? "map" : (byId(view) ? view : "map");
    return {
        "station": station,
        "device": target && target.device ? target.device : "",
        "files": target && target.files ? target.files : [],
        "category": target && target.category ? target.category : ""
    };
}

// The peer a typed name designates (case-insensitive), or null: the caller then
// shows the guided message instead of refusing in silence.
function findPeer(peers, name) {
    const wanted = String(name).toLowerCase();
    return (peers ?? []).find(p => String(p.name).toLowerCase() === wanted) ?? null;
}

// Share of the scale (0 top, 1 bottom) for a depth in metres
function fraction(depth) {
    return Math.max(0, Math.min(1, depth / MAX_DEPTH));
}

// "4 000 m": a thin no-break space groups the thousands
function depthLabel(depth) {
    return String(Math.round(depth)).replace(/\B(?=(\d{3})+$)/g, "\u202F") + " m";
}

// Dive transition: 200 ms down, 150 ms up (design spec); 0 when motion is off
function transitionMs(fromId, toId, reduceMotion) {
    if (reduceMotion || fromId === toId)
        return 0;
    return indexOf(toId) > indexOf(fromId) ? 200 : 150;
}

// Water temperature (°C) at the three stations, as the design spec gives it;
// between them it is interpolated (a picture, not a measure).
const TEMPERATURES = [[0, 18], [200, 6], [4000, 2]];

function temperature(depth) {
    const d = Math.max(0, Math.min(MAX_DEPTH, depth));
    for (let i = 1; i < TEMPERATURES.length; i++) {
        const [d0, t0] = TEMPERATURES[i - 1];
        const [d1, t1] = TEMPERATURES[i];
        if (d <= d1)
            return t0 + (t1 - t0) * (d - d0) / (d1 - d0);
    }
    return TEMPERATURES[TEMPERATURES.length - 1][1];
}

// Instrument readouts at a depth: sea water gains 1 bar per 10 m.
function readouts(depth) {
    const d = Math.max(0, Math.min(MAX_DEPTH, depth));
    return {
        "depth": Math.round(d) + " m",
        "pressure": Math.round(1 + d / 10) + " bar",
        "temperature": Math.round(temperature(d)) + " °C"
    };
}

// NetBird state ("connected" | "stopped" | "missing" | "unknown") as the
// signal readout: a glyph (not colour alone) and a Theme colour name.
function signal(state) {
    switch (state) {
    case "connected":
        return { "glyph": "●", "role": "success", "label": "signal" };
    case "stopped":
        return { "glyph": "◐", "role": "warning", "label": "off" };
    case "missing":
        return { "glyph": "✕", "role": "error", "label": "absent" };
    default:
        return { "glyph": "○", "role": "onSurfaceVariant", "label": "n/a" };
    }
}

// A device name in a message: the middle is elided so that the instruction
// after it (what to do) is never the part that gets cut off.
const NAME_MAX = 32;

function shortName(name) {
    const s = String(name);
    if (s.length <= NAME_MAX)
        return s;
    const head = Math.ceil((NAME_MAX - 1) / 2);
    return s.slice(0, head) + "…" + s.slice(s.length - (NAME_MAX - 1 - head));
}
