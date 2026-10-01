.pragma library

// A ping on demand, the way a person would run it: three echoes to a peer's
// address, only when asked (a button in the peer's card, `dms ipc call abyss
// ping <peer>`). Nothing is ever pinged on its own. Pure functions, tested
// with gjs in tests/.

// An address ping can take as an address and never as an option
function validAddress(ip) {
    return /^[0-9a-fA-F:.]+$/.test(String(ip || "")) && !/^-/.test(String(ip));
}

// argv for the process (never a shell line): 3 echoes, 2 s to wait for each
function command(ip) {
    return validAddress(ip) ? ["ping", "-c", "3", "-W", "2", ip] : null;
}

// `ping`'s output and exit code -> one line to show.
// "atlas: 4.2 ms (min 3.9 · max 4.8, 3/3 replies)", "atlas: no answer",
// "atlas: ping is not installed"
function summary(name, out, code) {
    const text = String(out || "");
    if (code === -1 && !text)
        return name + ": ping did not start (is it installed?)";
    const rtt = text.match(/=\s*([\d.]+)\/([\d.]+)\/([\d.]+)/);
    const got = text.match(/(\d+)\s+(?:packets\s+)?received/);
    const sent = text.match(/(\d+)\s+packets\s+transmitted/);
    const replies = got && sent ? got[1] + "/" + sent[1] + " replies" : "";
    if (!rtt)
        return name + ": no answer" + (replies ? " (" + replies + ")" : "");
    return name + ": " + Math.round(Number(rtt[2]) * 10) / 10 + " ms (min " + rtt[1] + " · max " + rtt[3] + (replies ? ", " + replies : "") + ")";
}
