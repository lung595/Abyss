// Bowl.js tests. Run from anywhere: gjs tests/bowl.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const B = load("components/Bowl.js");

const inside = (b, x, y) => ((x - b.cx) / b.rx) ** 2 + ((y - b.cy) / b.ry) ** 2 <= 1.0001;

[[680, 540], [340, 280], [1200, 500], [400, 900]].forEach(([w, h]) => {
    const b = B.build(w, h, 54), s = b.scene;
    ok(w + "×" + h + ": the bowl fits the widget", b.cx - b.rx >= 0 && b.cx + b.rx <= w && b.rimY >= 0 && b.baseY <= h);
    ok(w + "×" + h + ": rim, surface, gravel, base from top to bottom", b.rimY < b.surfaceY && b.surfaceY < b.gravelY && b.gravelY < b.baseY);
    // The scene's bottom corners must stay behind the glass
    ok(w + "×" + h + ": the scene's bottom corners are inside the glass", inside(b, s.x, s.y + s.h) && inside(b, s.x + s.w, s.y + s.h));
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
