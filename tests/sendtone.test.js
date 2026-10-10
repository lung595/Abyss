// SendTone.js tests. Run from anywhere: gjs tests/sendtone.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, ok, done } = imports.load;
const T = load("components/SendTone.js");

const hex = h => ({ r: parseInt(h.slice(1, 3), 16) / 255, g: parseInt(h.slice(3, 5), 16) / 255, b: parseInt(h.slice(5, 7), 16) / 255 });
const night = hex("#02040b");
// The menu background is the abyss: the primary sunk 94 % into the night
const abyss = p => T.mix(p, night, 0.94);
const near = (a, b, tol) => Math.abs(a - b) <= tol;

// The three theme primaries of the NAK-277 spec, with its contrast figures
const cases = [
    ["dark", "#d0bcff", 11.17, false],
    ["light", "#6750a4", 7.35, true],
    ["wallpaper", "#ffb95c", 11.23, false],
];
for (const [name, h, want, lifted] of cases) {
    const p = hex(h), t = T.sendTone(p);
    ok(name + ": " + (lifted ? "lifted with white" : "raw role kept"), (t === p) === !lifted);
    ok(name + ": contrast on the menu is " + want + " (±0.3)", near(T.contrast(t, abyss(p)), want, 0.3));
    ok(name + ": reads at 7:1 or more", T.contrast(t, abyss(p)) >= 7);
}

// Both sides of the 0.32 threshold
const grey = v => ({ r: v, g: v, b: v });
let lo = 0, hi = 1;
for (let i = 0; i < 30; i++) {
    const m = (lo + hi) / 2;
    if (T.luminance(grey(m)) < 0.32) lo = m; else hi = m;
}
ok("just under the threshold: lifted", T.sendTone(grey(lo - 0.01)).r > lo - 0.01);
ok("just over the threshold: kept", T.sendTone(grey(hi + 0.01)).r === hi + 0.01);
ok("black is lifted by exactly 40 % white", near(T.sendTone(grey(0)).r, 0.4, 1e-9));
ok("white luminance is 1", near(T.luminance(grey(1)), 1, 1e-9));
done("SendTone");
