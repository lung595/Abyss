import QtQuick
import qs.Common

// A peer's last minute of traffic: download filled in the peer's colour,
// upload dashed in yours (upColor), as the card's rates above it.
Canvas {
    id: spark

    // [[down, up], ...] in bits per second, oldest first
    property var points: []
    property color color: Theme.primary
    property color ink: "white"
    property color upColor: Theme.tertiary

    onPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onColorChanged: requestPaint()
    onUpColorChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const w = width, h = height, pts = points || [];
        c.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, 0.08);
        c.lineWidth = 1;
        for (let k = 1; k < 4; k++) {
            c.beginPath();
            c.moveTo(0, h * k / 4);
            c.lineTo(w, h * k / 4);
            c.stroke();
        }
        if (pts.length < 2)
            return;
        const max = Math.max(1000, ...pts.map(p => p[0] + p[1])) * 1.15;
        const X = i => w - (pts.length - 1 - i) * w / 59;
        const Y = v => h - v / max * (h - 4);
        c.beginPath();
        c.moveTo(X(0), h);
        pts.forEach((p, i) => c.lineTo(X(i), Y(p[0])));
        c.lineTo(X(pts.length - 1), h);
        c.closePath();
        const g = c.createLinearGradient(0, 0, 0, h);
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.5));
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.04));
        c.fillStyle = g;
        c.fill();
        c.beginPath();
        pts.forEach((p, i) => i ? c.lineTo(X(i), Y(p[0])) : c.moveTo(X(i), Y(p[0])));
        c.strokeStyle = color;
        c.lineWidth = 1.8;
        c.stroke();
        c.beginPath();
        pts.forEach((p, i) => i ? c.lineTo(X(i), Y(p[1])) : c.moveTo(X(i), Y(p[1])));
        c.setLineDash([4, 3]);
        c.strokeStyle = Qt.rgba(upColor.r, upColor.g, upColor.b, 0.85);
        c.lineWidth = 1.2;
        c.stroke();
    }
}
