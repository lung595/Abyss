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
