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
4. Switch the demo mesh between states with `dms ipc call abyss demo <state>` (`connected`, `disconnected`, `connecting`, `needsLogin`, `stopped`, `relayDown`, `relayUp`).

Tools: `gjs` (tests), `ffmpeg` (GIFs).

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

1. **Source**: `components/DemoSource.qml` stands in for NetBird. It serves made-up meshes (`DemoMesh.js`) shaped exactly like `netbird status --json`, with the same actions the real source will have. Reading the real daemon means writing a source with the same interface.
2. **View model**: `Mesh.js` turns what NetBird reports into the small model the scene draws.
3. **Layout**: `Layout.js` places everything (sonar fan, depth by latency); `Groups.js` gathers peers into shoals when there are more than `max`; `MyGroups.js` holds the user's own groups; `Query.js` filters for search.
4. **Scene**: `components/AbyssScene.qml` draws the deep, shared by the popout, the Control Center and the desktop.

**Main scene pieces.** `Jellyfish.qml` (you), `Creature.qml` + `CreatureShape.qml` (peers), `Tentacles.qml` (traffic), `Lantern.qml` (relays), `Cave.qml` (networks), `SurfaceSun.qml` + `LightShaft.qml` + `SunTree.qml` (Internet), `School.qml` + `GroupPeek.qml` (groups), `PeerCard.qml` (card), `HelpNote.qml` (refusals), `Reef*.qml/.js` and `Water.qml` (scenery), `FishBowl.qml` + `Bowl.js` + `SandLetters.qml` (desktop bowl).

**Motion.** `Spring.js` (grab and release) and `Swim.js` (moving to a new place) are pure functions driven by the scene clock.

**Help notes link to the docs.** `HelpNote.qml` opens `https://github.com/lung595/Abyss#<anchor>`; the anchors used in `AbyssScene.qml` (`explain(…)`) must exist as headings in `README.md`. Today: `internet-through-a-peer`. **Do not rename that heading** without updating the code.

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
├── tests/                # gjs tests for the pure .js logic (load.js: test helpers)
├── scripts/preview/      # offscreen renders and GIFs from the demo mesh
├── screenshots/          # images used by the docs
└── docs/GUIDE.md         # user guide
```

## Tests

```sh
for t in tests/*.test.js; do gjs "$t" || break; done
```

Run them before every commit. The pure `.js` files in `components/` are tested in `tests/<name>.test.js`; `tests/load.js` loads QML-flavoured JavaScript (`.pragma`, `.import`) into gjs.

## Screenshots and GIFs

```sh
scripts/preview/render.sh connected "$PWD/out.png"   # offscreen render from the demo mesh
scripts/preview/gif.sh gif-sun "$PWD/out.gif" 80      # a GIF, frame by frame (needs ffmpeg)
```

## Performance rules

Abyss must cost nothing while nobody looks at it. Keep these rules when changing the code:

- **Nothing runs while no view is open**: no timer, no reads.
- **Never loop a QML animation.** A running animation makes *every* shell window redraw at the display rate. One 30 Hz `Timer` (the scene clock) drives the pulses, the marine snow and the animals.
- **Paint once**: backgrounds and reef planes are painted once, then only moved with cheap transforms.
- **Honor DMS Reduce motion**: every movement stops.

## Conventions

- **Language**: code, comments, UI and docs in English.
- **Comments**: each file starts with a short comment saying what it is and why.
- **Privacy**: the plugin never talks to the network and has no telemetry. Nothing written to disk except settings through DMS.
- **Never refuse in silence**: anything the user cannot do shows a `HelpNote` saying why, linked to a README section.
- **Docs**: user-facing changes go in `docs/GUIDE.md` (and the README if they change installation or the basics), plus an entry in `CHANGELOG.md`.

## Releasing a version

1. Bump `version` in `plugin.json` ([Semantic Versioning](https://semver.org/)).
2. Move the `Unreleased` entries of `CHANGELOG.md` under the new version and date.
3. Refresh screenshots and GIFs if the look changed (`scripts/preview/`).
4. Run the tests, commit, then tag: `git tag v0.4.0 && git push --tags`.
