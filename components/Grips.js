.pragma library

// How a tentacle holds a creature (placeholder: being drawn).

// Where the tentacle meets the creature's grip, relative to its centre, for
// a creature of this kind drawn at scale s. Returns [dx, dy].
function anchor(kind, s) {
    return [0, -14 * s];
}
