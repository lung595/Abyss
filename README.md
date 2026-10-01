<div align="center">

# Abyss

**Your [NetBird](https://netbird.io) mesh as a glowing deep sea, for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell).**

You are the giant jellyfish. Every peer is a creature floating at the depth of its latency,
tied to you by a tentacle lit by its live traffic.

![The deep, connected](screenshots/connected.png)

[Getting started](#getting-started) · [Usage](#usage) · [Settings](#settings) · [Troubleshooting](#troubleshooting) · [User guide](docs/GUIDE.md) · [Changelog](CHANGELOG.md)

</div>

> [!NOTE]
> **Abyss reads your real NetBird daemon** through the `netbird` command when it is installed, and opens its test lab, a made-up mesh, otherwise. Choose with the **Mesh source** [setting](#settings).

## Getting started

### Requirements

| Dependency | Version | Needed for |
| --- | --- | --- |
| DankMaterialShell | 1.6.0 or newer | Everything |
| NetBird client (`netbird` command) | Any recent | Your real mesh; without it, Abyss shows its test lab |
| A polkit agent | Any (DMS has one) | *Optional*: starting the NetBird service from Abyss |
| A terminal emulator | Any | *Optional*: SSH to a peer |

### 1. Install

Abyss is a preview and is installed by hand:

```sh
git clone https://github.com/lung595/Abyss ~/.config/DankMaterialShell/plugins/Abyss
```

Then click **Settings → Plugins → *Scan for plugins***.

### 2. Enable

In **Settings → Plugins**, turn **Abyss** on. The launcher entry works right away (Super+Space, type `abyss`).

### 3. Add a widget

> [!IMPORTANT]
> **Abyss does not replace any existing widget.** Enabling it is not enough to see the deep: **add at least one of its widgets** yourself.

| Where | How to add it |
| --- | --- |
| **Control Center** | Open the Control Center, enter **edit mode**, add the **NetBird** tile from *Abyss* |
| **Bar** | **Settings → Appearance → DankBar Layout**, add **Abyss** to a section |
| **Desktop** | **Settings → Desktop Widgets**, add **Abyss** (a round fishbowl on your wallpaper) |

### 4. First steps

1. **Open the deep** from the widget you added.
2. **Click the jellyfish** (you) to connect or disconnect.
3. **Click a creature** to open its card; **drag the light of the surface** onto a peer to send your Internet through it.

## Features

| Relay down | Exit node, light theme |
| --- | --- |
| ![Relay down](screenshots/relay.png) | ![Exit node](screenshots/exit-light.png) |

- **Read your mesh at a glance**: depth is latency, tentacle width is live traffic, **TOP CONSUMER** marks the busiest peer.
- **A creature per device type**: manta = server, whale = VPS, fish = laptop, nautilus = desktop, seahorse = phone, squid = Raspberry Pi, turtle = NAS.
- **Internet through a peer or a whole group**, by carrying the light of the surface.
- **Your own groups**, plus automatic shoals that keep the view uncluttered.
- **Peer cards**: live rates, copy, SSH, open in the browser.
- **Everywhere**: bar, Control Center, desktop fishbowl and launcher.
- **Never refused in silence**: every refusal says why and links to the docs.
- **Lightweight and private**: nothing runs while no view is open.

## Usage

| In the deep | Means / action |
| --- | --- |
| The jellyfish (you) | Lit = connected. Click: connect or disconnect. Right-click: profile, offline peers |
| A creature | A peer. Click: open its card. Right-click: groups, Internet |
| Depth | Latency (1–320 ms, log scale) |
| Tentacle width and pulses | Live traffic of that peer |
| A coral lantern on a tentacle | A relay; blinking orange = the relay stopped answering |
| A creature asleep on the floor | Offline |
| Caves on the floor | Networks and routes; click one to turn it on or off |
| The light of the surface | Internet; drag it onto a peer to go out through it |
| A shoal ("3 busy") | A group; hover or click to open it |

**Find a peer**: just type its name. **Launcher**: Super+Space, `abyss`, then connect, choose where Internet goes out, or `abyss vega` to copy or SSH.

### Internet through a peer

**Drag the light of the surface onto a peer**: all your Internet traffic goes out through it. Drag the light back to the surface to go out directly again. **Click the light** to pick from a list instead.

![Carrying the light onto a peer](screenshots/internet.gif)

> [!NOTE]
> **Only a peer that offers an exit node can lend Internet** (NetBird's rule). Elsewhere, the light bounces back with a note. To turn a device into an exit node, in NetBird's dashboard: *Network Routes* › *Add route* › *Exit node*. See [NetBird's guide](https://docs.netbird.io/how-to/configuring-default-routes-for-internet-traffic).
>
> **Name the exit route after its peer** (for example `exit-atlas` for *atlas*): NetBird does not tell which peer serves a route until it is in use, so Abyss matches routes to peers by name.

📖 Cards, groups, Internet through a whole group, networks and the desktop fishbowl are explained step by step, with GIFs, in the **[user guide](docs/GUIDE.md)**.

## Settings

**Settings → Plugins → Abyss** (the *Desktop* section is also in **Settings → Desktop Widgets**).

| Section | Setting | Default |
| --- | --- | --- |
| Desktop | Screens showing the fishbowl | All |
| | Keep the desktop alive | Off |
| The deep | Things on screen (3 to 10) | 5 |
| | Open groups: hover and click, hover only, click only | Hover and click |
| | Show offline peers | On |
| | Light pulses | On |
| Peers | Notifications when a peer comes or goes | Off |
| | Terminal for SSH | Automatic |
| Source | Mesh source: automatic, NetBird, test lab | Automatic (NetBird when installed) |
| Test lab | Mesh: home (10), work (5), crowd (30) or a custom size (1 to 120 peers) | Home |
| | Added latency (0 to 400 ms) | 0 ms |
| | Trouble: a peer stops answering, a peer keeps dropping out, a relay or the management server down, signed out, service stopped | None |
| | Traffic: calm, normal, rush hour | Normal |

The **Test lab** section only shows while the test lab is the mesh source. It lives in memory and never touches NetBird; its title sums it up in one line and *Reset* brings back the quiet home mesh.

## Command line and keybindings

```sh
dms ipc call abyss open            # open the deep from the bar
dms ipc call abyss status          # "connected · 8/10 online"
dms ipc call abyss toggle          # or connect / disconnect
dms ipc call abyss copy <peer>     # copy the peer's IP
dms ipc call abyss ssh <peer>      # SSH in your terminal
dms ipc call abyss exit <target>   # Internet through a peer or one of your groups; "off" to stop
dms ipc call abyss demo <state>    # test lab only: connected, disconnected, connecting,
                                   # needsLogin, stopped, relayDown, relayUp
```

Bind them in your compositor, for example in niri: `Mod+A { spawn "dms" "ipc" "call" "abyss" "open"; }`, or in Hyprland: `bind = SUPER, A, exec, dms ipc call abyss open`.

## Troubleshooting

| Problem | Solution |
| --- | --- |
| Nothing changed after enabling | Add one of its widgets, see [Add a widget](#3-add-a-widget) |
| The peers shown are not mine | The test lab is shown: install the NetBird client, or set **Mesh source** to *NetBird* |
| "Service stopped" while NetBird runs | The `netbird` command cannot reach the daemon: check `netbird status` in a terminal |
| The light says to name the route after the peer | NetBird does not say which peer serves an unused exit route: name it after the peer in NetBird's dashboard, see [Internet through a peer](#internet-through-a-peer) |
| The light bounces back from a peer | That peer is not an exit node, see [Internet through a peer](#internet-through-a-peer) |
| A group stays "Group n" on the desktop | The desktop widget may not get keyboard focus: rename it from the bar popout |

## Privacy

The plugin never talks to the network and has no telemetry. It reads NetBird through its local `netbird` command, never through a shell. Peers and traffic stay in memory; only your settings (favorites, muted peers, groups) are saved by DMS. Details in the [user guide](docs/GUIDE.md#privacy).

## Documentation

| File | Content |
| --- | --- |
| [docs/GUIDE.md](docs/GUIDE.md) | Full user guide |
| [CHANGELOG.md](CHANGELOG.md) | What changed in each version |
| [ROADMAP.md](ROADMAP.md) | Ideas for the future |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Architecture, tests and release process, for anyone working on the code |

## Credits

The idea of a NetBird plugin for DMS comes from **NetbirdStatus** by [Dadangdut33](https://github.com/Dadangdut33) ([dms-plugins](https://github.com/Dadangdut33/dms-plugins)). The fishbowl is a nod to *The Amazing World of Gumball*, drawn from scratch. The GitHub mark is used only to link to these docs, as [GitHub's logo guidelines](https://github.com/logos) allow. Built on [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [Quickshell](https://quickshell.org).

## License

[MIT](LICENSE) © lung595
