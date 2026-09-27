pragma ComponentBehavior: Bound
import QtQuick
import "ReefPlan.js" as Plan

// Now and then a small school crosses the deep, each on its own rhythm and at
// a new depth every pass. Positions come from the scene clock alone: no timer
// here, nothing moves unless the deep already flows.
Item {
    id: fish

    property var frame
    // The scene clock (seconds); it only runs while someone watches
    property real t: 0
    // Only while the deep flows
    property bool live: false
    property bool lit: false
    property color body
    // Sideways slide of the plane (parallax)
    property real shift: 0

    // Two schools: how often they come (s), how long a crossing lasts (s),
    // how many fish, their size, and a start offset so they rarely meet
    readonly property var schools: [
        { "period": 23, "cross": 15, "count": 6, "size": 1, "phase": 4 },
        { "period": 37, "cross": 22, "count": 4, "size": 1.5, "phase": 17 }
    ]
    readonly property var members: {
        const out = [];
        schools.forEach((s, k) => {
            const r = Plan.rng(101 + k);
            for (let i = 0; i < s.count; i++)
                out.push({ "school": k, "i": i, "dx": i * 11 + r() * 8, "dy": (r() - 0.5) * 16 });
        });
        return out;
    }

    visible: live && !!frame

    Repeater {
        model: fish.members

        Canvas {
            id: one
            required property var modelData
            readonly property var sc: fish.schools[modelData.school]
            readonly property real clock: fish.t + sc.phase
            readonly property int pass: Math.floor(clock / sc.period)
            readonly property real u: (clock - pass * sc.period) / sc.cross
            readonly property int dir: pass % 2 ? -1 : 1
            // A new depth each pass, in the lower half of the water
            readonly property real lane: {
                const f = fish.frame, top = f.surfaceY + (f.floorY - f.surfaceY) * 0.45;
                return top + Plan.rng(pass * 31 + modelData.school * 7 + 3)() * (f.floorY - 26 - top);
            }
            readonly property real run: (fish.frame ? fish.frame.w : 0) + 140

            visible: u >= 0 && u <= 1
            width: 14 * sc.size
            height: 7 * sc.size
            x: (dir > 0 ? -70 + u * run - modelData.dx : run - 70 - u * run + modelData.dx) + fish.shift
            y: lane + modelData.dy + Math.sin(fish.t * 1.4 + modelData.i) * 1.5
            rotation: Math.sin(fish.t * 7 + modelData.i * 1.7) * 3
            transform: Scale {
                origin.x: one.width / 2
                xScale: one.dir
            }

            onPaint: {
                const c = getContext("2d"), w = width, h = height;
                c.reset();
                c.fillStyle = Qt.rgba(fish.body.r, fish.body.g, fish.body.b, fish.lit ? 0.5 : 0.9);
                c.beginPath();
                c.ellipse(w * 0.22, h * 0.18, w * 0.7, h * 0.64);
                c.fill();
                c.beginPath();
                c.moveTo(w * 0.3, h / 2);
                c.lineTo(0, h * 0.1);
                c.lineTo(0, h * 0.9);
                c.closePath();
                c.fill();
            }
            Connections {
                target: fish
                function onBodyChanged() {
                    one.requestPaint();
                }
            }
        }
    }
}
