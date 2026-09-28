.pragma library

// How a ribbon of light is drawn, shared by the two canvases that carry the
// tentacles: Tentacles.qml behind the creatures, Grip.qml in front of them
// for the tail that closes under the belly. One place, so the two halves can
// never drift apart in thickness, colour or dash.

// ctx: a canvas 2d context already reset by the caller
// ribbons: [{pts, color, level, width, dashed, warn, tail}] (level 0..1)
// ext: 0..1, how far the tentacles have grown out of the bell
// opts: {warn, tail} — the warning colour, and true to draw only the tail
// (the points Grips.js counted as the closing part of the wrap)
function draw(ctx, ribbons, ext, opts) {
    if (ext <= 0.01)
        return;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ribbons.forEach(tn => {
        const grown = Math.max(2, Math.round(tn.pts.length * Math.min(1, ext)));
        const tail = tn.tail || 0;
        // Each half draws its own share: the canvas behind the bodies takes
        // the ride and stops where the tail starts, the one in front takes
        // the tail. Drawn twice, the crossing would read as a bright knot
        const from = opts.tail ? Math.max(0, tn.pts.length - tail) : 0;
        const to = opts.tail ? grown : Math.max(from, grown - tail);
        const pts = tn.pts.slice(from, to);
        if (pts.length < 2)
            return;
        const col = tn.warn ? opts.warn : tn.color, lv = tn.level, w = tn.width;
        if (tn.dashed)
            ctx.setLineDash([4, 7]);
        // A faint halo, then the line itself, brighter with traffic
        path(ctx, pts);
        ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.03 + 0.07 * lv);
        ctx.lineWidth = w * 1.6 + 3;
        ctx.stroke();
        path(ctx, pts);
        ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, tn.warn ? 0.6 : 0.35 + 0.5 * lv);
        ctx.lineWidth = w;
        ctx.stroke();
        ctx.setLineDash([]);
    });
}

function path(ctx, pts) {
    ctx.beginPath();
    for (let i = 0; i < pts.length; i++)
        i ? ctx.lineTo(pts[i][0], pts[i][1]) : ctx.moveTo(pts[i][0], pts[i][1]);
}
