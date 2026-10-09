import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import "components"
import "components/Terminal.js" as Terminal
import "components/Connect.js" as Connect
import "components/MyGroups.js" as MyGroups
import "components/Query.js" as Query
import "components/Ping.js" as Ping
import "components/SendFlow.js" as SendFlow

// The one engine every surface shares: the mesh source, the actions that
// leave the shell (copy, SSH, browser), notifications and the IPC.
// Surfaces find it with PluginService.pluginDaemonInstances["abyss"].
// Nothing runs here on its own: the source only reads while a view watches
// (once at start, `command -v netbird` says whether NetBird is installed).
// Privacy: peers and traffic stay in memory; nothing is written to disk
// except the user's settings, and the plugin never talks to the network.
Item {
    id: root

    property var pluginService: null
    property string pluginId: "abyss"

    // The mesh every surface draws: the NetBird daemon, or the test lab's
    // made-up mesh (setting "Mesh source"; "auto" takes NetBird when
    // its CLI is installed). Both have the same interface; only the one in
    // use exists. Null until the lookup below has answered.
    readonly property var source: sourceLoader.item
    readonly property bool useDemo: prefs.source === "demo" || (prefs.source === "auto" && !hasNetbird)
    // The `netbird` CLI is installed (looked up once, at start)
    property bool hasNetbird: false
    property bool _looked: false

    Loader {
        id: sourceLoader
        active: root._looked || root.prefs.source !== "auto"
        sourceComponent: root.useDemo ? demoSource : netbirdSource
    }
    Component {
        id: demoSource
        DemoSource {
            labMesh: prefs.labMesh
            labPeers: prefs.labPeers
            labLatency: prefs.labLatency
            labTrouble: prefs.labTrouble
            labTraffic: prefs.labTraffic
            labLazy: prefs.labLazy
        }
    }
    Component {
        id: netbirdSource
        NetbirdSource {
            savedTies: prefs.exitTies
            onTiesLearned: ties => prefs.set("exitTies", ties)
        }
    }

    CliRunner {
        id: lookup
        Component.onCompleted: run(["sh", "-c", "command -v netbird"], (out, err, code) => {
            root.hasNetbird = code === 0;
            root._looked = true;
        })
    }

    // What the NetBird source could not do, said once
    Connections {
        target: root.source
        ignoreUnknownSignals: true
        function onNotice(text) {
            root._toast("Abyss", text);
        }
    }

    readonly property alias prefs: prefs
    Prefs {
        id: prefs
    }

    // Sending files to a peer: one hub for the drop, the menu, Ctrl+V, the
    // launcher and the IPC. Each open view plays the outcome itself; with no
    // view open it comes as a notification instead
    readonly property alias send: hub
    SendHub {
        id: hub
        prefs: prefs
    }
    Connections {
        target: hub
        function onEnded(peerId, ok, text, failure) {
            if (hub.viewers === 0)
                root._sendNote(ok ? { "title": text, "advice": "" } : failure);
        }
        function onRefused(peerId, failure) {
            if (hub.viewers === 0)
                root._sendNote(failure);
        }
    }
    // One notification for a send: its sentence, and the advice when it failed
    function _sendNote(note) {
        if (note.advice)
            ToastService.showWarning(Connect.plainText(note.title), Connect.plainText(note.advice), "", "abyss-send");
        else
            root._toast(note.title);
    }

    // --- Actions (called by the scene's buttons and by the IPC) -------------
    // what: what was copied ("IP"), for the toast; one toast either way
    function copy(text, what) {
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", String(text)]);
        if (what)
            root._toast(what + " copied", String(text));
        else
            root._toast("Copied " + text);
    }

    // False when the host is not one ssh can safely be handed (says why).
    // The terminal is looked up first, so a missing one is said too.
    // prog: "ssh" (default) or "sftp"; link: { user, port } for this peer
    function ssh(host, terminal, link, prog) {
        if (!host)
            return false;
        const h = String(host), want = terminal || prefs.terminal, p = prog || "ssh";
        if (!Terminal.validHost(h)) {
            root._toast("Abyss", "Not opening " + p.toUpperCase() + ": \"" + h + "\" is not a plain host name or address");
            return false;
        }
        lookup.run(Terminal.lookupCommand(want), (out, err, code) => {
            const found = String(out).trim();
            if (code !== 0 || !found)
                root._toast("Abyss", Terminal.missingText(want));
            else
                Quickshell.execDetached(p === "sftp" ? Terminal.sftpCommand(found, h, link) : Terminal.sshCommand(found, h, link));
        });
        return true;
    }

    // Reaches a peer the way its card says: "ssh", "sftp" (a terminal),
    // "files" (the file manager), "vnc" or "rdp" (whichever viewer is
    // installed). First knocks on its port (2 s at most): a device that does
    // not answer gets a toast saying how to turn that on, and a missing
    // viewer one with the command that installs it (DMS adds a copy button)
    function reach(kind, peer) {
        if (!peer)
            return false;
        const host = peer.fqdn || peer.ip, link = prefs.linkOf(peer.id);
        if (!Connect.validHost(host)) {
            root._toast("Abyss", "Not opening " + kind + ": \"" + host + "\" is not a plain host name or address");
            return false;
        }
        const probe = root.source && !root.source.demo ? Connect.probeCommand(peer.ip || host, Connect.portOf(kind, link)) : null;
        if (!probe) {
            root._open(kind, host, link);
            return true;
        }
        prober.run(probe, (out, err, code) => {
            if (code === 0) {
                root._open(kind, host, link);
                return;
            }
            const port = Connect.portOf(kind, link);
            root._help(Connect.closedHelp(kind, peer.name, peer.kind === "phone", port));
        });
        return true;
    }
    function _open(kind, host, link) {
        if (kind === "ssh" || kind === "sftp") {
            root.ssh(host, prefs.terminal, link, kind);
            return;
        }
        lookup.run(Connect.lookupCommand(kind), (out, err, code) => {
            const program = String(out).trim(), cmd = program ? Connect.command(kind, program, host) : null;
            if (code === 0 && cmd) {
                Quickshell.execDetached(cmd);
                return;
            }
            lookup.run(Connect.packageManagerCommand(), pm => root._help(Connect.installHelp(kind, String(pm).trim())));
        });
    }
    // A toast with a title, a plain line and, when there is one, a command
    // to copy (DMS's toast shows a copy button for it)
    function _help(h) {
        ToastService.showWarning(h.title, h.details, h.command, "abyss-help");
    }
    CliRunner {
        id: prober
        timeout: 4000
    }

    // Lets the other peers SSH into this device, or stops letting them. The
    // setting is the switch (here, the menu, the IPC or Settings): NetBird
    // follows each change of it, never at start
    function shareSsh(on) {
        prefs.set("shareSsh", !!on);
    }
    Connections {
        target: prefs
        function onShareSshChanged() {
            if (root.source)
                root.source.shareSsh(prefs.shareSsh);
        }
    }

    // Three echoes to a peer, when asked (never on its own); the answer
    // comes as a toast. The demo mesh has nobody to answer: it says what it
    // made up
    CliRunner {
        id: pinger
        timeout: 12000
    }
    function ping(peer) {
        if (!peer || !root.source)
            return false;
        if (root.source.demo) {
            root._toast("Abyss", peer.name + ": " + Math.round(peer.latencyMs * 10) / 10 + " ms (made-up mesh)");
            return true;
        }
        const cmd = Ping.command(peer.ip);
        if (!cmd) {
            root._toast("Abyss", "Not pinging: \"" + peer.ip + "\" is not an address");
            return false;
        }
        root._toast("Abyss", "Pinging " + peer.name + "…");
        pinger.run(cmd, (out, err, code) => root._toast("Abyss", Ping.summary(peer.name, out, code)));
        return true;
    }

    function openUrl(url) {
        Qt.openUrlExternally(url);
    }

    // Every toast goes through here: names and notes may come from peers
    function _toast(title, text) {
        if (text === undefined)
            ToastService.showInfo(Connect.plainText(title));
        else
            ToastService.showInfo(Connect.plainText(title), Connect.plainText(text));
    }

    // The jellyfish's click: the one step that moves the connection forward
    function pressJelly() {
        const src = root.source;
        if (!src)
            return;
        const st = src.view.state;
        if (st === "needsLogin")
            src.login();
        else if (st === "stopped")
            src.startService();
        else
            src.toggle();
    }

    // The deep, in the bar's popout (the launcher, a keyboard shortcut).
    // Needs Abyss in the bar; otherwise says so
    function open() {
        if (BarWidgetService.triggerWidgetPopout("abyss"))
            return true;
        root._toast("Abyss", "Add Abyss to the bar to open it from here");
        return false;
    }

    // A peer by name, fqdn, IP or id, or by the start of its name when only
    // one peer starts that way (for the IPC and the launcher); null otherwise
    function findPeer(key) {
        return root.source ? Query.lookup(root.source.view.peers, key).peer : null;
    }

    // --- Internet exit -------------------------------------------------------
    // Where Internet goes out now, in words: "directly", "through studio",
    // "through Homelab (studio)", or "through Homelab: nobody online"
    function exitText() {
        const src = root.source;
        if (!src)
            return "";
        const g = prefs.exitGroup ? MyGroups.byId(prefs.groups, prefs.exitGroup) : null;
        if (g)
            return "through " + g.name + (src.exitNode ? " (" + src.exitNode + ")" : ": nobody online");
        return src.exitNode ? "through " + src.exitNode : "directly";
    }

    // Through one peer (its name), through a group of mine (its id: the
    // group lends its best member, MyGroups.pickExit), or "" to stop
    function setExit(peerName, groupId) {
        if (!root.source)
            return;
        _choosing = true;
        prefs.set("exitGroup", groupId || "");
        if (groupId)
            _followExitGroup(groupId);
        else
            root.source.setExitNode(peerName || "");
        _choosing = false;
    }
    property bool _choosing: false
    // Through an exit route no peer is known for yet: the next read shows
    // who carries it, and the source learns it (saved as exitTies)
    function setExitRoute(id) {
        if (!root.source)
            return;
        prefs.set("exitGroup", "");
        root.source.setExitRoute(id);
    }
    // A group of mine carries the exit: when its member goes offline, the
    // next best takes over. Runs on each read, never on its own.
    function _followExitGroup(id) {
        const g = MyGroups.byId(prefs.groups, id);
        if (!g)
            return;
        const src = root.source;
        const p = MyGroups.pickExit(src.view.peers, g.members, src.exitNode);
        if (p && p.name !== src.exitNode)
            src.setExitNode(p.name);
    }
    Connections {
        target: root.source
        function onViewChanged() {
            if (prefs.exitGroup !== "")
                root._followExitGroup(prefs.exitGroup);
        }
        // An exit chosen elsewhere (the bar's menu, a profile switch) ends
        // the group's
        function onExitNodeChanged() {
            if (root._choosing || prefs.exitGroup === "")
                return;
            const g = MyGroups.byId(prefs.groups, prefs.exitGroup), p = root.findPeer(root.source.exitNode);
            if (!g || !p || g.members.indexOf(p.id) < 0)
                prefs.set("exitGroup", "");
        }
    }

    // --- Notifications (off by default, never for a muted peer) -------------
    Connections {
        target: root.source
        function onPeerEvent(name, online) {
            if (!prefs.notifications)
                return;
            const p = root.findPeer(name);
            if (p && prefs.isMuted(p.id))
                return;
            root._toast(name + (online ? " is online" : " went offline"));
        }
    }

    // The IPC's way to a peer: "user@peer" or "peer"
    function _reachIpc(kind, key) {
        if (!root.source)
            return "Abyss is starting";
        const at = String(key || "").indexOf("@"), user = at > 0 ? key.slice(0, at) : "", name = at > 0 ? key.slice(at + 1) : key;
        const found = Query.lookup(root.source.view.peers, name), p = found.peer;
        if (!p)
            return Query.lookupError(name, found);
        if (user && !Connect.validUser(user))
            return "Refused: " + user + " is not a user name";
        if (user && (kind === "ssh" || kind === "sftp")) {
            const host = p.fqdn || p.ip;
            return root.ssh(host, prefs.terminal, { "user": user, "port": prefs.linkOf(p.id).port }, kind) ? "OK" : "Refused: " + host + " is not a plain host name";
        }
        return root.reach(kind, p) ? "OK" : "Refused: " + (p.fqdn || p.ip) + " is not a plain host name";
    }

    // dms ipc call abyss send <peer> <path>: the same send as a drop, with a
    // looked-up peer and a path checked and capped (SendFlow.ipcRequest)
    function _sendIpc(pair, path) {
        if (!root.source)
            return "Abyss is starting";
        const req = SendFlow.ipcRequest(pair, path);
        if (!req.ok)
            return "Refused: " + req.reason;
        const found = Query.lookup(root.source.view.peers, req.pair);
        if (!found.peer)
            return Query.lookupError(req.pair, found);
        const no = hub.sendTo(found.peer, req.items);
        return no ? "Refused: " + no : "OK";
    }

    // dms ipc call abyss open | status | toggle | connect | disconnect
    // dms ipc call abyss copy <peer> | ssh <peer | user@peer> | sftp | files | vnc | rdp <peer>
    // dms ipc call abyss send <peer> <absolute path or file:// URL>
    // dms ipc call abyss link <peer> <user|-> <port|-> | join <setup key> <url|-> | leave | share on|off
    // dms ipc call abyss exit <peer | group of mine | off>
    // dms ipc call abyss demo connected | disconnected | connecting | needsLogin | stopped | relayDown | relayUp
    IpcHandler {
        target: "abyss"

        // One line: state, then how many peers are online
        function status(): string {
            if (!root.source)
                return "Abyss is starting";
            const v = root.source.view;
            const on = v.peers.filter(p => p.online).length;
            return v.state + (v.state === "connected" ? " · " + on + "/" + v.peers.length + " online · Internet " + root.exitText() : "");
        }

        // Opens (or closes) the deep in the bar's popout
        function open(): string {
            return root.open() ? "OK" : "Abyss is not in the bar";
        }

        function toggle(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.toggle();
            return "OK";
        }

        function connect(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.connect();
            return "OK";
        }

        function disconnect(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.disconnect();
            return "OK";
        }

        // Copies a peer's IP to the clipboard
        function copy(peer: string): string {
            if (!root.source)
                return "Abyss is starting";
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            root.copy(p.ip);
            return p.ip;
        }

        // Three echoes to a peer: "Pinging…", then the answer as a toast
        function ping(peer: string): string {
            if (!root.source)
                return "Abyss is starting";
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            if (!p.online)
                return p.name + " is offline";
            return root.ping(p) ? "Pinging " + p.name : "Refused";
        }

        // Opens `ssh <peer>` in the terminal chosen in the settings; "user@peer"
        // logs in as that user (the user and port saved by `link` otherwise)
        function ssh(peer: string): string {
            return root._reachIpc("ssh", peer);
        }
        // Files over SFTP in a terminal, or in the file manager
        function sftp(peer: string): string {
            return root._reachIpc("sftp", peer);
        }
        function send(peer: string, path: string): string {
            return root._sendIpc(peer, path);
        }
        function files(peer: string): string {
            return root._reachIpc("files", peer);
        }
        // A remote desktop to the peer, in whichever viewer is installed
        function vnc(peer: string): string {
            return root._reachIpc("vnc", peer);
        }
        function rdp(peer: string): string {
            return root._reachIpc("rdp", peer);
        }

        // Remembers how to SSH to a peer: user and port ("-" for none), as a
        // phone running Termux wants (`link phone u0_a123 8022`)
        function link(peer: string, user: string, port: string): string {
            if (!root.source)
                return "Abyss is starting";
            const found = Query.lookup(root.source.view.peers, peer), p = found.peer;
            if (!p)
                return Query.lookupError(peer, found);
            const u = user === "-" ? "" : user, n = port === "-" ? "" : port;
            if (u && !Connect.validUser(u))
                return "Refused: " + u + " is not a user name";
            if (n && !Connect.validPort(n))
                return "Refused: " + n + " is not a port";
            prefs.setLink(p.id, u, n);
            return u || n ? p.name + ": " + (u ? u + "@" : "") + "…" + (n ? " port " + n : "") : p.name + ": forgotten";
        }

        // Joins this device to a mesh with a setup key (the dashboard's
        // Setup Keys) kept in a file; `url` is the management server when
        // self-hosted. The key itself is refused: typed here it would stay
        // in the shell history and on the command line of `dms`
        function join(keyFile: string, url: string): string {
            if (!root.source)
                return "Abyss is starting";
            if (!keyFile.startsWith("/"))
                return "Refused: give the full path of a file that holds the setup key, not the key itself (it would stay in your shell history). See https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#join-a-mesh";
            return root.source.joinFile(keyFile, url === "-" ? "" : url) ? "Joining" : "Refused: that path or its address is not usable (the address must be http(s))";
        }
        function leave(): string {
            if (!root.source)
                return "Abyss is starting";
            root.source.logout();
            return "OK";
        }

        // Lets the other peers SSH into this device: on | off
        function share(state: string): string {
            if (!root.source)
                return "Abyss is starting";
            const k = String(state || "").trim().toLowerCase();
            if (k !== "on" && k !== "off")
                return "Shared with SSH: " + (prefs.shareSsh ? "on" : "off");
            root.shareSsh(k === "on");
            return "SSH in this device: " + k;
        }

        // Internet through a peer, a group of mine (by name), or "off";
        // "" says where it goes out now
        function exit(target: string): string {
            if (!root.source)
                return "Abyss is starting";
            const k = String(target || "").trim().toLowerCase();
            if (k === "")
                return "Internet goes out " + root.exitText();
            if (k === "off" || k === "none") {
                root.setExit("", "");
                return "Internet exit off";
            }
            const g = prefs.groups.find(x => x.name.toLowerCase() === k);
            if (g) {
                root.setExit("", g.id);
                return "Internet " + root.exitText();
            }
            const found = Query.lookup(root.source.view.peers, k), p = found.peer;
            const route = root.source.looseExits.find(r => r.id.toLowerCase() === k);
            if (!p && route) {
                root.setExitRoute(route.id);
                return "Internet through the route " + route.id;
            }
            if (!p)
                return found.many.length ? Query.lookupError(target, found) : "No peer, group or exit route named " + target;
            root.setExit(p.name, "");
            return "Internet through " + p.name;
        }

        // Jumps the demo mesh to a state, to try the interface
        function demo(state: string): string {
            if (!root.source)
                return "Abyss is starting";
            if (!root.source.demo)
                return "Not in demo mode";
            root.source.setState(state);
            return root.source.view.state;
        }
    }
}
