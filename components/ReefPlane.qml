import QtQuick
import "ReefPaint.js" as Paint

// One plane of the reef (far ridge, middle ridge, a cliff, the floor), painted
// once into a band of the scene; it only slides sideways with the lens, the
// far planes less than the near ones (parallax).
Canvas {
    id: plane

    property string part
    property var frame
    property var plan
    property var pal
    // Where the band sits in the scene; it paints what falls inside
    property real baseX: 0
    property real baseY: 0
    // How far the plane slides (px) when the lens is at the scene's edge
    property real depth: 0
    // Where the lens is, from -1 (left edge) to 1 (right edge)
    property real drift: 0

    x: baseX - drift * depth
    y: baseY

    onPlanChanged: requestPaint()
    onPalChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (!plan || !pal)
            return;
        ctx.translate(-baseX, -baseY);
        Paint.paintPart(part, ctx, frame, plan, pal);
    }
}
