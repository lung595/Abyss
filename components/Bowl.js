.pragma library

// The shape of the desktop fishbowl, for a widget of w × h: a round glass
// bowl with a flat base and an open rim, water up to a surface, colourful
// gravel on the bottom, and the rectangle inside where the deep's scene
// lives (its top bar in the air above the water, its floor on the gravel).
// Pure data, drawn by FishBowl.qml; tested with gjs in tests/bowl.test.js.

// Width over height of the bowl; it keeps this shape in any widget
const RATIO = 1.18;
// Heights across the body, as a fraction of its half height from the centre
// (negative = above it)
const RIM = -0.84, SURFACE = -0.6, GRAVEL = 0.58, BASE = 0.9;

// Half the width of the body at height y
function halfAt(b, y) {
    const k = (y - b.cy) / b.ry;
    return k <= -1 || k >= 1 ? 0 : b.rx * Math.sqrt(1 - k * k);
}

// The body's outline from the rim on the right, down round the flat base,
// up to the rim on the left (n points); `from` is where it starts (a height
// fraction), so the water uses the same outline cut at its surface
function _outline(b, from, n) {
    const a0 = Math.asin(from), pts = [];
    for (let i = 0; i <= n; i++) {
        const a = a0 + (Math.PI - 2 * a0) * i / n;
        pts.push([b.cx + b.rx * Math.cos(a), Math.min(b.baseY, b.cy + b.ry * Math.sin(a))]);
    }
    return pts;
}

// The back and the front edge of the sand's top at x, seen from a little
// above: heaped a little in the middle. Below the front edge, down to the
// base, the side of the bed shows through the glass.
function sandBack(b, x) {
    return b.gravelY - 12 * Math.cos((x - b.cx) / b.rx * Math.PI / 2);
}
function sandFront(b, x) {
    return sandBack(b, x) + 9 * Math.cos((x - b.cx) / b.rx * Math.PI / 2);
}

// top: the scene's top bar height (it sits in the air over the water)
function build(w, h, top) {
    const bw = Math.min(w, h * RATIO), bh = bw / RATIO;
    const b = {
        "cx": w / 2,
        "cy": h - bh * 0.53,
        "rx": bw * 0.49,
        "ry": bh * 0.5
    };
    b.rimY = b.cy + RIM * b.ry;
    b.surfaceY = b.cy + SURFACE * b.ry;
    b.gravelY = b.cy + GRAVEL * b.ry;
    b.baseY = b.cy + BASE * b.ry;
    b.rim = { "rx": halfAt(b, b.rimY), "ry": halfAt(b, b.rimY) * 0.09 };
    b.surface = { "rx": halfAt(b, b.surfaceY), "ry": halfAt(b, b.surfaceY) * 0.07 };
    b.outline = _outline(b, RIM, 64);
    b.water = _outline(b, SURFACE, 64);
    // The scene: its surface on the water's, its floor just on the gravel
    // (Layout.frame puts the floor max(34, 9 %) above its bottom)
    const y = b.surfaceY - top, room = b.gravelY + 8 - y;
    const sh = Math.max(room + 34, room / 0.91);
    // As wide as the bowl's belly, where the fan of peers spreads (the bowl
    // is round: much wider there than at the surface or on the gravel).
    // What sits at the surface (the top bar, the sun) or on the gravel (caves,
    // sleepers) keeps an inset, so it stays behind the glass too. The scene's
    // corners fall outside the glass: nothing is drawn there, and the scene
    // does not clip in the bowl.
    const half = b.rx * 0.95;
    b.scene = {
        "x": b.cx - half,
        "y": y,
        "w": 2 * half,
        "h": sh,
        "insetTop": half - b.surface.rx * 0.97,
        "insetFloor": half - halfAt(b, b.gravelY + 16) * 0.97
    };
    return b;
}
