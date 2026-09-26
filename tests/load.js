// Tiny test helpers for gjs. QML JavaScript files start with ".pragma" and
// may ".import" each other; plain JavaScript knows neither, so load() strips
// the pragma, loads each import first and hands it in under its QML name.
const { GLib } = imports.gi;

const _root = GLib.path_get_dirname(GLib.path_get_dirname(imports.system.programPath));

function _read(rel) {
    const [ok, bytes] = GLib.file_get_contents(_root + "/" + rel);
    if (!ok)
        throw new Error("cannot read " + rel);
    return new TextDecoder().decode(bytes);
}

// Returns an object with every top-level function and const of the file
function load(rel) {
    const dir = rel.replace(/[^/]*$/, "");
    let src = _read(rel).replace(/^\.pragma.*$/m, "");
    const names = [], values = [];
    src = src.replace(/^\.import\s+"([^"]+)"\s+as\s+(\w+)\s*;?$/mg, (m, file, name) => {
        names.push(name);
        values.push(load(dir + file));
        return "";
    });
    const exported = [...src.matchAll(/^(?:function\s+(\w+)|const\s+(\w+))/mg)].map(m => m[1] || m[2]);
    const body = src + "\nreturn {" + exported.join(", ") + "};";
    return new Function(...names, body)(...values);
}

let _fails = 0, _count = 0;

function _same(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
}

function eq(name, got, want) {
    _count++;
    if (!_same(got, want)) {
        _fails++;
        print("FAIL " + name + "\n  got:  " + JSON.stringify(got) + "\n  want: " + JSON.stringify(want));
    }
}

function ok(name, cond) {
    _count++;
    if (!cond) {
        _fails++;
        print("FAIL " + name);
    }
}

function done(label) {
    print((_fails ? "✗ " : "✓ ") + label + ": " + (_count - _fails) + "/" + _count + " passed");
    if (_fails)
        imports.system.exit(1);
}
