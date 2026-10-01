.pragma library

// The search bar is also a command palette: typing "add", "share",
// "disconnect"… offers the matching action, in plain words. Pure functions
// only, tested with gjs in tests/.

.import "Query.js" as Query

// Every command: words that find it, and when it makes sense.
// st: { state, shareSsh, exit, console, lab, offline }
const ALL = [
    { "act": "add", "icon": "add_circle", "text": "Add a device", "sub": "This computer or your phone, step by step", "w": ["add", "new device", "join", "setup key", "key", "phone", "enroll", "ajouter", "appareil", "rejoindre"], "when": st => true },
    { "act": "connect", "icon": "power_settings_new", "text": "Connect", "sub": "Join the mesh again", "w": ["connect", "on", "up", "start", "connecter", "allumer"], "when": st => st.state === "disconnected" },
    { "act": "signin", "icon": "login", "text": "Sign in", "sub": "NetBird needs you to sign in", "w": ["sign in", "login", "log in", "connect", "connexion"], "when": st => st.state === "needsLogin" },
    { "act": "start", "icon": "play_circle", "text": "Start NetBird", "sub": "The service is stopped", "w": ["start", "service", "connect", "demarrer"], "when": st => st.state === "stopped" },
    { "act": "disconnect", "icon": "power_settings_new", "text": "Disconnect", "sub": "Leave the mesh for now", "w": ["disconnect", "off", "down", "stop", "deconnecter", "couper"], "when": st => st.state === "connected" || st.state === "connecting" },
    { "act": "share", "icon": "login", "text": "Let my devices into this computer", "sub": "Your other peers can open a terminal here (SSH)", "w": ["share", "allow", "ssh in", "let in", "remote", "partager", "autoriser", "acces"], "when": st => !st.shareSsh },
    { "act": "unshare", "icon": "lock", "text": "Stop letting devices in", "sub": "Turn this computer's SSH off", "w": ["share", "allow", "lock", "close", "unshare", "stop sharing", "bloquer", "fermer"], "when": st => st.shareSsh },
    { "act": "direct", "icon": "public", "text": "Internet: go out directly", "sub": "Stop going out through " + "a peer", "w": ["internet", "direct", "exit", "off"], "when": st => !!st.exit },
    { "act": "offline", "icon": "visibility", "text": "Show offline devices", "sub": "", "w": ["offline", "show", "hidden", "asleep"], "when": st => !st.offline },
    { "act": "offline", "icon": "visibility_off", "text": "Hide offline devices", "sub": "", "w": ["offline", "hide", "asleep"], "when": st => st.offline },
    { "act": "console", "icon": "open_in_new", "text": "Open the admin console", "sub": "NetBird's dashboard: devices, keys, access", "w": ["console", "dashboard", "admin", "acl", "access", "policy", "keys", "settings"], "when": st => !!st.console },
    { "act": "leave", "icon": "logout", "text": "Sign this computer out", "sub": "It leaves the mesh until you sign in again", "w": ["sign out", "logout", "log out", "leave", "deconnexion"], "when": st => st.state !== "stopped" && !st.lab }
];

function _norm(s) {
    return Query.norm(s).trim();
}

// The commands a query finds, best first; at most `max`. A word must start
// one of the command's words (or its text): "dis" finds Disconnect, "add"
// Add a device. Nothing for an empty query
function match(query, st, max) {
    const q = _norm(query);
    if (!q)
        return [];
    const out = [];
    ALL.forEach((c, i) => {
        if (!c.when(st || {}))
            return;
        const words = c.w.concat([_norm(c.text)]);
        let score = 0;
        words.forEach(w => {
            const n = _norm(w);
            if (n === q)
                score = Math.max(score, 3);
            else if (n.indexOf(q) === 0)
                score = Math.max(score, 2);
            else if (q.length >= 3 && n.split(" ").some(part => part.indexOf(q) === 0))
                score = Math.max(score, 1);
        });
        if (score)
            out.push({ "c": c, "score": score, "i": i });
    });
    out.sort((a, b) => b.score - a.score || a.i - b.i);
    // The same act once (show/hide offline share words)
    const seen = {};
    return out.filter(x => !seen[x.c.act + x.c.text] && (seen[x.c.act + x.c.text] = true)).slice(0, max || 3).map(x => x.c);
}

// Shortcuts offered under the empty search bar: what people look for
const SUGGESTIONS = [
    { "q": "online", "icon": "wifi", "text": "Online" },
    { "q": "phones", "icon": "smartphone", "text": "Phones" },
    { "q": "fast", "icon": "bolt", "text": "Fast" },
    { "q": "slow", "icon": "hourglass_bottom", "text": "Slow" },
    { "q": "relay", "icon": "swap_horiz", "text": "Via a relay" },
    { "q": "exit", "icon": "public", "text": "Can lend Internet" },
    { "q": "busy", "icon": "trending_up", "text": "Busy" },
    { "q": "offline", "icon": "bedtime", "text": "Offline" }
];
