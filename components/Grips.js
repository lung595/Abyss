.pragma library
.import "Shapes.js" as Shapes

// How a tentacle holds a creature: the ribbon does not stop beside it, it
// goes around the body and closes on itself, so the jellyfish seems to hold
// the device for real. It walks the creature's own outline (Shapes.js), the
// one the canvas strokes, so it rides on the animal whatever its species and
// never cuts through it (P83: an ellipse around these bodies passed under
// seven of them, and the grip could not be seen at all).
//
// The tail that closes is the last fifth of the walk, drawn again in front of
// the creature (Grip.qml) so a held body looks held, not ringed.

// How a tentacle holds a creature: it does not stop beside it, it comes down
// on the flank the ribbon arrived on, sweeps UNDER the belly and hooks back
// up on the other side, so the jellyfish seems to hold the device for real
// (D132). It walks the creature's own outline (Shapes.js), the one the canvas
// strokes, so it rides on the animal whatever its species and never cuts
// through it (P83: an ellipse around these bodies passed under seven of
// them, and the grip could not be seen at all).
//
// The back is left open: the hook's mouth faces the tentacle, and the tip
// that comes back up is drawn in front of the body (Grip.qml) so a held
// creature looks held, not ringed.

// How far off the body the ribbon rides, in the shape's own units: it is
// scaled with the rest of the walk like everything else
const CLEAR = 2.5;
// How far round the body the hook reaches, as a share of one turn: 0.75 is
// three quarters of a way, from the flank the ribbon lands on, under the
// belly, and back up the other side. Asleep it stops short and hangs open.
const REACH = 0.75;
const REACH_ASLEEP = 0.55;
// The share of the hook over which the tip closes onto the body
const CLOSE_AT = 0.72;
// How much of the clearance the tip gives back. It visibly tightens without
// reaching the outline, which a radius-wise inset cannot promise on a small
// animal
const SHUT = 0.6;
// Where the ribbon lands, in degrees back from the direction it came from: it
// touches the flank it arrives on, already turning to run along the body.
// Landing straight on (0) is prettier on paper and worse in the scene — the
// ribbon then comes straight down the column and passes through whatever sits
// between (P84). Measured over the 7 configurations the layout test uses, the
// deepest a ribbon cuts into a neighbour is 23 px landing straight on, 18 px a
// quarter turn back, and 16 px at this angle.
const LAND = -45;
const SLACK = 0.45;  // how far the hook lets go on a body that sleeps
const N = 44;  // points in one turn of the walk
// The share of the hook drawn in front of the body: the stretch that passes
// under the belly and the tip coming back up. Drawn behind, a hook reads as a
// "C" floating beside the animal; drawn in front, it reads as an arm holding
// it, which is what D132 asked for.
const FRONT = 0.45;
// A shoal is a group of animals: one loose loop around the whole school
// (School.qml draws a 44 px ring), never closing, and not scaled by the
// lens, which grows the ring itself
const SHOAL = { "r": 25 };

function _ring(kind, s) {
    if (kind === "shoal") {
        const pts = [];
        for (let i = 0; i < N; i++) {
            const a = i / N * Math.PI * 2;
            pts.push([Math.cos(a) * SHOAL.r * s, Math.sin(a) * SHOAL.r * s]);
        }
        return { "points": pts, "cy": 0 };
    }
    const o = Shapes.outline(kind, CLEAR, N);
    return { "points": o.points.map(q => [q[0] * s, q[1] * s]), "cy": o.cy * s };
}

// The hook, from where the free ribbon lets go to its tip, around a creature
// of this kind at scale s centred on (cx, cy), entered from `from` (the bell
// or the lantern the tentacle comes from). wake: 1 awake, 0 asleep — a body
// the light has left is let go: the hook slackens and stops short, so its tip
// hangs open under the belly instead of coming back up.
function hold(kind, s, cx, cy, from, wake) {
    const ring = _ring(kind, s), pts = ring.points, n = pts.length, mid = ring.cy;
    const w = wake === undefined ? 1 : Math.max(0, Math.min(1, wake));
    const slack = 1 + SLACK * (1 - w);
    // The ribbon lands on the flank it came down on: the hook's mouth is left
    // open there, facing the tentacle, and the tip comes back up the far side
    const a0 = Math.atan2(from[1] - cy - mid, from[0] - cx) + LAND * Math.PI / 180;
    let start = 0, best = Infinity;
    for (let i = 0; i < n; i++) {
        let d = Math.atan2(pts[i][1] - mid, pts[i][0]) - a0;
        while (d > Math.PI)
            d -= Math.PI * 2;
        while (d < -Math.PI)
            d += Math.PI * 2;
        if (Math.abs(d) < best) {
            best = Math.abs(d);
            start = i;
        }
    }
    // Down one flank, under the belly, back up the other
    const reach = Math.max(4, Math.round(n * (REACH + (REACH_ASLEEP - REACH) * (1 - w))));
    const out = [];
    for (let k = 0; k <= reach; k++) {
        const t = k / reach, q = pts[(start + k) % n];
        // The last stretch closes onto the body: it comes in by exactly the
        // clearance it was riding, which puts the tip against the outline. A
        // share of the radius instead would take a wide animal's tip deep
        // inside itself (P84).
        const shut = t < CLOSE_AT ? 0 : (t - CLOSE_AT) / (1 - CLOSE_AT) * w;
        // CLEAR is in the shape's own units and q is already scaled, so the
        // closing is too: otherwise the tip overshoots by the scale and ends
        // just inside the body it is holding. It also stops short of the
        // outline, because the inset runs along a radius and not along the
        // body's own normal — on a small animal (the squid) the full margin
        // would take the tip through it.
        const l = Math.hypot(q[0], q[1]) || 1, f = slack * (1 - CLEAR * s * SHUT * shut / l);
        out.push([cx + q[0] * f, cy + mid + (q[1] - mid) * f]);
    }
    return out;
}

// How many points at the end of a hook are the tip coming back up, the part
// drawn in front of the body
function tailCount(n) {
    return Math.max(2, Math.round(n * FRONT));
}

// What a creature of this kind, drawn at scale s, covers on screen: the box
// of its body and the box of its name. The layout test keeps everything else
// out of them, and a shoal's ring is drawn at scene size (School.qml).
function print(kind, s) {
    if (kind === "shoal")
        return { "hw": SHOAL.r, "hh": SHOAL.r, "cy": 0, "labelDY": 28, "labelH": Shapes.LABEL_H, "labelW": Shapes.LABEL_W };
    const b = Shapes.bounds(kind);
    return {
        "hw": b.hw * s, "hh": b.hh * s, "cy": b.cy * s,
        "labelDY": Shapes.LABEL_DY, "labelH": Shapes.LABEL_H, "labelW": Shapes.LABEL_W
    };
}

// A relay lantern (Lantern.qml): its coral, drawn around [x, y - 4]
function hubPrint() {
    return { "hw": 24, "hh": 22, "cy": -4, "labelDY": 20, "labelH": 20, "labelW": 90 };
}
