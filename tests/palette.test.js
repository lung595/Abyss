// Palette.js tests: every role in both schemes, and the contrast pairs of the
// design spec, computed here (WCAG 2.x), not copied.
// Run from anywhere: gjs tests/palette.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const P = load("app/components/Palette.js");

const ROLES = ["surface", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
    "surfaceContainerHigh", "surfaceContainerHighest", "onSurface", "onSurfaceVariant",
    "outline", "outlineStrong", "primary", "onPrimary", "secondary", "onSecondary",
    "tertiary", "success", "warning", "error", "data4"];

const channel = v => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
};
const luminance = hex => {
    const [r, g, b] = [1, 3, 5].map(i => channel(parseInt(hex.substr(i, 2), 16)));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const contrast = (a, b) => {
    const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
    return (hi + 0.05) / (lo + 0.05);
};

for (const [name, light] of [["dark", false], ["light", true]]) {
    const c = P.colors(light);
    for (const role of ROLES)
        ok(name + " has " + role, /^#[0-9a-f]{6}$/.test(c[role] || ""));
    eq(name + " has no extra role", Object.keys(c).length, ROLES.length);
    eq(name + " outlineStrong is onSurfaceVariant", c.outlineStrong, c.onSurfaceVariant);

    // Text pairs: at least 4.5:1 (the primary, secondary... accents on the base surface)
    const text = [["onSurface", "surface"], ["onSurface", "surfaceContainerHighest"],
        ["onSurfaceVariant", "surface"], ["onSurfaceVariant", "surfaceContainerHighest"],
        ["primary", "surface"], ["onPrimary", "primary"], ["onSecondary", "secondary"]];
    for (const a of ["secondary", "tertiary", "success", "warning", "error", "data4"])
        text.push([a, "surface"]);
    for (const [fg, bg] of text)
        ok(name + " " + fg + "/" + bg + " >= 4.5 (" + contrast(c[fg], c[bg]).toFixed(2) + ")", contrast(c[fg], c[bg]) >= 4.5);

    // Borders: at least 3:1
    ok(name + " outline/surface >= 3", contrast(c.outline, c.surface) >= 3);
    for (const bg of ["surface", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
        "surfaceContainerHigh", "surfaceContainerHighest"])
        ok(name + " outlineStrong/" + bg + " >= 3", contrast(c.outlineStrong, c[bg]) >= 3);
}

// Spot check against the spec table (2.9.7): onSurface / surface 17.3 dark, 16.2 light
ok("dark onSurface/surface ~17.3", Math.abs(contrast(P.colors(false).onSurface, P.colors(false).surface) - 17.3) < 0.1);
ok("light onSurface/surface ~16.2", Math.abs(contrast(P.colors(true).onSurface, P.colors(true).surface) - 16.2) < 0.1);

done("Palette");
