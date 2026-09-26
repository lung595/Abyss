import QtQuick

// The bar's tiny jellyfish: a bell and three tentacles, one colour.
// Painted once; repainted only when its colour or size changes.
Canvas {
    id: glyph

    property color color: "white"
    // Thin dashed tentacles: not connected
    property bool asleep: false

    width: 18
    height: 18
    onColorChanged: requestPaint()
    onAsleepChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height;
        ctx.reset();
        ctx.fillStyle = color;
        ctx.strokeStyle = color;
        ctx.lineCap = "round";
        // Bell: a half dome with a wavy hem
        ctx.beginPath();
        ctx.moveTo(w * 0.12, h * 0.5);
        ctx.bezierCurveTo(w * 0.12, h * 0.08, w * 0.88, h * 0.08, w * 0.88, h * 0.5);
        ctx.quadraticCurveTo(w * 0.75, h * 0.42, w * 0.62, h * 0.5);
        ctx.quadraticCurveTo(w * 0.5, h * 0.42, w * 0.38, h * 0.5);
        ctx.quadraticCurveTo(w * 0.25, h * 0.42, w * 0.12, h * 0.5);
        ctx.fill();
        // Tentacles
        ctx.lineWidth = Math.max(1, w * 0.08);
        if (asleep)
            ctx.setLineDash([1.2, 1.6]);
        [0.3, 0.5, 0.7].forEach((x, i) => {
            ctx.beginPath();
            ctx.moveTo(w * x, h * 0.54);
            ctx.quadraticCurveTo(w * (x + (i === 1 ? 0 : (x < 0.5 ? -0.08 : 0.08))), h * 0.74, w * x, h * 0.94);
            ctx.stroke();
        });
    }
}
