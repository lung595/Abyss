.pragma library
.import "Connect.js" as Connect

// Waking a sleeping device (Wake-on-LAN), as pure functions tested with gjs
// in tests/. Nothing here runs a program: it checks a MAC address, picks the
// way to send the magic packet, builds argument lists and words the refusals.
// Like Send.js, every piece of data is its own argument (never pasted into a
// shell string), "--" ends the options before data, and ssh runs in batch
// mode so it fails instead of asking for a password.
//
// A magic packet is a broadcast: it only reaches devices on the sender's own
// network. So the packet leaves from this computer when it is on the
// device's network, otherwise from an online peer that is (over ssh).
// "lan" below is an opaque key for a network (see lanKey), compared as text.

// The programs that send a magic packet, in order of preference
const TOOLS = ["wakeonlan", "etherwake"];

// Where the guide explains each refusal (value 10: say why and how to fix it)
const GUIDE = "docs/GUIDE.md#wake-a-device";

// --- The MAC address ----------------------------------------------------------

// "aa:bb:cc:dd:ee:ff" (lower case, colons) from a MAC written with colons,
// dashes or none, or "" for anything else. A broadcast, an all-zero or a
// multicast address is no device's own address, so it is refused too.
function normalizeMac(text) {
    const s = String(text === undefined || text === null ? "" : text).trim();
    let hex = "";
    if (/^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$/.test(s) && (s.indexOf(":") < 0 || s.indexOf("-") < 0))
        hex = s.replace(/[:-]/g, "");
    else if (/^[0-9A-Fa-f]{12}$/.test(s))
        hex = s;
    else
        return "";
    hex = hex.toLowerCase();
    // Multicast bit set (this covers the broadcast ff:ff:ff:ff:ff:ff)
    if (parseInt(hex.slice(0, 2), 16) & 1)
        return "";
    if (/^0{12}$/.test(hex))
        return "";
    return hex.replace(/(..)(?=.)/g, "$1:");
}

// --- The network ---------------------------------------------------------------

// A key for the IPv4 network an address is on ("192.168.1.0/24" for
// 192.168.1.20/24), or "" for an address or prefix that is not usable.
// prefix is the number of network bits (8 to 30).
function lanKey(ip, prefix) {
    const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(String(ip || ""));
    const bits = Number(prefix);
    if (!m || !/^\d{1,2}$/.test(String(prefix)) || bits < 8 || bits > 30)
        return "";
    const o = m.slice(1).map(Number);
    if (o.some(n => n > 255))
        return "";
    // Four octets as one unsigned number, then the host bits cleared
    const n = ((o[0] * 256 + o[1]) * 256 + o[2]) * 256 + o[3];
    const size = Math.pow(2, 32 - bits);
    const base = Math.floor(n / size) * size;
    return [Math.floor(base / 16777216), Math.floor(base / 65536) % 256, Math.floor(base / 256) % 256, base % 256].join(".") + "/" + bits;
}

// --- What is known about a device ------------------------------------------------

// { mac, lan } to remember for a device, or null when it must not be learned
// now. Only a device that is online has an address worth keeping (an old
// neighbour entry may belong to anyone), and a MAC is only useful with the
// network it was seen on.
function learn(online, mac, lan) {
    const m = normalizeMac(mac);
    if (online !== true || m === "" || typeof lan !== "string" || lan === "")
        return null;
    return { "mac": m, "lan": lan };
}

// The saved { mac, lan } of a device if it can be woken, else null
function known(saved) {
    const s = saved || {};
    const mac = normalizeMac(s.mac);
    return mac !== "" && typeof s.lan === "string" && s.lan !== "" ? { "mac": mac, "lan": s.lan } : null;
}

// --- The way to send ---------------------------------------------------------------

// { kind, peer, reason }: how to wake `target` ({ id, mac, lan } as saved).
//   kind "direct": this computer is on the device's network (here: its key)
//   kind "peer":   an online peer of that network sends it; peer is the entry
//   kind "none":   reason "nomac" (never learned) or "nopeer" (no way now)
// peers: [{ id, online, lan, host, link }]; the first usable one wins, which
// keeps the choice stable from one click to the next.
function route(target, here, peers) {
    const k = known(target);
    if (!k)
        return { "kind": "none", "peer": null, "reason": "nomac" };
    if (typeof here === "string" && here !== "" && here === k.lan)
        return { "kind": "direct", "peer": null, "reason": "" };
    const peer = (Array.isArray(peers) ? peers : []).find(p => p && p.online === true && p.lan === k.lan && p.id !== (target || {}).id && Connect.validHost(p.host));
    return peer ? { "kind": "peer", "peer": peer, "reason": "" } : { "kind": "none", "peer": null, "reason": "nopeer" };
}

