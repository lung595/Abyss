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
