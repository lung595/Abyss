pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import "Layout.js" as Lay

// You: a giant jellyfish just below the surface. Two bells, each painted
// once (lit and asleep), crossfade as it wakes or falls asleep, so switching
// is a slow glow and never a jump. Its loose threads hang from the rim; each
// peer it reaches takes one over (the real tentacle leaves from that slot).
// All motion (breathing, swaying) comes from the scene's swim phase: frozen
// when nothing runs, so nothing moves here at rest.
Item {
    id: jelly

    property var scene
    property real r: 60
    property color tint: Theme.tertiary
    property color tint2: Theme.primary
    // 0 (asleep) .. 1 (connected)
    property real lit: 1
    // The scene's swimming phase (see AbyssScene.swim)
    property real phase: 0
    // Rim slots (0 .. Lay.LEGS - 1) where a real tentacle leaves the bell
    property var taken: []

    // Breathing: a slow swell of the bell, deeper when awake. The phase only
    // moves while the scene runs, so this never snaps back.
    readonly property real breath: 1 + (0.012 + 0.016 * lit) * Math.sin(phase * 1.5)
    // The bell swells from its top: where a point below it goes (y from the centre)
    readonly property real _top: -r * 1.1

    width: 0
    height: 0

    // The bell in one look: g = 0 asleep .. 1 lit, t1/t2 its two tints
    function paintBell(c, w, g, t1, t2) {
        const R = r, cx = w / 2, cy = R * 1.1;
        const a = (col, al) => Qt.rgba(col.r, col.g, col.b, al);
        c.reset();
        c.beginPath();
        c.moveTo(cx - R, cy + 6);
        c.bezierCurveTo(cx - R, cy - R * 1.05, cx + R, cy - R * 1.05, cx + R, cy + 6);
        for (let k = 8; k >= 1; k--) {
            const px = cx - R + k * (2 * R / 8);
            c.quadraticCurveTo(px - R / 8, cy + 18, px - R / 4, cy + 6);
        }
        const bell = c.createRadialGradient(cx - R * 0.25, cy - R * 0.55, 4, cx, cy - R * 0.1, R * 1.15);
        bell.addColorStop(0, a(Qt.lighter(t1, 1.6), 0.3 + 0.45 * g));
        bell.addColorStop(0.6, a(t1, 0.12 + 0.3 * g));
        bell.addColorStop(1, a(t2, 0.05 + 0.15 * g));
        c.fillStyle = bell;
        c.fill();
        c.strokeStyle = a(Qt.lighter(t1, 1.4), 0.3 + 0.55 * g);
        c.lineWidth = 1.5;
        c.stroke();
        // Four gonads, the jellyfish's signature, and a lit rim
        for (let k = 0; k < 4; k++) {
            const ang = k / 4 * Math.PI * 2 + 0.4;
            c.beginPath();
            c.ellipse(cx + Math.cos(ang) * R * 0.27 - R * 0.16, cy - R * 0.36 + Math.sin(ang) * R * 0.12 - R * 0.08, R * 0.32, R * 0.16);
            c.strokeStyle = a(Qt.lighter(t2, 1.3), 0.25 + 0.55 * g);
            c.lineWidth = 2;
            c.stroke();
        }
        for (let k = 0; k <= 16; k++) {
            c.fillStyle = a(Qt.lighter(t1, 1.5), (0.2 + 0.8 * g) * (0.6 + 0.4 * Math.sin(k * 1.7)));
            c.beginPath();
            c.arc(cx - R + k * (2 * R / 16), cy + 10, 1.8, 0, Math.PI * 2);
            c.fill();
        }
    }

    Halo {
        width: jelly.r * 5
        height: width
        x: -width / 2
        y: -width / 2
        color: jelly.tint
        strength: 0.4
        opacity: 0.15 + 0.85 * jelly.lit
    }

    // Loose threads, behind the bell: lines of light hooked to nothing. A
    // slot held by a real tentacle fades its thread out: the tentacle leaving
    // from that very point takes its place.
    Repeater {
        model: Lay.LEGS

        Item {
            id: leg

            required property int index
            readonly property var at: Lay.legPoint({
                "x": 0,
                "y": 0,
                "r": jelly.r
            }, index)
            // Centre threads hang longest, like a real bell's; a small
            // per-slot offset keeps them from looking combed
            readonly property real len: jelly.r * (2.0 - 0.9 * Math.abs(index - (Lay.LEGS - 1) / 2) / ((Lay.LEGS - 1) / 2) + 0.1 * Math.sin(index * 2.7))

            // Rides the rim as the bell breathes, so it never detaches
            x: at[0] * jelly.breath
            y: jelly._top + (at[1] - jelly._top) * jelly.breath
            opacity: jelly.taken.indexOf(index) >= 0 ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: jelly.scene && jelly.scene.reduceMotion ? 0 : 500
                    easing.type: Easing.InOutQuad
                }
            }

            Canvas {
                id: thread
                width: 24
                height: leg.len + 4
                x: -width / 2
                transformOrigin: Item.Top
                // Sways around its top, wider when awake
                rotation: Math.sin(jelly.phase * 0.8 + leg.index * 1.3) * (1.5 + 3 * jelly.lit)
                // Dimmer asleep, never gone
                opacity: 0.4 + 0.6 * jelly.lit
                onHeightChanged: requestPaint()
                Connections {
                    target: jelly
                    function onTintChanged() {
                        thread.requestPaint();
                    }
                }

                onPaint: {
                    const c = getContext("2d");
                    c.reset();
                    const col = Qt.lighter(jelly.tint, 1.35), L = leg.len, cx = width / 2;
                    // A gentle S, mirrored every other slot
                    const s = (leg.index % 2 ? 1 : -1) * Math.min(7, L * 0.07);
                    const fade = (al) => {
                        const g = c.createLinearGradient(0, 0, 0, L);
                        g.addColorStop(0, Qt.rgba(col.r, col.g, col.b, al));
                        g.addColorStop(0.55, Qt.rgba(col.r, col.g, col.b, al * 0.55));
                        g.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0));
                        return g;
                    };
                    const path = () => {
                        c.beginPath();
                        c.moveTo(cx, 0);
                        c.bezierCurveTo(cx + s, L * 0.33, cx - s, L * 0.66, cx + s * 0.4, L);
                    };
                    c.lineCap = "round";
                    // A faint halo, then the thread itself
                    path();
                    c.strokeStyle = fade(0.1);
                    c.lineWidth = 4;
                    c.stroke();
                    path();
                    c.strokeStyle = fade(0.7);
                    c.lineWidth = 1.2;
                    c.stroke();
                }
            }
        }
    }

    // The bell: both looks breathe together from their top
    Item {
        id: bellBox
        scale: jelly.breath
        transformOrigin: Item.Top
        x: -bellLit.width / 2
        y: jelly._top
        width: bellLit.width
        height: bellLit.height

        Canvas {
            id: bellAsleep
            width: jelly.r * 2.3
            height: jelly.r * 1.1 + 24
            opacity: 1 - jelly.lit
            onWidthChanged: requestPaint()
            onPaint: {
                // Asleep, the bell greys toward the sleeping colour
                const s = jelly.scene;
                const t1 = s ? s.mix(jelly.tint, s.sleepColor, 0.55) : jelly.tint;
                const t2 = s ? s.mix(jelly.tint2, s.sleepColor, 0.55) : jelly.tint2;
                jelly.paintBell(getContext("2d"), width, 0.08, t1, t2);
            }
        }
        Canvas {
            id: bellLit
            width: jelly.r * 2.3
            height: jelly.r * 1.1 + 24
            opacity: jelly.lit
            onWidthChanged: requestPaint()
            onPaint: jelly.paintBell(getContext("2d"), width, 1, jelly.tint, jelly.tint2)
        }
        Connections {
            target: jelly
            function onTintChanged() {
                bellLit.requestPaint();
                bellAsleep.requestPaint();
            }
            function onTint2Changed() {
                bellLit.requestPaint();
                bellAsleep.requestPaint();
            }
        }
        Connections {
            target: jelly.scene
            function onSleepColorChanged() {
                bellAsleep.requestPaint();
            }
        }
    }
}
