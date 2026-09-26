import QtQuick

// A soft round glow, painted once per colour; its brightness is the item's
// opacity (cheap to change).
Canvas {
    id: halo

    property color color: "white"
    property real strength: 0.6

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const r = width / 2;
        const g = c.createRadialGradient(r, r, 0, r, r, r);
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, strength));
        g.addColorStop(0.45, Qt.rgba(color.r, color.g, color.b, strength * 0.35));
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
        c.fillStyle = g;
        c.fillRect(0, 0, width, height);
    }
}
