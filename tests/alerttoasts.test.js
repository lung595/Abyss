// AlertToasts.js tests. Run from anywhere: gjs tests/alerttoasts.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const T = load("components/AlertToasts.js");

const names = { a: "Reef NAS", b: "Kelp-Pi", c: "Atlas", d: "Dune", e: "Bay" };
const nameOf = id => names[id];
const down = id => ({ kind: "down", id, since: 0, duration: 0 });
const back = (id, duration) => ({ kind: "back", id, since: 0, duration });

eq("nothing, nothing", T.toasts([], nameOf), []);
eq("one down", T.toasts([down("a")], nameOf), [{ title: "Reef NAS is offline.", details: "" }]);
eq("one back", T.toasts([back("a", 45000)], nameOf), [{ title: "Reef NAS is back after 45 s.", details: "" }]);
eq("two down", T.toasts([down("a"), down("b")], nameOf), [{ title: "Reef NAS and Kelp-Pi are offline.", details: "Reef NAS · Kelp-Pi" }]);
eq("two back", T.toasts([back("a", 180000), back("b", 45000)], nameOf),
    [{ title: "Reef NAS and Kelp-Pi are back.", details: "Reef NAS 3 min · Kelp-Pi 45 s" }]);
eq("three down", T.toasts([down("a"), down("b"), down("c")], nameOf),
    [{ title: "3 favourites are offline.", details: "Reef NAS · Kelp-Pi · Atlas" }]);
eq("five back, capped at three names", T.toasts(["a", "b", "c", "d", "e"].map(i => back(i, 60000)), nameOf),
    [{ title: "5 favourites are back.", details: "Reef NAS 1 min · Kelp-Pi 1 min · Atlas 1 min · +2 more" }]);
eq("down and back make two toasts, down first", T.toasts([back("a", 1000), down("b")], nameOf).map(t => t.title),
    ["Kelp-Pi is offline.", "Reef NAS is back after 1 s."]);
eq("a dash in a name is replaced", T.toasts([down("a")], () => "Nas — one")[0].title, "Nas - one is offline.");
eq("an unknown device is still said", T.toasts([down("z")], nameOf)[0].title, "A favourite is offline.");
eq("two events with one unknown name stay a sentence", T.toasts([down("z"), down("b")], nameOf)[0].title, "A favourite and Kelp-Pi are offline.");
eq("junk events are ignored", T.toasts([null, { kind: "x", id: "a" }], nameOf), []);
done();
