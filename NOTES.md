# Review notes

A working log of the code review of 0.3.0 and of what was changed after it:
every bug found, its fix (or why it is still open), and how it was checked.
Newest work at the bottom of each section.

## Fixed

### 1. Device kind guessed from words inside other words
- **Where**: `components/Mesh.js`, `kindOf`.
- **Bug**: the patterns had no word boundaries, so `chair-pc` and
  `hairdresser` became laptops ("air"), `banana` a NAS ("nas"), `ghost` and
  `nodejs-dev` servers ("host", "node").
- **Fix**: each kind lists long words that may sit anywhere in the name
  (`thinkpad`, `proxmox`…) and short ones that must be a whole word of it
  (`air`, `nas`, `pi`, `host`, `node`…). Words are split on anything but
  letters and digits, and also tried without a trailing number (`rpi4`,
  `nas01`).
- **Checked**: 13 new cases in `tests/mesh.test.js`; every peer of the demo
  meshes keeps the creature it had before (45 peers, 0 change).

### 2. SSH to a peer whose name looks like an option
- **Where**: `components/Terminal.js`, `AbyssDaemon.qml` (`ssh`, IPC `ssh`).
- **Bug**: the host was its own argument (no shell injection), but nothing
  stopped ssh from reading it as an option: a peer named
  `-oProxyCommand=…` built `kitty ssh -oProxyCommand=…`, which runs a
  command locally. Peer names come from other people's machines once the
  real daemon is read.
- **Fix**: `validHost` accepts only a plain name or address (letters,
  digits, `. _ : % [ ] -`, never a leading `-`); `sshCommand` returns null
  otherwise, and puts `--` before the host in every case. The daemon says
  why it does not open SSH (toast), and the IPC answers "Refused: …"
  instead of "OK".
- **Checked**: 10 new cases in `tests/terminal.test.js`.

### 3. A command picked whichever peer came first
- **Where**: `AbyssDaemon.qml` (`findPeer`, IPC `copy`, `ssh`, `exit`),
  used by the launcher too.
- **Bug**: after the exact match, any peer whose name *started* with the
  word was taken, the first one in the list: `dms ipc call abyss ssh a`
  opened SSH to atlas or aurora depending on latency order.
- **Fix**: `Query.lookup` (pure): exact name, fqdn, address or id; then the
  start of a name only when a single peer starts that way. Otherwise the
  IPC answers "Several peers start with a: atlas, aurora".
- **Checked**: 11 new cases in `tests/groups.test.js`.

### 4. Two peers with the same short name
- **Where**: `components/Mesh.js` (`parse`).
- **Risk**: a peer's name is its fqdn's first label, and the exit node,
  `findPeer`, notifications and the demo all go by name. Two peers named
  `pc` in different domains would have been mixed up. NetBird normally
  keeps labels unique within one account, so this is defensive.
- **Fix**: `_unique` gives clashing peers as many fqdn labels as it takes
  (`pc.home`, `pc.work`), else their address. Names that do not clash stay
  short.
- **Checked**: 3 new cases in `tests/mesh.test.js`.

### 5. "Connected since" would always be empty with the real daemon
- **Where**: `components/Mesh.js` (`peerOf`).
- **Bug**: the peer's time of its last state change was read from
  `statusSince`, a key NetBird never prints; the client's JSON calls it
  `lastStatusUpdate` (`client/status/status.go`). The demo mesh used the
  same wrong key, so nothing showed it.
- **Fix**: read `lastStatusUpdate`; the demo and the tests use it too.
- **Checked**: `tests/netbird.test.js` parses a status shaped from the
  client's own structs.

### 6. "Can lend Internet" read from the wrong field
- **Where**: `components/Mesh.js` (`exit`), and the whole Internet light.
- **Bug**: a peer was taken as an exit node when its `networks` held
  `0.0.0.0/0`. With the real daemon, a peer's `networks` only lists the
  routes going through it *right now* (`AddPeerStateRoute` in the client's
  route manager), so only the exit node already in use would have shown,
  and the light could never be dropped anywhere else.
- **Fix**: `Mesh.js` now tells both apart: `lending` (Internet goes through
  it now) and `exit` (it can lend). The NetBird source widens `exit` from
  `netbird networks list`: every `0.0.0.0/0` (or `::/0`) route belongs to
  the peer seen carrying it, or the peer it is named after
  (`Netbird.exitMap`).
- **Limit, open**: NetBird's CLI never says which peer serves a route that
  is not in use. A route named after nobody (e.g. "Office Exit") can only
  be matched once it has been used; until then dropping the light on that
  peer says to name the route after the peer. See "Open" below.

### 7. The NetBird source (new)
- **What**: `components/NetbirdSource.qml`, same interface as
  `DemoSource`, picked by the new **Mesh source** setting (`auto` by
  default: NetBird when `netbird` is installed, else the demo). Only the
  source in use exists (a `Loader` in `AbyssDaemon.qml`).