// --- The commands ----------------------------------------------------------------------

// argv that prints the first sending program installed here, or exits 1.
// The names are arguments of the script, never pasted into it.
function toolCommand() {
    return ["sh", "-c", "for t in \"$@\"; do command -v \"$t\" >/dev/null 2>&1 && { echo \"$t\"; exit 0; }; done; exit 1", "sh"].concat(TOOLS);
}

// The program toolCommand printed (one of TOOLS), or "" for anything else
function parseTool(out) {
    const t = String(out || "").trim();
    return TOOLS.indexOf(t) >= 0 ? t : "";
}

// argv sending the packet from this computer, or null for a program or MAC
// that is not accepted
function directCommand(tool, mac) {
    const m = normalizeMac(mac);
    return TOOLS.indexOf(tool) < 0 || m === "" ? null : [tool, "--", m];
}

// What the peer runs: its own search for a program, so nothing is asked of
// it first. The MAC is a positional parameter of sh, and only a checked MAC
// (hex and colons) is ever written in the command. 127 means no program.
const REMOTE_MISSING = 127;
const _REMOTE_SCRIPT = "for t in " + TOOLS.join(" ") + "; do command -v \"$t\" >/dev/null 2>&1 && exec \"$t\" -- \"$1\"; done; exit " + REMOTE_MISSING;

// argv sending the packet from a peer over ssh, or null for a host or MAC
// that is not accepted. Single quotes keep the peer's login shell (bash,
// fish…) from reading the script; link is the peer's saved { user, port }.
function peerCommand(host, link, mac) {
    const m = normalizeMac(mac);
    if (!Connect.validHost(host) || m === "")
        return null;
    const t = Connect.sshTarget(host, link);
    return ["ssh", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=10"].concat(t.options, ["--", t.target, "sh -c '" + _REMOTE_SCRIPT + "' sh " + m]);
}

// --- Saying it ---------------------------------------------------------------------------

function _note(kind, title, advice) {
    return { "kind": kind, "title": title, "advice": advice, "guide": GUIDE };
}

// The refusal for a route of kind "none"
function routeNote(reason, name) {
    const who = Connect.plainText(name || "this device");
    if (reason === "nopeer")
        return _note("nopeer", "No device can wake " + who + " right now", "Waking needs this computer, or another online device, on the same network as " + who + ". Connect one of them, then try again.");
    return _note("nomac", "Abyss does not know how to wake " + who + " yet", "It learns the address of " + who + " while it is online on a network you share. Wait until it shows as online once, then try again.");
}

// What to install when no sending program exists. where: "here" or the name
// of the peer that lacks it; pm: the package manager found (see
// Connect.packageManagerCommand), "" if unknown.
const PACKAGE = { "pacman": "wakeonlan", "apt": "wakeonlan", "dnf": "wakeonlan", "zypper": "wakeonlan" };
function toolNote(where, pm) {
    const on = where === "here" || !where ? "on this computer" : "on " + Connect.plainText(where);
    const pkg = PACKAGE[pm] || "";
    return {
        "kind": "notool",
        "title": "No wake program installed " + on,
        "advice": pkg ? "Install it with the command below, then try again." : "Install wakeonlan (or etherwake) from your software center, then try again.",
        "guide": GUIDE,
        "command": pkg ? Connect.INSTALL[pm] + pkg : ""
    };
}

// An ended wake that did not go through, from the exit code. via: "direct"
// or "peer"; name: the device's; peerName: the peer that sent it. A peer's
// 127 is the missing program; ssh's own failure is 255; -1 is a program that
// could not start or took too long (CliRunner's convention).
function explain(code, via, name, peerName) {
    const who = Connect.plainText(name || "this device");
    const peer = Connect.plainText(peerName || "the other device");
    if (via === "peer" && code === REMOTE_MISSING)
        return toolNote(peerName || "the other device", "");
    if (via === "peer" && code === 255)
        return _note("peer", "Abyss could not reach " + peer + " to wake " + who, "It sends the signal for you. Check that it is online and accepts SSH from this computer, then try again.");
    if (code === -1)
        return _note("stuck", "The wake signal to " + who + " did not go out", "The program did not start or took too long. Try again.");
    return _note("other", "The wake signal to " + who + " failed", "Try again. If it keeps failing, the guide lists what to check.");
}

// The sentence for a magic packet sent. A sent packet is not a woken device:
// the device may be off at the mains, or its BIOS may ignore the signal.
function doneText(name, via, peerName) {
    const who = Connect.plainText(name || "this device");
    return via === "peer" ? "Wake signal sent to " + who + " through " + Connect.plainText(peerName || "another device") : "Wake signal sent to " + who;
}

// What the runner says while it works
function wakingText(name) {
    return "Waking " + Connect.plainText(name || "this device");
}
