.pragma library

// The "grab the file" scene, as numbers. A file appears, a tentacle of the
// creature reaches it, carries it over and the file drops in; then the send
// shows its progress. One motion for every way of sending (a drop, the
// menu, Ctrl+V, the launcher), so GrabFile.qml only turns time into this.
// Pure: t is 0..1 over DURATION, the points are scene coordinates.

const DURATION = 900;
// How long the creature's light blooms once a send has gone through
const BLOOM = 700;

// Phase edges, as fractions of DURATION: appear, grab, carry, drop in
const _APPEAR = 0.2, _GRAB = 0.4, _CARRY = 0.85;

function _clamp(v) {
    return Math.max(0, Math.min(1, v));
}

function _ease(k) {
    return k * k * (3 - 2 * k);
}

// { x, y, scale, opacity, reach, phase } at t. reach is how far the tentacle
// has gone toward the file (0 in the creature, 1 holding it).
function pose(t, from, to) {
    const k = _clamp(t);
    if (k < _APPEAR) {
        const a = _ease(k / _APPEAR);
        return { "x": from.x, "y": from.y, "scale": 0.6 + 0.4 * a, "opacity": a, "reach": 0, "phase": "appear" };
    }
    if (k < _GRAB) {
        const g = _ease((k - _APPEAR) / (_GRAB - _APPEAR));
        // The file bobs up a little as it is caught
        return { "x": from.x, "y": from.y, "scale": 1 + 0.08 * Math.sin(Math.PI * g), "opacity": 1, "reach": g, "phase": "grab" };
    }
    if (k < _CARRY) {
        const c = _ease((k - _GRAB) / (_CARRY - _GRAB));
        // An arc, not a line: it is lifted over the water on the way
        const lift = -0.15 * Math.hypot(to.x - from.x, to.y - from.y) * Math.sin(Math.PI * c);
        return { "x": from.x + (to.x - from.x) * c, "y": from.y + (to.y - from.y) * c + lift, "scale": 1, "opacity": 1, "reach": 1, "phase": "carry" };
    }
    const d = _ease((k - _CARRY) / (1 - _CARRY));
    return { "x": to.x, "y": to.y, "scale": 1 - 0.85 * d, "opacity": 1 - d, "reach": 1 - d, "phase": "drop" };
}

// The tentacle's tip: from the creature toward the file as far as reach
function tip(creature, file, reach) {
    return { "x": creature.x + (file.x - creature.x) * reach, "y": creature.y + (file.y - creature.y) * reach };
}

// Where the file appears: a spot beside the creature, kept inside the scene.
// size: { w, h } of the scene.
function startPoint(target, size) {
    const at = { "x": target.x - 110, "y": target.y - 90 };
    return { "x": Math.max(24, Math.min(size.w - 24, at.x)), "y": Math.max(24, Math.min(size.h - 24, at.y)) };
}

// 0..1..0 over BLOOM: the light of a creature that has just received
// something. t is 0..1 over BLOOM; outside it there is no light.
function bloom(t) {
    return t <= 0 || t >= 1 ? 0 : Math.sin(Math.PI * t);
}
