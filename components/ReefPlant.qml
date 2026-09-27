import QtQuick
import "ReefPlan.js" as Plan
import "ReefPaint.js" as Paint

// One living thing of the reef, painted once; the current only turns it
// around its foot (a cheap transform, no repaint).
Canvas {
    id: plant

    property var it
    property var pal
    // The scene clock (s) and whether the deep flows (else it stands still)
    property real t: 0
    property bool live: false
    // Sideways slide of its plane (parallax)
    property real shift: 0

    width: 64 * it.s
    height: 50 * it.s
    x: it.x - width / 2 + shift
    y: it.y - height
    transformOrigin: Item.Bottom
    rotation: live ? Plan.swayAt(it, t) : 0
    antialiasing: true

    onPalChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (!pal)
            return;
        ctx.translate(width / 2, height);
        Paint.paintLife(ctx, it, pal);
    }
}
