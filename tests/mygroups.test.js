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

// The light's menu, as a tree
const lend = [
    { id: "s1", name: "atlas", online: true, relayed: false, latencyMs: 9, exit: true },
    { id: "s2", name: "vega", online: true, relayed: false, latencyMs: 4, exit: true },
    { id: "s3", name: "orion", online: false, relayed: false, latencyMs: 2, exit: true },
    { id: "s4", name: "lyra", online: true, relayed: false, latencyMs: 30, exit: true },
    { id: "s5", name: "laptop", online: true, relayed: false, latencyMs: 1, exit: false }
];
const tg = [{ id: "u1", name: "Busy", members: ["s1", "s2", "s3", "s5"] }, { id: "u2", name: "Idle", members: ["s5"] }];
let rows = M.exitTree(tg, lend, [], "", "");
eq("folded: one folder, then the lender in no group", rows.map(r => r.name).join(","), "Busy,lyra");
eq("the folder counts who can lend now", rows[0].count, 2);
rows = M.exitTree(tg, lend, ["u1"], "vega", "u1");
eq("unfolded: quickest online first, offline last", rows.slice(1, 4).map(r => r.name).join(","), "vega,atlas,orion");
ok("the chosen group is on, its member serving", rows[0].on && rows[1].serving && !rows[1].on);
ok("the last member closes the branch", rows[3].last && !rows[2].last);
ok("a group nobody in it can lend is left out", !rows.some(r => r.name === "Idle"));
rows = M.exitTree(tg, lend, ["u1"], "atlas", "");
ok("a peer picked alone is on, the group is not", rows.find(r => r.name === "atlas").on && !rows[0].on);
eq("nobody can lend: no rows", M.exitTree([], [lend[4]], [], "", "").length, 0);

// Exit routes no peer is known for come last, by name
const withLoose = M.exitTree([], [], [], "", "", [{ "id": "office-gw", "selected": true }]);
eq("a loose route is a row of its own", withLoose, [{ "kind": "route", "id": "office-gw", "name": "office-gw", "on": true, "online": true, "depth": 0, "last": false, "serving": false }]);
eq("no loose routes, no rows", M.exitTree([], [], [], "", ""), []);

done("mygroups");
