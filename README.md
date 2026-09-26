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

**Click a creature** to open its card: live rates and a 60-second curve, copy its IP or name, SSH, open in the browser, use as exit node, favorite, mute, latency, connected since, last handshake, totals, networks it opens.

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

### 0.1.0 — 2026-09-26

- First preview: the whole deep (jellyfish, creatures by device type, traffic tentacles, relays, networks, exit node by drag, peer card, type to find) on a made-up demo mesh.
- Bar pill, Control Center tile and desktop widget; IPC; notifications; SSH in the terminal of your choice.

## Roadmap

No promises, no dates.

- **Read the real NetBird daemon** (`netbird status --json`, only while a view is open), connect, disconnect, sign in, networks and profiles through the `netbird` CLI.
- Bar count kept fresh without polling while nothing is open.
- Open the admin console, reconnect shortcut, daemon version.
- A compact list for very large meshes (30+ peers).
- Known limit: a relay lantern can be hidden behind a nearby label.

## Credits

- The idea of a NetBird plugin for DMS comes from **NetbirdStatus** by [Dadangdut33](https://github.com/Dadangdut33), in [dms-plugins](https://github.com/Dadangdut33/dms-plugins). Thank you!
- Built on [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [Quickshell](https://quickshell.org).

## License

MIT © lung595