- **How**: `components/Netbird.js` (pure, tested) builds every command and
  reads every answer; `components/CliRunner.qml` runs commands one at a
  time. Reads (`status --json` every 2 s, `networks list` and `profile
  list` when needed) and actions (`up`, `down`, `networks select`…) have
  their own queues, so a sign-in waiting in the browser never stops the
  reads. Nothing runs while no view is open.
- **Privacy**: argv lists only, no shell; network ids go after `--`;
  nothing written to disk; what is learned about exit routes stays in
  memory.
- **Errors**: every failed action says why in a toast (the same note at
  most once per 30 s) and the light goes back where it was.

### 8. CliRunner gave a command's output to another command's callback
- **Where**: `components/CliRunner.qml` (found by the integration test
  while writing it).
- **Bug**: a callback that queued new commands started a process from
  inside `_finish`, which then started another one over it: the output of
  `networks list` reached the `profile list` callback, one run in two.
- **Fix**: `_next` never starts a job while one runs or while it is
  already starting one (`_starting`).
- **Checked**: `tests/qml/CliRunner.test.qml` fails on the old code and
  passes on the new; `NetbirdSource.test.qml` passed 4 runs out of 4.

### 9. A view kept watching a source that was gone
- **Where**: `components/AbyssScene.qml` (`_watch`).
- **Bug**: when the source changed while a view was open, the old one was
  never released and the new one never watched (it only mattered once the
  source could change: the Mesh source setting).
- **Fix**: the view keeps the object it watches and swaps it.

## Tests

`tests/run.sh` runs everything: the gjs unit tests, then the QML
integration tests (`tests/qml/`, need PySide6) against a fake `netbird`
(`tests/qml/fake-netbird`) whose outputs follow the real client's code:
- `CliRunner.test.qml`: order, callbacks, skip, a missing program.
- `NetbirdSource.test.qml`: reads, exit node moves (and refusals), caves,
  connect / disconnect, a failed action in the middle, profiles, a stopped
  daemon, and nothing running once no view watches.
- `Daemon.test.qml`: the source chosen by the setting, the IPC.

## Open

- **Exit routes named after nobody** (see 6): a later step could list them
  in the light's menu by route id, or let the user tie a route to a peer
  once (kept in the settings).
- **Lazy connections**: with NetBird's lazy connections on, idle peers are
  reported `Idle` and drawn asleep although they are reachable.
- **`netbird up` for a sign-in** opens the browser through the CLI; on a
  machine where it cannot, the login URL is not shown in Abyss yet.
- **Starting the service** uses `pkexec netbird service start`, which needs
  a polkit agent (DMS has one).
- Not tried against a live NetBird daemon from this environment: the
  outputs come from the client's source code (cloned at 82e5428, 2026-09-30).

### 10. A failing exit was retried on every read
- **Where**: `components/NetbirdSource.qml` (`setExitNode`), driven by
  `AbyssDaemon._followExitGroup`.
- **Bug**: with Internet through a group of mine, each read picks the
  group's best member; when switching to it failed, the next read (2 s
  later) asked for it again, running a failing command every 2 s.
- **Fix**: an exit that just failed is not asked again for 30 s.
- **Checked**: a step in `NetbirdSource.test.qml`.

### 11. The bar and the launcher knew nothing before a view opened
- **Where**: `components/NetbirdSource.qml`, `AbyssLauncher.qml`.
- **Bug**: the demo had a mesh from the start; the NetBird source read
  nothing until a view opened, so the bar pill showed "Service stopped",
  and the launcher's first rows offered to start the service. The launcher
  also read the view right after asking for a read the NetBird source only
  answers later.
- **Fix**: one read at start (then nothing until a view opens). The
  launcher asks for its rows again once, when the read it asked for lands
  (never on the reads of an open view, so no loop).
- **Checked**: a step in `Daemon.test.qml`.
- **Still open**: the bar count goes stale while no view is open (roadmap:
  "Bar count kept fresh without polling").

### 12. The fake netbird lost changes made side by side (tests only)
- **Where**: `tests/qml/fake-netbird`. Found by the first CI run: GitHub's
  runner is slower than the machine the tests were written on.
- **Bug**: each call loads, changes and saves its state; a test's `_set`
  beside an action could be undone by it (the action saved what it had
  loaded before), so "up" did not fail when told to.
- **Fix**: calls take a file lock; reads never save. `FAKE_NB_DELAY`
  slows every call down to try a slow machine: 6 runs out of 6 passed at
  0.3 s per call. CI actions moved to their Node 24 versions.

### 13. `networks list` on every read when there is nothing to list
- **Where**: `components/NetbirdSource.qml` (`_read`).
- **Bug**: an empty list of networks (no routes, or a stopped daemon) made
  every read (every 2 s) ask `netbird networks list` again: one process
  too many each time.
- **Fix**: asked once, then every 10th read and after each change.
