import QtQuick
import qs.Common

// Every tentacle, and the threads from caves to the peer that opens them.
// A tentacle is a line of light: a thread for everyday use, a few pixels for
// the heaviest (Layout.ribbonWidth), brighter with traffic. The waves running
// along it (in: download, out: upload) are separate items moved by the scene clock;
// this canvas is only repainted when the traffic is read (once a second
// while watched), while tentacles grow, or while the lens moves them.
Canvas {
    id: canvas

    property var scene
    // [{pts, color, level, down, up, dashed, warn}] (levels 0..1)
    property var tents: []
    // [{pts, color}]
    property var threads: []
    // 0..1: how far tentacles have grown out of the bell
    property real ext: 1

    onTentsChanged: requestPaint()
    onThreadsChanged: requestPaint()
    onExtChanged: requestPaint()

    // The polyline shifted sideways by d (negative = left of the direction)
    function _offset(pts, d) {
        return pts.map((q, i) => {
            const a = pts[Math.max(0, i - 1)], b = pts[Math.min(pts.length - 1, i + 1)];
            const dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy) || 1;
            return [q[0] - dy / L * d, q[1] + dx / L * d];
        });
    }

    function _path(c, pts) {
        c.beginPath();
        for (let i = 0; i < pts.length; i++)
            i ? c.lineTo(pts[i][0], pts[i][1]) : c.moveTo(pts[i][0], pts[i][1]);
    }

    onPaint: {
        const c = getContext("2d");
        c.reset();
        if (ext <= 0.01)
            return;
        c.lineCap = "round";
        c.lineJoin = "round";
        threads.forEach(th => {
            _path(c, th.pts);
            c.setLineDash([2, 6]);
            c.strokeStyle = Qt.rgba(th.color.r, th.color.g, th.color.b, 0.55 * ext);
            c.lineWidth = 1.4;
            c.stroke();
        });
        c.setLineDash([]);
        tents.forEach(tn => {
            const n = Math.max(2, Math.round(tn.pts.length * Math.min(1, ext)));
            const pts = tn.pts.slice(0, n);
            const col = tn.warn ? Theme.warning : tn.color, lv = tn.level;
            const w = tn.width;
            if (tn.dashed)
                c.setLineDash([4, 7]);
            // A faint halo, then the line itself, brighter with traffic
            _path(c, pts);
            c.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.03 + 0.07 * lv);
            c.lineWidth = w * 1.6 + 3;
            c.stroke();
            _path(c, pts);
            c.strokeStyle = Qt.rgba(col.r, col.g, col.b, tn.warn ? 0.6 : 0.35 + 0.5 * lv);
            c.lineWidth = w;
            c.stroke();
            c.setLineDash([]);
        });
    }
}
