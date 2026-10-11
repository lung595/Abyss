// Tags.js tests. Run from anywhere: gjs tests/tags.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const T = load("components/Tags.js");

eq("clean lowers, strips # and accents", T.clean("#Été Maison"), "ete-maison");
eq("clean drops everything unsafe", T.clean("a;rm -rf $(x)"), "a-rm-rf-x");
eq("clean caps the length", T.clean("x".repeat(60)).length, 24);
eq("clean of nothing", T.clean(undefined), "");
eq("list: doubles and empties dropped", T.cleanList(["NAS", "nas", "", "#nas", "b"]), ["nas", "b"]);
eq("list: capped at 8", T.cleanList("abcdefghijkl".split("")).length, 8);
eq("list: not an array", T.cleanList("nas"), []);
eq("map: bad shapes", T.cleanMap([1]), {});
eq("map: empty lists dropped", T.cleanMap({ "a": [], "b": ["x"] }), { "b": ["x"] });
const big = {};
for (let i = 0; i < 300; i++)
    big["p" + i] = ["t"];
eq("map: capped at 200 peers", Object.keys(T.cleanMap(big)).length, 200);
eq("setManual adds", T.setManual({}, "a", ["Backup"]), { "a": ["backup"] });
eq("setManual with [] removes", T.setManual({ "a": ["x"] }, "a", []), {});
eq("setManual keeps a full map full", Object.keys(T.setManual(T.cleanMap(big), "new", ["t"])).length, 200);

const peer = { id: "a", name: "atlas", kind: "nas", exit: true, networks: ["192.168.1.0/24", "0.0.0.0/0"] };
const groups = [{ id: "u1", name: "Home", members: ["a"] }];
eq("auto: kind, exit, subnet, group", T.auto(peer, groups), ["nas", "exit", "subnet", "home"]);
eq("auto: nothing special", T.auto({ id: "z", kind: "", networks: [] }, []), []);
eq("of: manual after auto, no double", T.of(peer, groups, { "a": ["Work", "nas"] }), ["nas", "exit", "subnet", "home", "work"]);

// Query: "#tag" and plain words reach tags
const Q = load("components/Query.js");
const tagsOf = p => T.of(p, groups, { "a": ["work"] });
const f = Q.parse("#work", [], tagsOf);
ok("#tag is a filter, not a name", f.length === 1 && !f[0].name && f[0].test(peer));
ok("#tag is exact", !Q.parse("#wor", [], tagsOf)[0].test(peer));
ok("a plain word matches a tag start", Q.parse("wor", [], tagsOf)[0].test(peer));
ok("a plain word no tag has fails", !Q.parse("zzz", [], tagsOf)[0].test(peer));
ok("without tagsOf nothing breaks", !Q.parse("#work", [])[0].test(peer));
ok("known words keep their meaning", Q.parse("nas", [], tagsOf)[0].label === "NAS");
done();
