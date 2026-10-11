import QtQuick
import QtQuick.Window
import qs.Common
import "../../components/Shapes.js" as Shapes
import "../../components/Grips.js" as Grips
import "../../components/Ribbon.js" as Ribbon

// Design prototype for the jellyfish grab (NAK-335, D407): never shipped,
// never imported by the plugin. It draws three demo creatures (a lantern
// whale, a manta ray, a shoal) held by a tentacle, frame by frame, so the
// owner can compare today's hook ("before", the real Grips.js) with two
// embraces that coil around the body's girth: part of each turn passes in
// front of the animal and part behind it.
// Usage: qml-qt6 -I imports grab.qml -- <before|a|b> <dark|light> <anim|still> <out.png>
// anim writes out-0.png ... out-N.png, still writes the held pose only.
Window {
    id: win

    readonly property var args: Qt.application.arguments
    readonly property string variant: args[args.length - 4]
    readonly property string look: args[args.length - 3]
    readonly property bool still: args[args.length - 2] === "still"
    readonly property string out: args[args.length - 1]
    // One frame every 60 ms of scene time, 3.9 s in all
    readonly property real step: 0.06
    readonly property int frames: 65
    property int frame: 0
    readonly property real t: still ? 1.3 : frame * step

    // What each proposal asks the engineer to build
    readonly property var specs: ({
            "a": { "turns": 3, "span": 0.3, "tilt": 0.42, "amp": 0.55, "decay": 7, "freq": 13, "k": 90, "zeta": 0.4, "curl": 0 },
            "b": { "turns": 2, "span": 0.62, "tilt": 0.3, "amp": 0.4, "decay": 5, "freq": 9, "k": 60, "zeta": 0.35, "curl": 1 }
        })
    readonly property var cells: [
        { "kind": "vps", "name": "harbor-vps", "x": 120 },
        { "kind": "server", "name": "atlas-server", "x": 360 },
        { "kind": "shoal", "name": "4 phones", "x": 600 }
    ]
    readonly property real s: 1.5
    readonly property real cy: 118

    width: 720
    height: 250
    visible: true
    color: Theme.surface
    Component.onCompleted: Theme.isLightMode = look === "light"

    function smooth(x) {
        const c = Math.max(0, Math.min(1, x));
        return c * c * (3 - 2 * c);
    }

    function stateName() {
        if (still)
            return "Reduce motion: final pose, no movement";
        return t < 1.1 ? "Takes hold" : t < 1.5 ? "Held, at rest" : t < 2.1 ? "Dragged" : t < 2.75 ? "Released" : "Asleep: lets go";
    }

    // Where the user's drag has put the device at time t
    function dragAt(time) {
        if (time < 1.5)
            return [0, 0];
        if (time < 2.1) {
            const e = smooth((time - 1.5) / 0.55);
            return [38 * e, 20 * e];
        }
        const q = time - 2.1, e = Math.exp(-9 * q) * (1 + 9 * q);
        return [38 * e, 20 * e];
    }

    // How far the coil trails behind the device: a spring pulled by the
    // device, stepped from the start of the drag (the frames must not depend
    // on the wall clock)
    function lagAt(time, k, zeta) {
        let f = [0, 0], v = [0, 0];
        const dt = 1 / 240, c = 2 * zeta * Math.sqrt(k);
        for (let q = 1.5; q < time; q += dt) {
            const d = dragAt(q);
            for (let i = 0; i < 2; i++) {
                v[i] += (k * (d[i] - f[i]) - c * v[i]) * dt;
                f[i] += v[i] * dt;
            }
        }
        const d = dragAt(time);
        return time < 1.5 ? [0, 0] : [f[0] - d[0], f[1] - d[1]];
    }

    // The top and bottom of a body at this x, from its real outline
    function spanAt(kind, x) {
        if (kind === "shoal") {
            const r = 25, h = Math.sqrt(Math.max(0, r * r - x * x));
            return [-h, h];
        }
        const hull = Shapes.hull(kind);
        let lo = Infinity, hi = -Infinity;
        for (let i = 0; i < hull.length; i++) {
            const a = hull[i], b = hull[(i + 1) % hull.length];
            if ((a[0] - x) * (b[0] - x) > 0 || a[0] === b[0])
                continue;
            const y = a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]);
            lo = Math.min(lo, y);
            hi = Math.max(hi, y);
        }
        return lo === Infinity ? [0, 0] : [lo * s, hi * s];
    }

    function halfWidth(kind) {
        return kind === "shoal" ? 25 : Shapes.bounds(kind).hw * s;
    }

    // The embrace: a helix around the body's long axis, seen from the side.
    // Returns [{x, y, z}], z > 0 in front of the body.
    function coil(cell, sp, pos, from) {
        const hw = halfWidth(cell.kind), side = from[0] > pos[0] ? 1 : -1;
        const xa = side * sp.span * hw, xb = -xa;
        const tight = t - 0.55;
        // Loose while it reaches, then it tightens past the body and settles
        let slack = tight < 0 ? 1 + sp.amp : 1 + sp.amp * Math.exp(-sp.decay * tight) * Math.cos(sp.freq * tight);
        const wake = 1 - smooth((t - 2.75) / 0.9);
        slack *= 1 + 0.5 * (1 - wake);
        const reach = Math.min(1, 1 - Math.pow(1 - Math.min(1, t / 0.75), 3)) * (0.3 + 0.7 * wake);
        const lag = lagAt(t, sp.k, sp.zeta);
        const n = Math.round(40 * sp.turns), pts = [];
        for (let i = 0; i <= n * reach; i++) {
            const u = i / n, x = xa + (xb - xa) * u, th = -Math.PI / 2 + Math.PI * 2 * sp.turns * u;
            const sp2 = spanAt(cell.kind, x), mid = (sp2[0] + sp2[1]) / 2;
            const r = ((sp2[1] - sp2[0]) / 2 + 4) * slack, z = Math.cos(th), w = 0.3 + 0.7 * u;
            pts.push({
                "x": pos[0] + x + sp.tilt * r * z * side + lag[0] * w,
                "y": pos[1] + mid + r * Math.sin(th) + lag[1] * w + 16 * (1 - wake) * u * u,
                "z": z
            });
        }
        // B ends on a small curl resting on the flank, in front
        if (sp.curl && pts.length > 4 && reach >= 1) {
            const e = pts[pts.length - 1], g = 7 * slack;
            for (let j = 1; j <= 14; j++) {
                const a = -Math.PI / 2 + j / 14 * Math.PI * 1.6, rr = g * (1 - j / 20);
                pts.push({ "x": e.x - side * rr * Math.cos(a), "y": e.y + g + rr * Math.sin(a), "z": 1 });
            }
        }
        return pts;
    }

    // The free ribbon from the bell to where it meets the body: it hangs,
    // and its belly trails behind when the device moves
    function freeRibbon(from, to, lag) {
        const cx = (from[0] + to[0]) / 2 + lag[0] * 0.6 - 30, cyy = (from[1] + to[1]) / 2 + 26 + lag[1] * 0.6, pts = [];
        for (let i = 0; i <= 20; i++) {
            const u = i / 20, v = 1 - u;
            pts.push([v * v * from[0] + 2 * v * u * cx + u * u * to[0], v * v * from[1] + 2 * v * u * cyy + u * u * to[1]]);
        }
        return pts;
    }

    // Cuts the coil where it changes side, one ribbon per stretch
    function runs(pts, front) {
        const out = [];
        let cur = [];
        pts.forEach((q, i) => {
            if ((q.z > 0) === front) {
                // One point of overlap hides the seam between two stretches
                if (!cur.length && i > 0)
                    cur.push([pts[i - 1].x, pts[i - 1].y]);
                cur.push([q.x, q.y]);
            } else if (cur.length) {
                cur.push([q.x, q.y]);
                out.push(cur);
                cur = [];
            }
        });
        if (cur.length)
            out.push(cur);
        return out;
    }

    function drawBody(c, cell, pos, asleep) {
        c.save();
        c.translate(pos[0], pos[1]);
        if (cell.kind === "shoal") {
            [[-11, -8], [9, -10], [-6, 9], [12, 7]].forEach(q => {
                c.save();
                c.translate(q[0], q[1]);
                c.scale(0.34, 0.34);
                Shapes.draw(c, "laptop", Theme.tertiary, 0.4, asleep);
                c.restore();
            });
        } else {
            c.scale(s, s);
            Shapes.draw(c, cell.kind, Theme.tertiary, 0.4, asleep);
        }
        c.restore();
    }

    // grabToImage captures the content item, not the window's own colour
    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const asleep = win.t > 3.1, opts = { "warn": Theme.warning, "tail": false };
            win.cells.forEach(cell => {
                const d = win.dragAt(win.t), pos = [cell.x + d[0], win.cy + d[1]], from = [cell.x + 104, 6];
                const rib = pts => ({ "pts": pts, "color": Theme.primary, "level": 0.8, "width": 2.2, "tail": 0 });
                if (win.variant === "before") {
                    const wake = 1 - win.smooth((win.t - 2.75) / 0.9);
                    const hook = Grips.hold(cell.kind, cell.kind === "shoal" ? 1 : win.s, pos[0], pos[1], from, wake);
                    const all = win.freeRibbon(from, hook[0], [0, 0]).concat(hook);
                    const tent = [Object.assign(rib(all), { "tail": Grips.tailCount(hook.length) })];
                    const ext = Math.min(1, win.t / 0.75);
                    Ribbon.draw(c, tent, ext, opts);
                    win.drawBody(c, cell, pos, asleep);
                    Ribbon.draw(c, tent, ext, { "warn": Theme.warning, "tail": true });
                    return;
                }
                const sp = win.specs[win.variant], pts = win.coil(cell, sp, pos, from);
                const lag = win.lagAt(win.t, sp.k, sp.zeta);
                const back = win.runs(pts, false).map(rib);
                // The stretches behind the body are dimmer: depth by light
                back.forEach(r => r.level = 0.1);
                if (pts.length)
                    back.unshift(rib(win.freeRibbon(from, [pts[0].x, pts[0].y], lag)));
                Ribbon.draw(c, back, 1, opts);
                win.drawBody(c, cell, pos, asleep);
                Ribbon.draw(c, win.runs(pts, true).map(rib), 1, opts);
            });
        }
    }

    Repeater {
        model: win.cells

        Text {
            required property var modelData

            x: modelData.x - width / 2
            y: win.cy + 62
            text: modelData.name
            color: Theme.surfaceText
            font.pixelSize: 13
        }
    }

    Text {
        x: 16
        y: win.height - 28
        text: (win.variant === "before" ? "Before: the hook" : win.variant === "a" ? "A: tight coil" : "B: long embrace") + "  ·  " + win.stateName()
        color: Theme.surfaceVariantText
        font.pixelSize: 13
    }

    Timer {
        interval: 80
        running: true
        repeat: true
        onTriggered: {
            const n = win.frame;
            win.contentItem.grabToImage(r => {
                r.saveToFile(win.still ? win.out : win.out.replace(/\.png$/, "-" + n + ".png"));
                if (win.still || n >= win.frames - 1)
                    Qt.quit();
                win.frame = n + 1;
                canvas.requestPaint();
            });
        }
    }
}
