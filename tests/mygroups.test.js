// MyGroups.js tests (the user's own groups, Internet through a group).
// Run from anywhere: gjs tests/mygroups.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const M = load("components/MyGroups.js");

// Making, joining, leaving
let r = M.create([], ["a"]);
eq("a first group is called Group 1", r.groups[0].name, "Group 1");
let gs = r.groups;
r = M.create(gs, ["b"]);
gs = r.groups;
eq("the next one is Group 2", gs[1].name, "Group 2");
gs = M.join(gs, "u1", "b");
eq("joining moves the peer", M.groupOf(gs, "b").id, "u1");
ok("a group left empty disappears", !M.byId(gs, "u2"));
gs = M.create(gs, ["a"]).groups;
ok("a peer never sits in two groups", gs.filter(g => g.members.indexOf("a") >= 0).length === 1);
gs = M.rename(gs, "u1", "  Office  ");
eq("rename trims", M.byId(gs, "u1").name, "Office");
eq("a blank name keeps the old one", M.byId(M.rename(gs, "u1", "  "), "u1").name, "Office");
eq("leave takes it out", M.groupOf(M.leave(gs, "b"), "b"), null);
eq("remove drops the group", M.byId(M.remove(gs, "u1"), "u1"), null);
eq("the old list is never changed", gs.length, 2);

// Internet through a group: its best member, and no flapping
const peers = [
    { id: "a", name: "a", online: true, relayed: true, latencyMs: 5, exit: true },
    { id: "b", name: "b", online: true, relayed: false, latencyMs: 40, exit: true },
    { id: "c", name: "c", online: true, relayed: false, latencyMs: 12, exit: true },
    { id: "d", name: "d", online: false, relayed: false, latencyMs: 1, exit: true }
];
eq("direct first, then the quickest", M.pickExit(peers, ["a", "b", "c", "d"], "").name, "c");
eq("the current one stays while online", M.pickExit(peers, ["a", "b", "c"], "b").name, "b");
eq("an offline current one is replaced", M.pickExit(peers, ["b", "d"], "d").name, "b");
eq("steady latency wins over a jittery read", M.pickExit([
    { id: "x", name: "x", online: true, relayed: false, latencyMs: 3, steadyMs: 50, exit: true },
    { id: "y", name: "y", online: true, relayed: false, latencyMs: 30, steadyMs: 20, exit: true }
], ["x", "y"], "").name, "y");
eq("nobody online: no exit", M.pickExit(peers, ["d"], ""), null);
// Only a member offering an exit node can lend Internet
const mixed = [
    { id: "p", name: "p", online: true, relayed: false, latencyMs: 2, exit: false },
    { id: "q", name: "q", online: true, relayed: false, latencyMs: 30, exit: true }
];
eq("the quickest that can lend, not the quickest", M.pickExit(mixed, ["p", "q"], "").name, "q");
eq("a current one that cannot lend is replaced", M.pickExit(mixed, ["p", "q"], "p").name, "q");
eq("nobody can lend: no exit", M.pickExit(mixed, ["p"], ""), null);

done("mygroups");
