.pragma library

// How a tentacle holds a creature: the ribbon does not stop beside it, it
// goes around the body and closes on itself, so the jellyfish seems to hold
// the device for real. Pure maths, built around the creature's centre: the
// ring follows the body of the species (CreatureShape draws them all around
// their own centre) at the scale the creature is drawn at, and the tail that
// closes is the last fifth of the wrap, drawn again in front of the creature
// (Grip.qml) so a held body looks held, not ringed.
//
// The same table gives the drawn footprint of each species (print): what a
// name, a body or a lantern may not be drawn over. One table, so the grip and
// the test that guards the layout can never disagree about a body.

// The silhouette of each species, read off CreatureShape.qml: half width,
// half height and how far the body sits from its own centre (its box is
// 96x96, everything is drawn around the middle of it). A shoal is a group of
// animals drawn at scene size (School.qml's 44 px ring), so it is not scaled.
// tight: how far the tail closes (a shoal is held as one loose loop, it does
// not close at all).
const BODIES = {
    "server": { "hw": 34, "hh": 23.5, "cy": 6.5 },  // manta, wings out
    "vps": { "hw": 38.5, "hh": 19, "cy": -7 },  // lantern whale
    "laptop": { "hw": 36, "hh": 18, "cy": -9 },  // fish
    "phone": { "hw": 13.5, "hh": 25, "cy": -3 },  // seahorse
    "pi": { "hw": 10, "hh": 21.5, "cy": 1.5 },  // little squid
    "nas": { "hw": 29.5, "hh": 17.5, "cy": -2.5 },  // turtle
    "desktop": { "hw": 16, "hh": 16, "cy": 0 },  // nautilus, its shell
    "shoal": { "hw": 22, "hh": 22, "cy": 0, "tight": 1 }
};
// The thread rides a little off the body, so it never cuts the outline
const CLEAR = 3;
// The name under a creature (Creature.qml): below the body, up to three lines
const LABEL_DY = 26, LABEL_H = 46, LABEL_W = 120;
// A relay lantern (Lantern.qml): its coral, and the name it shows when down
const HUB_HW = 24, HUB_HH = 22, HUB_CY = -4, HUB_LABEL_DY = 20, HUB_LABEL_H = 20, HUB_LABEL_W = 90;

// One turn around the body, then a little past it, so the tail crosses the
// ribbon it came from. It rides the body until CLOSE_AT, then draws in.
const TURN = Math.PI * 2 + 0.9;
const CLOSE_AT = 0.8;
const TIGHT = 0.62;
const SLACK = 0.55;  // how far the ring lets go on a body that sleeps
const N = 22;  // points in the wrap
// The share of the grip that is the closing tail, drawn in front
const FRONT = 1 - CLOSE_AT;

function _body(kind) {
    return BODIES[kind] || BODIES.desktop;
}

// The body of a creature of this kind drawn at scale s, in scene pixels
function body(kind, s) {
    const b = _body(kind);
    return { "rx": (b.hw + CLEAR) * s, "ry": (b.hh + CLEAR) * s, "cy": b.cy * s };
}

// The wrap, from where the free ribbon lets go to the tip, around a creature
// of this kind at scale s centred on (cx, cy), entered from `from` (the bell
// or the lantern the tentacle comes from). wake: 1 awake, 0 asleep — a body
// the light has left is let go, the ring slackens and the tail hangs open
// instead of closing.
function hold(kind, s, cx, cy, from, wake) {
    const b = _body(kind);
    const w = wake === undefined ? 1 : Math.max(0, Math.min(1, wake));
    const rx = (b.hw + CLEAR) * s, ry = (b.hh + CLEAR) * s, cy0 = b.cy * s;
    // The ribbon lands on the flank its direction gives, already turning
    // there: the wrap leaves along the line it arrived on
    const a0 = Math.atan2(from[1] - cy, from[0] - cx) + Math.PI / 2;
    const slack = 1 + SLACK * (1 - w);
    // A body the light has left is not held: the tail hangs open (w = 0)
    const close = TIGHT * w * (b.tight === undefined ? 1 : b.tight);
    const out = [];
    for (let i = 0; i <= N; i++) {
        const t = i / N, a = a0 + TURN * t;
        const k = t < CLOSE_AT ? 1 : 1 - (1 - close) * w * (t - CLOSE_AT) / (1 - CLOSE_AT);
        out.push([cx + Math.cos(a) * rx * slack * k, cy + cy0 + Math.sin(a) * ry * slack * k]);
    }
    return out;
}

// How many points at the end of a wrap are the tail that closes on itself
// (of n points in the whole wrap)
function tailCount(n) {
    return Math.max(2, Math.round(n * FRONT));
}

// What a creature of this kind, drawn at scale s, covers on screen: the box
// of its body (around its centre, itself at [x, y + cy]) and the box of its
// name (below it). A shoal draws its ring at scene size, so s does not scale
// it. The layout test keeps everything else out of these boxes.
function print(kind, s) {
    const b = _body(kind), k = kind === "shoal" ? 1 : s;
    return {
        "hw": b.hw * k, "hh": b.hh * k, "cy": b.cy * k,
        "labelDY": (kind === "shoal" ? 28 : LABEL_DY) * (kind === "shoal" ? k : 1),
        "labelH": LABEL_H * (kind === "shoal" ? k : 1),
        "labelW": LABEL_W * (kind === "shoal" ? k : 1)
    };
}

// The same for a relay lantern
function hubPrint() {
    return {
        "hw": HUB_HW, "hh": HUB_HH, "cy": HUB_CY,
        "labelDY": HUB_LABEL_DY, "labelH": HUB_LABEL_H, "labelW": HUB_LABEL_W
    };
}
