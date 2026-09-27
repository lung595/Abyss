import QtQuick

// A soft round glow, painted once per colour; its brightness is the item's
// opacity (cheap to change).
Canvas {
    id: halo

    property color color: "white"
    property real strength: 0.6

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        // An oval filling the item, so a box wider than tall never cuts it
        const r = width / 2;
        c.translate(r, height / 2);
        c.scale(1, height / width);
        const g = c.createRadialGradient(0, 0, 0, 0, 0, r);
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, strength));
        g.addColorStop(0.45, Qt.rgba(color.r, color.g, color.b, strength * 0.35));
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
        c.fillStyle = g;
        c.fillRect(-r, -r, width, width);
    }
}
