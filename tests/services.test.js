// Services.js tests. Run from anywhere: gjs tests/services.test.js
imports.searchPath.unshift(imports.gi.GLib.path_get_dirname(imports.system.programPath));
const { load, eq, ok, done } = imports.load;
const S = load("components/Services.js");

// The table: every service, its port and scheme
const want = { jellyfin: [8096, "http"], homeassistant: [8123, "http"], proxmox: [8006, "https"], nextcloud: [8080, "http"], syncthing: [8384, "http"], portainer: [9443, "https"], immich: [2283, "http"], http: [80, "http"], https: [443, "https"] };
eq("nine services", S.SERVICES.length, 9);
for (const id of Object.keys(want)) {
    const s = S.SERVICES.find(x => x.id === id);
    ok("listed: " + id, !!s && s.name.length > 0);
    eq("port and scheme: " + id, [s.port, s.scheme], want[id]);
}
eq("ports are unique", new Set(S.SERVICES.map(s => s.port)).size, 9);

// Addresses
for (const good of ["100.64.0.7", "0.0.0.0", "255.255.255.255", "fd7a:115c:a1e0::1", "::1", "2001:db8:0:0:0:0:0:1", "fe80::"])
    ok("accepted: " + good, S.addressKind(good) !== "");
eq("kinds", [S.addressKind("10.0.0.1"), S.addressKind("::1")], ["v4", "v6"]);
for (const bad of ["", "256.1.1.1", "1.2.3", "1.2.3.4.5", "-1.2.3.4", "-oX", "host.example", "a b", "1.2.3.4;id", "$(id)", ":::", "1::2::3", "12345::1", "1:2:3:4:5:6:7", "1:2:3:4:5:6:7:8:9", ":1:2:3:4:5:6:7", "1:2:3:4:5:6:7:", "fe80::g", "1.2.3.4/24", "010.008.1.1", "1.02.3.4", "01.2.3.4", null, undefined, 5])
    eq("refused: " + JSON.stringify(bad), S.addressKind(bad), "");

// The plan
const p = S.probePlan("100.64.0.7");
ok("plan ok", p.ok && p.reason === "" && p.probes.length === 9);
const j = p.probes.find(x => x.id === "jellyfin");
eq("argument list", j.argv, ["timeout", "1", "bash", "-c", ': < "/dev/tcp/$1/$2"', "abyss-probe", "100.64.0.7", "8096"]);
ok("data never inside the script", p.probes.every(x => x.argv[4].indexOf("100.64") < 0 && x.argv.every(a => typeof a === "string")));
eq("v6 plan", S.probePlan("fd7a::1").probes[0].argv[6], "fd7a::1");
for (const bad of ["", "x; id", "-oProxyCommand=x", null, ["10.0.0.1"]]) {
    const q = S.probePlan(bad);
    eq("invalid plan: " + JSON.stringify(bad), [q.ok, q.probes.length], [false, 0]);
    ok("reason given", q.reason.length > 0);
}

// URLs
const by = id => S.SERVICES.find(s => s.id === id);
eq("custom port", S.url(by("jellyfin"), "100.64.0.7"), "http://100.64.0.7:8096/");
eq("https custom port", S.url(by("proxmox"), "100.64.0.7"), "https://100.64.0.7:8006/");
eq("default http port left out", S.url(by("http"), "100.64.0.7"), "http://100.64.0.7/");
eq("default https port left out", S.url(by("https"), "100.64.0.7"), "https://100.64.0.7/");
eq("IPv6 in brackets", S.url(by("immich"), "fd7a::1"), "http://[fd7a::1]:2283/");
eq("bad address", S.url(by("immich"), "x"), "");
eq("no service", S.url(null, "10.0.0.1"), "");

// Results -> buttons
const res = ids => ids.map(id => ({ id: id, open: true }));
eq("empty results", S.servicesFrom("10.0.0.1", [], 6), []);
eq("not a list", [S.servicesFrom("10.0.0.1", null), S.servicesFrom("10.0.0.1", undefined)], [[], []]);
eq("all closed", S.servicesFrom("10.0.0.1", [{ id: "jellyfin", open: false }]), []);
eq("one open", S.servicesFrom("10.0.0.1", res(["jellyfin"])), [{ id: "jellyfin", name: "Jellyfin", url: "http://10.0.0.1:8096/" }]);
eq("table order, not answer order", S.servicesFrom("10.0.0.1", res(["immich", "jellyfin"])).map(s => s.id), ["jellyfin", "immich"]);
eq("partial and junk entries", S.servicesFrom("10.0.0.1", [null, 3, {}, { id: "nope", open: true }, { id: "proxmox", open: "yes" }, { id: "proxmox", open: true }]).map(s => s.id), ["proxmox"]);
eq("plain web hidden next to a named service", S.servicesFrom("10.0.0.1", res(["http", "https", "syncthing"])).map(s => s.id), ["syncthing"]);
eq("plain web shown alone", S.servicesFrom("10.0.0.1", res(["https", "http"])).map(s => s.id), ["http", "https"]);
eq("capped at six by default", S.servicesFrom("10.0.0.1", res(Object.keys(want))).length, 6);
eq("cap as a parameter", S.servicesFrom("10.0.0.1", res(Object.keys(want)), 2).length, 2);
eq("bad cap falls back", S.servicesFrom("10.0.0.1", res(Object.keys(want)), -1).length, 6);
eq("invalid address shows nothing", S.servicesFrom("x", res(["jellyfin"])), []);
eq("IPv6 buttons", S.servicesFrom("fd7a::1", res(["proxmox"]))[0].url, "https://[fd7a::1]:8006/");

done("services");
