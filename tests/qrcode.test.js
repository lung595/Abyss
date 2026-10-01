// QrCode.js tests. Run from anywhere: gjs tests/qrcode.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const Q = load("components/QrCode.js");

const m = Q.matrix("https://play.google.com/store/apps/details?id=io.netbird.client");
ok("a square matrix", m.length >= 21 && m.every(r => r.length === m.length));
ok("version 1 to 40 sizes", (m.length - 17) % 4 === 0);
// The three finder patterns: a dark 7x7 ring with a dark 3x3 core
function finder(r0, c0) {
    for (let r = 0; r < 7; r++)
        for (let c = 0; c < 7; c++) {
            const ring = r === 0 || r === 6 || c === 0 || c === 6;
            const core = r >= 2 && r <= 4 && c >= 2 && c <= 4;
            if (m[r0 + r][c0 + c] !== (ring || core))
                return false;
        }
    return true;
}
ok("finder top left", finder(0, 0));
ok("finder top right", finder(0, m.length - 7));
ok("finder bottom left", finder(m.length - 7, 0));
eq("the same text, the same code", JSON.stringify(Q.matrix("abc")), JSON.stringify(Q.matrix("abc")));
ok("longer text, bigger code", Q.matrix("x".repeat(200)).length > Q.matrix("x").length);
ok("UTF-8 text encodes", Q.matrix("café ✓").length >= 21);

done("QrCode.js");
