.pragma library
.import "../../components/Send.js" as Send
.import "../../components/Connect.js" as Connect

// How one job of the Send queue travels: the rsync command (percentage, rate,
// resume) when both sides have it, else the scp command of the engine
// (components/Send.js), reused and not copied. Pure: it builds argument lists
// and reads rsync's meter; the view runs them. Every piece of data is its own
// argument, "--" ends the options, and -s keeps the remote shell out of the
// names.

// The ssh options of the engine, as the single string rsync -e wants. Only
// fixed words and a port that Connect.cleanLink already checked go into it.
function _ssh(link) {
    const l = Connect.cleanLink(link);
    return "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=3" + (l.port ? " -p " + l.port : "");
}

// "rsync" when both ends have it, else "scp" (indeterminate progress)
function program(localHasRsync, remoteHasRsync) {
    return localHasRsync && remoteHasRsync ? "rsync" : "scp";
}

// argv that prints the path of rsync on the device, nothing when it has none
function remoteProbe(host, link) {
    const l = Connect.cleanLink(link);
    const target = (l.user ? l.user + "@" : "") + Connect.urlHost(host);
    return ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10"].concat(l.port ? ["-p", l.port] : [], ["--", target, "command -v rsync"]);
}

// { ok, reason, program, argv, paths } for one job: Send.plan decides what is
// allowed (host, paths, folder), this only picks the program.
function plan(prog, host, link, items, setting) {
    const base = Send.plan(host, link, items, setting);
    if (!base.ok || prog !== "rsync")
        return Object.assign({ "program": "scp" }, base);
    const l = Connect.cleanLink(link);
    const dir = Send.remoteDir(setting).dir;
    const target = (l.user ? l.user + "@" : "") + Connect.urlHost(host) + ":" + dir;
    return {
        "ok": true, "reason": "", "program": "rsync", "paths": base.paths,
        "argv": ["rsync", "-a", "-s", "--partial", "--info=progress2", "--no-inc-recursive", "-e", _ssh(link), "--"].concat(base.paths, [target])
    };
}

// { fraction, rate } from a piece of rsync's output (its meter rewrites one
// line with \r): the last meter in it, or null when there is none yet.
function parseProgress(chunk) {
    const re = /(\d{1,3})%\s+(\S+\/s)/g;
    let last = null, m;
    while ((m = re.exec(String(chunk || ""))) !== null)
        last = m;
    return last ? { "fraction": Math.min(100, Number(last[1])) / 100, "rate": last[2] } : null;
}

// A name for a queue row, elided in the middle so that the extension stays:
// 18 + … + 6 characters at most, as in the mockup (e5-long-names-send).
function middle(name, head, tail) {
    const s = String(name);
    if (s.length <= head + tail + 1)
        return s;
    return s.slice(0, head) + "…" + s.slice(s.length - tail);
}

// The row's name: the last part of the path
function baseName(path) {
    const p = String(path);
    return p.slice(p.lastIndexOf("/") + 1) || p;
}
