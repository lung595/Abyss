import QtQuick
import qs.Common

// Every tentacle, and the threads from caves to the peer that opens them.
// A tentacle's width and brightness are its peer's traffic. Repainted when
// the traffic is read (once a second while watched) or while tentacles grow.
Canvas {
    id: canvas

    property var scene
    // [{pts, color, level, dashed, warn}]
    property var tents: []
    // [{pts, color}]
    property var threads: []
    // 0..1: how far tentacles have grown out of the bell
    property real ext: 1

    onTentsChanged: requestPaint()
    onThreadsChanged: requestPaint()
    onExtChanged: requestPaint()

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
            const w = 1 + 6 * lv * lv + 1.2 * lv;
            if (tn.dashed)
                c.setLineDash([4, 7]);
            _path(c, pts);
            c.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.05 + 0.1 * lv);
            c.lineWidth = w * 4 + 5;
            c.stroke();
            _path(c, pts);
            c.strokeStyle = Qt.rgba(col.r, col.g, col.b, tn.warn ? 0.55 : 0.3 + 0.55 * lv);
            c.lineWidth = w;
            c.stroke();
            c.setLineDash([]);
        });
    }
}
