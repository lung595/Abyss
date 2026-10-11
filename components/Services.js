.pragma library

// The web services a peer may run, as pure functions tested with gjs in
// tests/. Nothing here opens a socket or starts a program: it holds the
// fixed list of well-known services, builds the argument lists that probe
// their ports (run later, on demand, by a component) and turns the answers
// into the buttons to show. Like Ping.js, an address is validated before use,
// every piece of data is its own argument (never pasted into a shell string)
// and a probe can never be read as an option.

// The well-known services, most specific first. The plain http and https
// ports come last so that they only add a button for what has no name.
const SERVICES = [
    { id: "jellyfin", name: "Jellyfin", port: 8096, scheme: "http" },
    { id: "homeassistant", name: "Home Assistant", port: 8123, scheme: "http" },
    { id: "proxmox", name: "Proxmox", port: 8006, scheme: "https" },
    { id: "nextcloud", name: "Nextcloud", port: 8080, scheme: "http" },
    { id: "syncthing", name: "Syncthing", port: 8384, scheme: "http" },
    { id: "portainer", name: "Portainer", port: 9443, scheme: "https" },
    { id: "immich", name: "Immich", port: 2283, scheme: "http" },
    { id: "http", name: "Web page (http)", port: 80, scheme: "http" },
    { id: "https", name: "Web page (https)", port: 443, scheme: "https" }
];

// How long one probe waits for a connection, in seconds. Short on purpose:
// a peer that is up answers at once, a closed port must not hold the card.
const PROBE_SECONDS = 1;

// The most buttons a card shows: a short list stays readable on a small card
const MAX_SHOWN = 6;

// "v4", "v6" or "" for an address a probe may take. IPv4 is four numbers
// up to 255; IPv6 is hex groups and colons with at most one "::" (an
// embedded dotted tail is not accepted: peers never need it). No "-" at the
// start is possible in either form, so it can never pass as an option.
function addressKind(ip) {
    const s = String(ip === undefined || ip === null ? "" : ip);
    const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(s);
    // A leading zero is refused: resolvers read "010" as octal, so the probe
    // could reach another host than the one shown
    if (m)
        return m.slice(1).every(n => Number(n) <= 255 && (n === "0" || n[0] !== "0")) ? "v4" : "";
    if (!/^[0-9a-fA-F:]+$/.test(s) || s.indexOf(":") < 0 || s.indexOf(":::") >= 0)
        return "";
    const doubles = s.split("::").length - 1;
    if (doubles > 1)
        return "";
    const groups = s.split(":").filter(g => g !== "");
    if (groups.some(g => g.length > 4))
        return "";
    // Without "::" all eight groups are written; with it, fewer than eight
    if (doubles === 0 ? groups.length !== 8 || s.startsWith(":") || s.endsWith(":") : groups.length > 7)
        return "";
    // A single leading or trailing colon is only valid as part of "::"
    if ((s.startsWith(":") && !s.startsWith("::")) || (s.endsWith(":") && !s.endsWith("::")))
        return "";
    return "v6";
}

// The probe plan for one peer: { ok, reason, probes }. Each probe is
// { id, port, argv }; argv is a connection test for bash that waits at most
// PROBE_SECONDS and exits 0 when the port accepts. The address and the port
// reach bash as positional parameters ("$1", "$2"), never inside the script.
function probePlan(ip) {
    if (typeof ip !== "string" || !addressKind(ip))
        return { ok: false, reason: "not a valid address", probes: [] };
    return {
        ok: true,
        reason: "",
        probes: SERVICES.map(s => ({
            id: s.id,
            port: s.port,
            argv: ["timeout", String(PROBE_SECONDS), "bash", "-c", ': < "/dev/tcp/$1/$2"', "abyss-probe", ip, String(s.port)]
        }))
    };
}

// The URL that opens a service, or "" for an unusable address or service.
// An IPv6 address goes in brackets, as a URL requires; the default port of
// the scheme is left out so the address bar reads like a person would type.
function url(service, ip) {
    const kind = typeof ip === "string" ? addressKind(ip) : "";
    if (!kind || !service)
        return "";
    const host = kind === "v6" ? "[" + ip + "]" : ip;
    const plain = (service.scheme === "http" && service.port === 80) || (service.scheme === "https" && service.port === 443);
    return service.scheme + "://" + host + (plain ? "" : ":" + service.port) + "/";
}

// Probe answers -> the buttons to show: [{ id, name, url }] in table order.
// results is a list of { id, open } (an unknown id, a missing field or an
// answer that is not exactly true counts as closed). Empty when nothing
// answered, so the card shows no section (a partial list is still shown).
// Plain http and https are dropped when a named service already answers on
// the same machine: they would only repeat it, and the list stays short.
function servicesFrom(ip, results, max) {
    const open = {};
    for (const r of Array.isArray(results) ? results : []) {
        if (r && r.open === true)
            open[r.id] = true;
    }
    const found = SERVICES.filter(s => open[s.id] === true);
    const named = found.filter(s => s.id !== "http" && s.id !== "https");
    const wanted = named.length ? named : found;
    const limit = Number(max) > 0 ? Math.floor(Number(max)) : MAX_SHOWN;
    return wanted
        .map(s => ({ id: s.id, name: s.name, url: url(s, ip) }))
        .filter(s => s.url !== "")
        .slice(0, limit);
}
