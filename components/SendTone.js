.pragma library

// The colour of the "Send a file…" / "Send a folder…" menu entries. Pure
// maths on {r, g, b} objects (channels 0..1) so it is tested with gjs; the
// scene only wraps the result in a Qt colour.

// Luminance from which the raw role measures 7:1 or more on the dark menu
const BRIGHT = 0.32;
// Share of white mixed into a role too dark to read on the menu
const LIFT = 0.4;

// WCAG relative luminance (sRGB channels linearised)
function luminance(c) {
    const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

// WCAG contrast ratio of two opaque colours
function contrast(a, b) {
    const la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

function mix(a, b, k) {
    return { r: a.r + (b.r - a.r) * k, g: a.g + (b.g - a.g) * k, b: a.b + (b.b - a.b) * k };
}

// The role itself when it is bright enough, a mix with white when the theme
// is light
function sendTone(primary) {
    return luminance(primary) >= BRIGHT ? primary : mix(primary, { r: 1, g: 1, b: 1 }, LIFT);
}
