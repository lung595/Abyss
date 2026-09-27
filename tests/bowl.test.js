// Bowl.js tests. Run from anywhere: gjs tests/bowl.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const B = load("components/Bowl.js");
const L = load("components/Layout.js");

const inside = (b, x, y) => ((x - b.cx) / b.rx) ** 2 + ((y - b.cy) / b.ry) ** 2 <= 1.0001;

[[680, 540], [340, 280], [1200, 500], [400, 900]].forEach(([w, h]) => {
    const b = B.build(w, h, 54), s = b.scene;
    ok(w + "×" + h + ": the bowl fits the widget", b.cx - b.rx >= 0 && b.cx + b.rx <= w && b.rimY >= 0 && b.baseY <= h);
    ok(w + "×" + h + ": rim, surface, gravel, base from top to bottom", b.rimY < b.surfaceY && b.surfaceY < b.gravelY && b.gravelY < b.baseY);
    // The scene is as wide as the bowl's belly; what sits at the surface and
    // on the gravel keeps its inset, so its ends stay behind the glass
    ok(w + "×" + h + ": the floor's ends are inside the glass", inside(b, s.x + s.insetFloor, b.gravelY - 20) && inside(b, s.x + s.w - s.insetFloor, b.gravelY - 20));
    ok(w + "×" + h + ": the surface's ends are inside the glass", inside(b, s.x + s.insetTop, b.surfaceY) && inside(b, s.x + s.w - s.insetTop, b.surfaceY));
    ok(w + "×" + h + ": the scene spans the bowl's belly", s.w >= 1.85 * b.rx);
    // Every spot of the fan, with its label's half width (44 px) either
    // side, is behind the glass: the peers use the whole belly, safely
    const f = L.frame(s.w, s.h, 54, { "top": s.insetTop, "floor": s.insetFloor });
    const fanIn = [0, 1, 2].every(k => {
        for (let d = 90 - L.HALF_SPAN; d <= 90 + L.HALF_SPAN; d += 5) {
            const q = L.fanPoint(f, d, f.fan.rings[k]), x = s.x + q.x, y = s.y + q.y;
            if (!inside(b, x - 44, y) || !inside(b, x + 44, y))
                return false;
        }
        return true;
    });
    ok(w + "×" + h + ": every spot of the fan is behind the glass", fanIn);
    // The first cave's rock (Cave.qml: 56 px either side, its foot 12 px
    // under the floor line) and the last sleeper (30 px either side)
    const foot = s.y + f.floorY + 12;
    ok(w + "×" + h + ": the first cave is behind the glass", inside(b, s.x + L.caveX(f, 0) - 56, foot));
    ok(w + "×" + h + ": the last sleeper is behind the glass", inside(b, s.x + s.w - s.insetFloor - 60 + 30, s.y + f.floorY - 30));
    ok(w + "×" + h + ": the scene's surface is the water's", Math.abs(s.y + 54 - b.surfaceY) < 0.01);
    // Layout.frame: floorY = h - max(34, 9 % h)
    const floor = s.y + s.h - Math.max(34, s.h * 0.09);
    ok(w + "×" + h + ": the scene's floor lies on the gravel", floor >= b.gravelY - 1 && floor <= b.gravelY + 12);
    ok(w + "×" + h + ": the water outline never rises above its surface", b.water.every(q => q[1] >= b.surfaceY - 0.01));
    ok(w + "×" + h + ": no outline point goes below the base", b.outline.every(q => q[1] <= b.baseY + 0.01));
});
const a = B.build(680, 540, 54);
eq("the same size gives the same bowl", a, B.build(680, 540, 54));
ok("the outline is closed round the bottom: it starts on the right, ends on the left", a.outline[0][0] > a.cx && a.outline[a.outline.length - 1][0] < a.cx);
ok("the rim is narrower than the water's surface", a.rim.rx < a.surface.rx);

done("bowl");
