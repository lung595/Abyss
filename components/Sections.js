.pragma library

// The settings page's sections: names, page titles and the rules around them.
// The list and its order are common to every plugin of the family; a plugin
// only chooses its own page title and subtitle (its voice). Pure functions,
// tested with gjs in tests/sections.test.js.

const LIST = [
    { id: "connect", text: "Connect", title: "Connections", sub: "Join a mesh, let your devices in, and how Abyss opens them" },
    { id: "appearance", text: "Appearance", title: "The deep", sub: "What the sea shows, and how much of it at once" },
    { id: "effects", text: "Effects & battery", title: "Effects & battery", sub: "Every moving thing, and what it costs. Off = calmer and longer battery" },
    { id: "bar", text: "Bar", title: "Bar", sub: "The small jellyfish in your bar" },
    { id: "desktop", text: "Desktop", title: "Desktop fishbowl", sub: "The round jar on your wallpaper" },
    { id: "alerts", text: "Alerts & sounds", title: "Alerts & sounds", sub: "When Abyss speaks up" },
    { id: "advanced", text: "Advanced", title: "Source & test lab", sub: "Your real NetBird, or a made-up mesh to try things on" },
    { id: "help", text: "Help", title: "Quick guide", sub: "Everything in Abyss, in one minute" }
];

// Ids the page used before the common list: a remembered one still opens
// the section that now holds its settings ("Bar & alerts" became "Bar").
const LEGACY = { "deep": "appearance", "source": "advanced" };

// The sections that hold at least one setting, in list order. `counts` maps a
// section id to how many settings it has; a missing id counts as none, so an
// empty section leaves no gap and the others keep their order.
function shown(counts) {
    return LIST.filter(s => (counts[s.id] || 0) > 0);
}

// Index of `id` in `rows` (a result of shown()), also for a legacy id; falls
// back to the first row so a stale or unknown value never opens nothing.
function indexOf(rows, id) {
    const want = LEGACY[id] || id;
    const i = rows.findIndex(s => s.id === want);
    return i < 0 ? 0 : i;
}

// The row next to `i` in a direction (-1 up, +1 down), stopping at the ends
function step(i, dir, n) {
    return Math.max(0, Math.min(n - 1, i + dir));
}
