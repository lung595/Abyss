# Abyss

Your [NetBird](https://netbird.io) mesh as a glowing deep sea, for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell).

You are the giant jellyfish. Every peer is a creature floating at the depth of its latency, tied to you by a tentacle that carries its live traffic: the more it uses, the thicker and brighter the tentacle, with pulses of light running toward you (download) or toward it (upload). Who uses the most is marked at a glance, and every creature shows its ↓/↑ rate. No clicks needed to read your network.

> **New in 0.1.0:** first preview. The interface is complete but runs on a **made-up demo mesh**; reading the real NetBird daemon comes next.

![The deep, connected](screenshots/connected.png)

## What you see

| In the deep | Means |
|---|---|
| The jellyfish (you), lit | Connected. Click it to connect or disconnect (or sign in / start the service) |
| A creature | A peer; its species says what it is: manta = server, lantern whale = VPS, fish = laptop, nautilus = desktop, seahorse = phone, squid = Raspberry Pi, turtle = NAS |
| Depth | Latency, on a log scale (1–320 ms, gauge on the right) |
| Tentacle width and pulses | Live traffic of that peer; **TOP CONSUMER** marks the biggest |
| A coral lantern on a tentacle | The relay a peer goes through; blinking orange = the relay stopped answering |
| A creature asleep on the floor | Offline |
| Caves on the floor | Networks and routes; click one to turn it on or off |
| The light of the surface | Internet. Drag it onto a peer to use it as exit node, drop it in the water to stop |

![A peer's card](screenshots/card.png)

**Click a creature** to open its card: live rates and a 60-second curve, copy its IP or name, SSH, open in the browser, use as exit node, favorite, mute, latency, connected since, last handshake, totals, networks it opens. <kbd>←</kbd> <kbd>→</kbd> (or the ‹ › arrows) step to the previous or next device without leaving the card.

**Type a name** to find a peer (favorites first), <kbd>Enter</kbd> opens its card, <kbd>Esc</kbd> closes.

| Relay down | Exit node, light theme |
|---|---|
| ![Relay down](screenshots/relay.png) | ![Exit node](screenshots/exit-light.png) |

## Surfaces

- **Bar**: a small jellyfish with the number of peers online. Click opens the deep, right click connects or disconnects.
- **Control Center**: a NetBird tile (toggle) with the deep underneath.
- **Desktop**: the deep as a window onto your wallpaper. It stays still until the pointer is over it.

![Control Center](screenshots/connected-cc.png)

## Keyboard and scripts

```sh
dms ipc call abyss status          # "connected · 8/10 online"
dms ipc call abyss toggle          # or connect / disconnect
dms ipc call abyss copy <peer>     # copies the peer's IP
dms ipc call abyss ssh <peer>      # SSH in your terminal
dms ipc call abyss demo <state>    # demo only: connected, disconnected, connecting,
                                   # needsLogin, stopped, relayDown, relayUp
```

## Settings

Offline peers on the floor, light pulses, keeping the desktop alive, notifications when a peer comes or goes (off by default; muted peers stay quiet), and the terminal used for SSH (automatic by default).

## Lightweight

- Nothing runs while no view is open: no timer, no reads.
- While a view is open, one 30 Hz timer moves the pulses and the marine snow; only this window redraws, never the whole shell. Backgrounds are painted once.
- *Reduce motion* turns every movement off.

Measured numbers will be added here before the first stable release.

## Privacy

- The plugin never talks to the network itself and has no telemetry.
- Peers, addresses and traffic stay in memory for the session; nothing is written to disk except your settings (favorites and muted peers included).
- Copy uses DMS's clipboard, SSH opens your own terminal.

## Install

```sh
git clone https://github.com/lung595/Abyss ~/.config/DankMaterialShell/plugins/Abyss
```

Then enable **Abyss** in DMS Settings → Plugins, and add it to the bar, the Control Center or the desktop.

## Development

```sh
gjs tests/mesh.test.js && gjs tests/layout.test.js && gjs tests/terminal.test.js
scripts/preview/render.sh connected "$PWD/out.png"   # offscreen renders from the demo mesh
```

## Changelog

### 0.2.0 — in progress (branch `lens`, not released yet)

- **Lens**: a soft magnetic lens follows the pointer and gently enlarges what it lights; the scroll wheel sets its strength. The pointer is a warm light in a darker, more immersive deep.
- **Groups**: never more than 5 things on screen (3–10 in settings). Busy, struggling and favourite peers stay alone; the rest gather in automatic groups that open when you hover them. Type anywhere to find, and everything else blurs.
- **Sonar fan**: the jellyfish sits at the top and peers fan out below it, farther when slower, with sonar rings in ms.
- **Grab and release**: drag any creature; it springs back to its place, like Orbit.
- **Peer card like Orbit**: the card rises and the creature dives toward it and rides up with it; on close it swims straight home.
- **Frosted glass card**: the deep shows through, blurred once as the card opens (nothing is re-blurred while it stays open). Every device gets the same compact height; the details scroll inside.
- **Step through devices** with ‹ › or <kbd>←</kbd> <kbd>→</kbd>: the circle stays still while the creature, the name and the status crossfade in place, and the previous creature fades back home.
- **The pointer light reveals the scenery** instead of glowing: a soft disc under the lens uncovers a reef in depth (far hills in a faint distant haze, rock spires and an arch, cliffs, the floor) with a little parallax, glowing coral tips, swaying kelp and gorgonians, sponges, anemones and a small shoal of fish passing now and then. Muted on purpose; it costs nothing measurable.
- Thinner traffic tentacles (a thread when idle, a ribbon when busy) and calmer motion.
- The jellyfish now has loose threads of light; each linked peer takes one over. Its bell fades smoothly between asleep and awake.
- Caves (routed networks) always glow a little, and burn when on. Their thread to the gateway only shows while you hover them, and leaves from above the name.
- Fixed: a traffic spike each time the view opened; grabbing moved only the tentacle.
- Still to come in 0.2.0: see the [Roadmap](#roadmap).

### 0.1.0 — 2026-09-26

- First preview: the whole deep (jellyfish, creatures by device type, traffic tentacles, relays, networks, exit node by drag, peer card, type to find) on a made-up demo mesh.
- Bar pill, Control Center tile and desktop widget; IPC; notifications; SSH in the terminal of your choice.

## Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

### Finishing 0.2.0 (branch `lens`)

- **Devices swim** to their new depth in their animal's gait instead of jumping (wired, being tuned).
- **A wake-up wave**: when you connect, light spreads from the jellyfish to each device; switched on, everything floats gently; switched off, the deep sleeps, dimmer and stiller (wired, being tuned).
- **Tentacles that hold their device**: the tip wraps around the creature, as if the jellyfish really held it.
- **The card first, then the creature**: both finish landing at the same moment.
- **A group view**:
  - hovering or clicking a group glides to it, centres it and zooms in until it fills most of the screen;
  - the rest gets much blurrier and a little darker;
  - the group's name and summary sit at the top centre; click the name to rename it, and a small ⚙ opens its settings.
- **The jellyfish as the only on/off switch**: the extra toggle goes, and a small ON/OFF word sits by the jellyfish.
- **Drop the Internet light into a group** to pick the exit node among its devices.
- **A cleaner layout**: one sector per relay, so no tentacle or lantern ever hides a device or a label.
- Measured CPU cost while a view is open, and fresh screenshots.

### Later

- **Smart search bar**: understands words and synonyms, not only names.
- **Smart tags**: added automatically (from the name, services, machine type) or by hand.
- **Use it from the launcher (Super+Space)**: `abyss >100ms`, `abyss proxmox`, `docker`… with a live preview.
- **Read the real NetBird daemon** (`netbird status --json`, only while a view is open), connect, disconnect, sign in, networks and profiles through the `netbird` CLI.
- Bar count kept fresh without polling while nothing is open.
- Bar pill options: icon only, with peers online, or with the total rate.
- Show online peers only, or all of them.
- Ping a peer from its card, on demand only (never in the background).
- Open the admin console, a reconnect shortcut, the daemon version.
- A compact list for very large meshes (30+ peers).
- Maybe, if asked: a one-click debug bundle for support, and client settings (SSH server, Rosenpass, connect at startup).

## Credits

- The idea of a NetBird plugin for DMS comes from **NetbirdStatus** by [Dadangdut33](https://github.com/Dadangdut33), in [dms-plugins](https://github.com/Dadangdut33/dms-plugins). Thank you!
- Built on [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [Quickshell](https://quickshell.org).

## License

MIT © lung595
