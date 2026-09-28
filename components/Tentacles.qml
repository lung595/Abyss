import QtQuick
import qs.Common
import "Ribbon.js" as Ribbon

// Every tentacle, and the threads from caves to the peer that opens them.
// Drawn behind the creatures (AbyssScene puts it before them), so a tentacle
// that grips a body passes behind it; the tail that closes under the belly
// is drawn again in front, by Grip.qml.
// A tentacle is a line of light: a thread for everyday use, a few pixels for
// the heaviest (Layout.ribbonWidth), brighter with traffic. The waves running
// along it (in: download, out: upload) are separate items moved by the scene
// clock; this canvas is only repainted when the traffic is read (once a second
// while watched), while tentacles grow, or while the lens moves them.
Canvas {
    id: canvas

    property var scene
    // [{pts, color, level, down, up, dashed, warn, tail}] (levels 0..1)
    property var tents: []
    // [{pts, color}]
    property var threads: []
    // 0..1: how far tentacles have grown out of the bell
    property real ext: 1

    onTentsChanged: requestPaint()
    onThreadsChanged: requestPaint()
    onExtChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        if (ext <= 0.01)
            return;
        c.lineCap = "round";
        c.lineJoin = "round";
        threads.forEach(th => {
            Ribbon.path(c, th.pts);
            c.setLineDash([2, 6]);
            c.strokeStyle = Qt.rgba(th.color.r, th.color.g, th.color.b, 0.55 * ext);
            c.lineWidth = 1.4;
            c.stroke();
        });
        c.setLineDash([]);
        Ribbon.draw(c, tents, ext, { "warn": Theme.warning, "tail": false });
    }
}
