.pragma library

// The smart search: typed words become filters on peers. Pure functions
// only, tested with gjs in tests/.
//
// Each word is either a known word (a species, a state, a route, "busy",
// "slow"...), a latency bound like ">100ms", or part of a name. Every filter
// must match. English and French words are both understood; labels are
// English. Nothing leaves the machine: it is only string matching.

.import "Groups.js" as Groups

// Lower case, without accents
function norm(s) {
    return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

// "hrbr" finds "harbor": the letters appear in order
function subseq(q, s) {
    let i = 0;
    for (let k = 0; k < s.length && i < q.length; k++)
        if (s[k] === q[i])
            i++;
    return i === q.length;
}

const WORDS = [
    { "w": ["phone", "telephone", "tel", "mobile", "smartphone", "android", "iphone", "tablet", "ipad", "pixel"], "label": "phones", "test": p => p.kind === "phone" },
    { "w": ["server", "serveur", "srv", "homelab", "proxmox", "docker", "router", "routeur", "gateway", "nuc"], "label": "servers", "test": p => p.kind === "server" },
    { "w": ["vps", "cloud", "droplet", "hetzner", "aws", "vultr", "linode"], "label": "VPS", "test": p => p.kind === "vps" },
    { "w": ["nas", "storage", "stockage", "synology", "truenas", "qnap", "backup", "sauvegarde"], "label": "NAS", "test": p => p.kind === "nas" },
    { "w": ["pi", "raspberry", "rpi"], "label": "Raspberry Pi", "test": p => p.kind === "pi" },
    { "w": ["laptop", "portable", "macbook", "mac", "chromebook", "thinkpad", "notebook"], "label": "laptops", "test": p => p.kind === "laptop" },
    { "w": ["desktop", "pc", "fixe", "workstation", "tower", "tour"], "label": "desktops", "test": p => p.kind === "desktop" },
    { "w": ["offline", "off", "asleep", "sleeping", "dort", "eteint"], "label": "offline", "test": p => !p.online },
    { "w": ["online", "on", "up", "connecte"], "label": "online", "test": p => p.online },
    { "w": ["relay", "relayed", "relais", "relaye", "via"], "label": "through a relay", "test": p => p.online && p.relayed },
    { "w": ["direct", "p2p"], "label": "direct", "test": p => p.online && !p.relayed },
    { "w": ["busy", "big", "heavy", "top", "gros", "actif"], "label": "heavy traffic", "test": p => p.online && Groups.total(p) > 1e6 },
    { "w": ["quiet", "idle", "calme", "inactif"], "label": "almost idle", "test": p => p.online && Groups.total(p) < 1e5 },
    { "w": ["exit", "lender", "sortie"], "label": "can lend Internet", "test": p => !!p.exit },
    { "w": ["new", "recent", "nouveau", "recemment"], "label": "online for under an hour", "test": p => p.online && p.since > 0 && Date.now() - p.since < 3600000 },
    { "w": ["slow", "far", "lent", "loin"], "label": "latency > 100 ms", "test": p => p.online && p.latencyMs > 100 },
    { "w": ["fast", "near", "close", "rapide", "proche"], "label": "latency < 20 ms", "test": p => p.online && p.latencyMs < 20 }
];

// Small words that carry no meaning in a query
const STOP = ["the", "my", "all", "and", "en", "les", "le", "la", "des", "de", "du", "et", "mes"];

// "hors ligne" -> offline; "phones offline" -> [phones, offline]
// Returns [{label, name: bool, test(peer)}]
function parse(query, relays) {
    const known = (relays || []).map(norm);
    const toks = norm(query).replace(/hors[\s-]*ligne?/g, "offline").replace(/en[\s-]+ligne/g, "online").split(/\s+/).filter(Boolean);
    const out = [];
    toks.forEach(tok => {
        const m = tok.match(/^([<>])(\d+)(ms)?$/);
        if (m) {
            const n = Number(m[2]);
            out.push(m[1] === ">" ? {
                "label": "latency > " + n + " ms",
                "test": p => p.online && p.latencyMs > n
            } : {
                "label": "latency < " + n + " ms",
                "test": p => p.online && p.latencyMs < n
            });
            return;
        }
        if (STOP.indexOf(tok) >= 0)
            return;
        // A relay by name, or by its tail ("eu" for "relay-eu")
        const relay = known.find(r => r === tok || r.endsWith("-" + tok));
        if (relay) {
            out.push({ "label": "via " + relay, "test": p => p.online && p.relayed && norm(p.relay) === relay });
            return;
        }
        const word = WORDS.find(k => k.w.indexOf(tok) >= 0 || k.w.indexOf(tok.replace(/s$/, "")) >= 0);
        if (word) {
            if (out.indexOf(word) < 0)
                out.push(word);
            return;
        }
        out.push({
            "label": "name ≈ “" + tok + "”",
            "name": true,
            "test": p => norm(p.name).indexOf(tok) >= 0 || (tok.length >= 3 && subseq(tok, norm(p.name)))
        });
    });
    return out;
}

// One peer for a word typed in a command (IPC, launcher): its exact name,
// fqdn, address or id first, then the start of a name, but only when one
// peer starts that way ("abyss ssh a" must not pick whoever comes first).
// Returns { peer, many: [names] }: peer null with `many` listing the
// candidates when the word fits several
function lookup(peers, key) {
    const k = String(key || "").trim().toLowerCase();
    const none = { "peer": null, "many": [] };
    if (!k)
        return none;
    const list = peers || [];
    const exact = list.find(p => p.name.toLowerCase() === k || (p.fqdn || "").toLowerCase() === k || p.ip === k || p.id === key);
    if (exact)
        return { "peer": exact, "many": [] };
    const starts = list.filter(p => p.name.toLowerCase().startsWith(k));
    if (starts.length === 1)
        return { "peer": starts[0], "many": [] };
    return { "peer": null, "many": starts.map(p => p.name) };
}

// What to say when lookup found no single peer
function lookupError(key, found) {
    if (found.many.length)
        return "Several peers start with " + key + ": " + found.many.join(", ");
    return "No peer named " + key;
}
