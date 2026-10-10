# Contributing

Everything needed to work on Abyss or take over the project.

## Contents

- [Development setup](#development-setup)
- [Architecture](#architecture)
- [Project layout](#project-layout)
- [Tests](#tests)
- [Screenshots and GIFs](#screenshots-and-gifs)
- [Performance rules](#performance-rules)
- [Conventions](#conventions)
- [Releasing a version](#releasing-a-version)

## Development setup

1. Clone the repository into the DMS plugin folder and enable it in **Settings → Plugins**:

   ```sh
   git clone https://github.com/lung595/Abyss ~/.config/DankMaterialShell/plugins/Abyss
   ```

2. Add at least one widget (Control Center, bar or desktop) to see your changes.
3. DMS reloads QML on save, but Qt keeps `components/` and `.js` files cached in the running shell: **run `dms restart`** after changing them.
4. Set **Mesh source** to *Test lab* to work without NetBird: the **Test lab** section then sets the number of peers, added latency, a trouble (silent or flapping peer, relay or management down, signed out, service stopped) and the traffic. `dms ipc call abyss demo <state>` still jumps between states (`connected`, `disconnected`, `connecting`, `needsLogin`, `stopped`, `relayDown`, `relayUp`).

Tools: `gjs` (unit tests), Python with PySide6 (integration tests: `pip install PySide6-Essentials`), `ffmpeg` (GIFs).

## Architecture

`plugin.json` declares a **composite** plugin with the id `abyss`:

| Component | File | Role |
| --- | --- | --- |
| Daemon | `AbyssDaemon.qml` | The one engine every surface shares: the mesh source, actions that leave the shell (copy, SSH, browser), notifications and IPC |
| Widget | `AbyssWidget.qml` | Bar pill, bar popout and Control Center tile |
| Desktop | `AbyssDesktop.qml` | The deep in a round fishbowl on the wallpaper |
| Launcher | `AbyssLauncher.qml` | Launcher provider (`abyss`) |
| Settings | `AbyssSettings.qml` | Settings page |

**Data flow.**

1. **Source**: two objects with the same interface (`view`, `networks`, `exitNode`, `profiles`, `watch()`, `connect()`, `setExitNode()`…); the daemon creates only the one picked by the **Mesh source** setting (`auto` checks `command -v netbird` once at start).
   - `components/NetbirdSource.qml` reads the daemon through the `netbird` CLI. `Netbird.js` (pure) builds every command and reads every answer; `CliRunner.qml` runs commands one at a time (argv lists, never a shell). Reads and actions have separate queues, so a sign-in waiting in the browser never stops the reads.
   - `components/DemoSource.qml` serves made-up meshes (`DemoMesh.js`) shaped exactly like `netbird status --json`.
   - **Exit nodes**: a peer's `networks` in the status only lists routes going through it *now*. Which peers can lend Internet comes from `netbird networks list` (`0.0.0.0/0` routes), matched to peers by `Netbird.exitMap`.
2. **View model**: `Mesh.js` turns what NetBird reports into the small model the scene draws.
3. **Layout**: `Layout.js` places everything (sonar fan, depth by latency); `Groups.js` gathers peers into shoals when there are more than `max`; `MyGroups.js` holds the user's own groups; `Query.js` filters for search.
4. **Scene**: `components/AbyssScene.qml` draws the deep, shared by the popout, the Control Center and the desktop.

**Main scene pieces.** `Jellyfish.qml` (you), `Creature.qml` + `CreatureShape.qml` (peers), `Tentacles.qml` (traffic), `Lantern.qml` (relays), `Cave.qml` (networks), `SurfaceSun.qml` + `LightShaft.qml` + `SunTree.qml` (Internet), `School.qml` + `GroupPeek.qml` (groups), `PeerCard.qml` (card), `HelpNote.qml` (refusals), `Reef*.qml/.js` and `Water.qml` (scenery), `FishBowl.qml` + `Bowl.js` + `SandLetters.qml` (desktop bowl).

**Motion.** `Spring.js` (grab and release) and `Swim.js` (moving to a new place) are pure functions driven by the scene clock.

**Help notes link to the guide.** `HelpNote.qml` opens `https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#<anchor>`; every anchor passed to it must exist as a heading in `docs/GUIDE.md`. **Do not rename those headings** without updating the code.

Settings are read through `components/Prefs.qml`, a reactive view shared by every surface.

## Project layout

```
Abyss/
├── plugin.json           # manifest: id, version, components, permissions
├── AbyssDaemon.qml       # shared engine (see Architecture)
├── AbyssWidget.qml       # bar pill, popout and Control Center tile
├── AbyssDesktop.qml      # desktop fishbowl
├── AbyssLauncher.qml     # launcher provider
├── AbyssSettings.qml     # settings page
├── components/           # the scene (.qml) and pure logic (.js)
├── tests/                # gjs tests (cli.test.js: the app's parser; app.sh: launcher, offscreen; install.sh: installer in a scratch HOME)
│   └── qml/              # QML integration tests, fake netbird, DMS / Quickshell stand-ins
├── app/                  # the standalone app (Quickshell only, no DMS import)
│   ├── shell.qml         # the window and its IPC entry point
│   ├── abyss             # the `abyss` command (POSIX sh), single instance
│   ├── abyss.desktop     # menu entry
│   ├── usage.txt         # what `abyss --help` prints
│   └── components/       # Cli.js (command-line parser, pure), Palette.js (the app's colours, pure), Theme.qml (singleton with the DMS Theme API, so shared components render unchanged; scheme follows the system, `ABYSS_SCHEME=light|dark` forces it)
├── install-app.sh        # installs / removes the app under ~/.local
├── .github/workflows/    # CI: tests/run.sh on every push
├── scripts/preview/      # offscreen renders and GIFs from the demo mesh
├── screenshots/          # images used by the docs
└── docs/GUIDE.md         # user guide
```

## Tests

```sh
tests/run.sh                          # every test
PYTHON=/path/to/python tests/run.sh   # a Python that has PySide6
```

Run them before every commit; CI runs them on every push (`.github/workflows/tests.yml`).

- **Unit tests** (`gjs`): the pure `.js` files in `components/` are tested in `tests/<name>.test.js`; `tests/load.js` loads QML-flavoured JavaScript (`.pragma`, `.import`) into gjs.
- **Integration tests** (PySide6, skipped without it): `tests/qml/*.test.qml` run through `tests/qml/qmltest.py`, which plays Quickshell's `Process` with a real `QProcess` and puts a fake `netbird` (`tests/qml/fake-netbird`, outputs taken from the NetBird client's code) first on the `PATH`. They cover `CliRunner`, `NetbirdSource`, `AbyssDaemon`, the send engine and `SendHub` (with fake `scp`, `wl-paste` and `zenity`; `touch $FAKE_NB/missing.<program>` makes a program fail to start). **Scene tests** (`tests/scene/*.test.qml`, `tests/scene/run.sh`, `qml-qt6` with the fake shell modules of `scripts/preview/imports`) drive the scene itself: menu, Ctrl+V. `FAKE_NB_DELAY=0.3` makes every fake call slow, to try a slow machine.
- `NOTES.md` logs every bug found in review: where, why, the fix and the test that shows it.

## Screenshots and GIFs

```sh
scripts/preview/render.sh connected "$PWD/out.png"   # offscreen render from the demo mesh
scripts/preview/gif.sh gif-sun "$PWD/out.gif" 80      # a GIF, frame by frame (needs ffmpeg)
```

## Performance rules

Abyss must cost nothing while nobody looks at it. Keep these rules when changing the code:

- **Nothing runs while no view is open**: no timer, no reads (except one read of NetBird when the shell starts, so the bar shows the real state).
- **One command at a time**: NetBird is read every 2 s while a view is open, never piled up; `networks list` and `profile list` only on opening, after a change, and every 10th read.
- **Never loop a QML animation.** A running animation makes *every* shell window redraw at the display rate. One 30 Hz `Timer` (the scene clock) drives the pulses, the marine snow and the animals.
- **Paint once**: backgrounds and reef planes are painted once, then only moved with cheap transforms.
- **Honor DMS Reduce motion**: every movement stops.

## Conventions

- **Language**: code, comments, UI and docs in English.
- **Comments**: each file starts with a short comment saying what it is and why.
- **Privacy**: the plugin never talks to the network and has no telemetry. Nothing written to disk except settings through DMS. Commands are argv lists, never shell lines; anything that comes from another machine (peer names, route ids) goes after `--`.
- **QML**: qualify every property access (`root.x`, not `x`), above all inside callbacks, where an unqualified write can miss the object.
- **Never refuse in silence**: anything the user cannot do shows a `HelpNote` saying why, linked to a README section.
- **Docs**: user-facing changes go in `docs/GUIDE.md` (and the README if they change installation or the basics), plus an entry in `CHANGELOG.md`.

## Releasing a version

1. Bump `version` in `plugin.json` ([Semantic Versioning](https://semver.org/)).
2. Move the `Unreleased` entries of `CHANGELOG.md` under the new version and date.
3. Refresh screenshots and GIFs if the look changed (`scripts/preview/`).
4. Run the tests, commit, then tag: `git tag v0.5.0 && git push --tags`.
