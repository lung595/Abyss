# Abyss

Your [NetBird](https://netbird.io) mesh as a glowing deep sea, for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell).

You are the giant jellyfish. Every peer is a creature floating at the depth of its latency, tied to you by a tentacle that carries its live traffic: the more it uses, the thicker and brighter the tentacle, with pulses of light running toward you (download) or toward it (upload). Who uses the most is marked at a glance, and every creature shows its ↓/↑ rate. No clicks needed to read your network.

> **New in 0.3.0:** your own groups, Internet through a peer or a whole group by carrying the light of the surface (or picking it from a small tree), livelier animals, a launcher entry (Super+Space, `abyss`), a borderless fishbowl, and a guide to every option below. Anything you cannot do now says why. **Next release:** Abyss reads your real NetBird daemon (`netbird` CLI) when it is installed, and keeps the made-up demo mesh otherwise ([Mesh source](#settings)).

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
| The light of the surface | Internet. Drag it onto a peer to use it as exit node, drop it in the water to stop ([how](#internet-through-a-peer)) |

| Relay down | Exit node, light theme |
|---|---|
| ![Relay down](screenshots/relay.png) | ![Exit node](screenshots/exit-light.png) |

The full guide, option by option, is in [How to use](#how-to-use).

## How to use

Every refusal in Abyss says why in a short note, with a GitHub mark that opens the matching section below.

### Connect and disconnect

Click **the jellyfish** (you) to connect or disconnect; if NetBird needs it, the same click signs you in or starts the service. Right-click it for more: connect or disconnect, switch to the next profile, show or hide offline peers. From the bar, a right click on the small jellyfish does the same, and `dms ipc call abyss toggle` too.

![The deep, connected](screenshots/connected.png)

### Open a peer's card

Click a creature. Its card rises from the bottom and the creature flies onto it: live rates and a 60-second curve, copy its IP or name, SSH, open in the browser, use it for Internet, favorite, mute, latency, connected since, last handshake, totals, networks it opens. Click outside it or press <kbd>Esc</kbd> to close.

![Opening a card](screenshots/card-open.gif)

<kbd>←</kbd> <kbd>→</kbd> (or the ‹ › arrows) step to the previous or next device without leaving the card.

![Stepping between cards](screenshots/card-step.gif)

### Open a group

Peers that look alike swim together as a shoal ("3 busy", "2 quiet"). Rest the pointer on one, or click it: the camera glides in and the group opens in the middle, every member within reach. Move the pointer away to come back. The **Open groups** setting chooses how: on hover and click (default), on hover only, or on click only.

![Opening a group](screenshots/group-open.gif)

### Make your own groups

Right-click a creature or a group: add it to one of your groups, start a new one, rename it, ungroup it, or keep an automatic group as yours. Your groups come first and never reshuffle.

![The right-click menu](screenshots/groups-menu.png)

### Internet through a peer

The light at the surface is your Internet. **Drag it onto a peer** and all your Internet traffic goes out through that peer; a soft beam falls from the light onto it. Drag the light back to the surface, or drop it in open water, to go out directly again. <kbd>Esc</kbd> while carrying puts it back. Resting it on a group opens the group, so you can leave it on a member.

![Carrying the light onto a peer](screenshots/internet.gif)

**Only a peer that offers an exit node can lend Internet** (NetBird's rule). While you carry the light, the others step back and, over one of them, the light says so; drop it there anyway and it bounces home with a note. To let a device lend Internet, turn it into an exit node in NetBird's dashboard: *Network Routes* › *Add route* › *Exit node*, see [NetBird's guide](https://docs.netbird.io/how-to/configuring-default-routes-for-internet-traffic).

![Dropping the light on a peer that cannot lend Internet](screenshots/cant-lend.gif)

**Click the light** instead of dragging it for the same choice as a list: your groups as folders (click a name for the whole group, its arrow to pick one member), then the other peers that can lend, quickest first, and "Stop". A small turning sun marks the one in use. Right-clicking a peer offers "Use for Internet" too.

![The light's menu](screenshots/internet-menu.png)

### Internet through a whole group

Carry the light into one of your groups and let it go in the middle. It stays there, tied by a tentacle to the member lending the Internet (NetBird uses one exit node at a time) and by dashed lines to the ones ready to take over: if that member goes offline, the next best one (direct first, then the lowest latency) takes over by itself. Take the light from the middle and drop it on one member to use only that one; drag it out of the group to stop.

![The light in the middle of a group](screenshots/internet-group.png)

### Turn a network on or off

The caves on the floor are your networks and routes. Click one to turn it on or off, or open the list from the network button at the top.

![Networks](screenshots/networks.png)

### Find a peer

Just type a name: the deep keeps the matches (favorites first) and dims the rest. <kbd>Enter</kbd> opens the first one's card, <kbd>Esc</kbd> clears.

![Finding a peer](screenshots/find.png)

### From the launcher

Press Super+Space and type `abyss`: "Open Abyss" opens the deep from the bar; below it, connect, where Internet goes out (a sun marks the one in use), and, as you type a name (`abyss vega`), copy its address or SSH to it.

### On the desktop

Add Abyss in Settings › Desktop Widgets: a round fishbowl on your wallpaper, the deep inside it. It stays still until the pointer is over it; who is online and the live totals are poured into its sand. Pick its screens in the settings.

![The fishbowl](screenshots/desk.png)

### Settings

- **Desktop**: which screens show the bowl (all by default).
- **Open groups**: on hover and click (default), hover only, or click only. Carrying the light always opens them.
- **Show offline peers**: asleep on the floor, or hidden.
- **Light pulses**: the pulses of traffic along the tentacles, on or off.
- **Keep the desktop alive**: the bowl keeps moving when the pointer is away (off by default, to cost nothing).
- **Things on screen**: how many creatures and groups the deep shows before it gathers the rest into shoals (3 to 10, 5 by default).
- **Notifications**: when a peer comes or goes (off by default; muted peers stay quiet).
- **Terminal for SSH**: the one used for SSH (automatic by default).
- **Mesh source**: your NetBird daemon, or a made-up demo mesh to try Abyss. Automatic (default) reads NetBird when the `netbird` command is installed.

## Surfaces

- **Bar**: a small jellyfish with the number of peers online. Click opens the deep, right click connects or disconnects.
- **Control Center**: a NetBird tile (toggle) with the deep underneath.
- **Launcher** (Super+Space, type `abyss`): "Open Abyss" opens the deep from the bar; below it, the quick steps — connect, where Internet goes out (a sun marks the one in use), and, as you type a name (`abyss vega`), copy its address or SSH to it.
- **Desktop**: a round fishbowl on your wallpaper, with a sandy bed, glass and a water line; the deep lives inside it. It stays still until the pointer is over it. Who is online and the live totals are written in its sand, in a fine line of coloured sand; choose which screens show it in the settings.

![The fishbowl desktop widget, with a made-up mesh](screenshots/desk.png)

![Control Center](screenshots/connected-cc.png)

## Keyboard and scripts

```sh
dms ipc call abyss open            # opens the deep from the bar
dms ipc call abyss status          # "connected · 8/10 online"
dms ipc call abyss toggle          # or connect / disconnect
dms ipc call abyss copy <peer>     # copies the peer's IP
dms ipc call abyss ssh <peer>      # SSH in your terminal
dms ipc call abyss exit <target>   # Internet through a peer or one of your
                                   # groups; "off" to stop
dms ipc call abyss demo <state>    # demo only: connected, disconnected, connecting,
                                   # needsLogin, stopped, relayDown, relayUp
```

## Lightweight

- Nothing runs while no view is open: no timer, no reads (one read of NetBird when the shell starts, so the bar shows the real state).
- While a view is open, NetBird is read every 2 s, one command at a time, never piled up.
- While a view is open, one 30 Hz timer moves the pulses and the marine snow; only this window redraws, never the whole shell. Backgrounds are painted once.
- *Reduce motion* turns every movement off.

Measured numbers will be added here before the first stable release.

## Privacy

- The plugin never talks to the network itself and has no telemetry. It reads NetBird through its local `netbird` command, only while a view is open, and never through a shell (no name or address can run anything).
- Peers, addresses and traffic stay in memory for the session; nothing is written to disk except your settings (favorites, muted peers, your groups and the group carrying the Internet included).
- Copy uses DMS's clipboard, SSH opens your own terminal.

## Install

```sh
git clone https://github.com/lung595/Abyss ~/.config/DankMaterialShell/plugins/Abyss
```

Then enable **Abyss** in DMS Settings → Plugins, and add it to the bar, the Control Center or the desktop.

## Development

```sh
tests/run.sh                                          # every test (see below)
scripts/preview/render.sh connected "$PWD/out.png"   # offscreen renders from the demo mesh
scripts/preview/gif.sh gif-sun "$PWD/out.gif" 80      # the README GIFs, frame by frame (needs ffmpeg)
```

- **Unit tests** (`tests/*.test.js`, need `gjs`): every pure JavaScript file in `components/`.
- **Integration tests** (`tests/qml/`, need PySide6: `pip install PySide6-Essentials`): the NetBird source, the command runner and the daemon, through real processes, against a fake `netbird` (`tests/qml/fake-netbird`) whose answers follow the NetBird client's code. Skipped when PySide6 is missing.
- CI runs both on every push (`.github/workflows/tests.yml`).
- `NOTES.md` logs every bug found in review and how it was fixed.

## Changelog

### Unreleased

- **Your real NetBird mesh**: peers, traffic, relays, networks, profiles and the Internet light now come from the NetBird daemon, through its `netbird` command, only while a view is open. Connect, disconnect, sign in, start the service, switch profile, turn networks on or off and pick where Internet goes out all run the matching `netbird` command; anything that fails says why. New **Mesh source** setting (automatic, NetBird, demo).
- **Internet through a peer, the NetBird way**: a peer can lend Internet when one of NetBird's exit routes (`0.0.0.0/0`) goes through it. NetBird does not say which peer serves a route until it is used, so a route is matched to the peer it is named after ("exit-atlas") or the one seen carrying it; dropping the light on a peer whose route cannot be found says to name the route after it.
- **Safer SSH**: a peer whose name looks like an option (`-o…`) is refused, and `--` always ends ssh's options.
- **Commands pick the right peer**: `dms ipc call abyss ssh a` no longer picks whoever comes first when several peers start with "a"; it names them.
- Fixes: creatures guessed from letters inside other words (`chair-pc` drawn as a laptop), two peers with the same short name mixed up, "connected for" empty with the real daemon, a failing Internet switch retried every 2 s.
- Tests: QML integration tests and CI; see [Development](#development).

### 0.3.0 — 2026-09-27

- **Never refused in silence**: drop the light on a peer that cannot lend Internet and it bounces home, with a short note saying why and what to do, and a GitHub mark that opens the right part of this README. While you carry it, such peers step further back and the hint under the light starts with ⊘.
- **How to use**: this README now explains every option, with pictures and GIFs.
- **From the launcher**: Super+Space, type `abyss` — open the deep, connect, choose where Internet goes out, copy an address or SSH to a peer, without leaving the keyboard. Nothing runs between two uses; it reads NetBird once when you open it.
- **Livelier animals**: between trips every creature now has its own life — the fish beats its tail and wanders, the manta flaps its wings, the squid squeezes and jets upward, the seahorse sways upright, the turtle paddles, the whale and the nautilus roll slowly — and now and then the ones that can turn look the other way. Inside an open group the members live too (they were still). Calmer asleep, still with *Reduce motion*, and nothing runs while nobody looks: it rides the scene's existing clock, moving the shapes without repainting them (idle CPU unchanged: 3.7 % vs 3.6 % of one core, same session).
- **Click the light** for where Internet can go, as a small file tree: each of your groups is a folder — click its name for the whole group, or its arrow to unfold it and pick one of its peers — then the peers in no group, quickest first, and "Stop". What is in use wears a small turning sun (still with *Reduce motion*). No dragging needed. Picked from there or dropped, the light now **glides** to its new place in 0.6 s instead of jumping, and the beam follows it; **Escape** while carrying puts it back; a peer's right-click menu has "Use for Internet" too.
- **From the whole group to one member, and back**: with a group open, take the light up from the middle and drop it on one member — it now rests above that member (it used to vanish), and goes back to the middle for the whole group.
- **Only what can lend Internet**: while you carry the light, the peers that can lend it (they offer an exit node) stay bright and the others step back; over one that cannot, the light says so and dropping it changes nothing. A group only ever lends through such a member. In a peer's card, "Use for Internet" appears only when it can.
- **See what "the whole group" means before letting go**: carrying the light over the middle of an open group shows a ring where it will rest and faint tentacles to every member; once dropped, a bead of light runs out to each of them, once.
- **Your own groups**: right-click a creature or a group to add it to a group, start one, rename, ungroup, or keep an automatic group. They come first and never reshuffle.
- **Internet through a whole group**: drop the light in the middle of a group; it stays there, tied to the member lending the Internet, and the next best member takes over if that one goes offline. Drag it out of the group to stop. Also `dms ipc call abyss exit <group or peer>`.
- **Carry the Internet into groups**: resting the light on a group opens it (the groups hold still meanwhile), you can then leave it on any member; carrying it out of the bubble closes it.
- **Setting "Open groups"**: on hover and click (default), on hover only, or on click only.
- **Choose the screens for the desktop bowl**: a "Desktop" section at the top of Abyss's settings (all displays, or pick them one by one), from the Plugins page or from Settings › Desktop Widgets.
- **No bar over the bowl**: who is online and the live totals are written in the bed of sand, a fine line of your theme's accent colour poured against the glass, like a sand bottle, following the bowl's curve. Click the jellyfish to connect; right-click it to connect or disconnect, switch profile, or show and hide offline peers (everywhere, not just in the bowl). The bar stays in the bar popout and the Control Center.
- **Card**: received and sent now sit either side of the creature's medallion, on small cards in their own colours (received in the peer's colour, sent in yours, as the curve below), and the address and the name share one line, each with its copy button.
- **The light that lends Internet**: a soft beam now falls from it onto the peer (it was a hard rectangle). The light holds still while you look around the deep, follows that peer when you drag it, and takes a deliberate pull to lift, so a click or a brush no longer carries it away.
- **TOP CONSUMER** is told by its caption alone; its label no longer changes colour.
- **Fixed**: a group could close again at once when reopened (the camera carries it to the middle, away from the pointer, which then counted as having left); leaving now only counts once the pointer has been inside, or has clearly moved on.
- **Fixed**: a click, or resting the pointer, opened a creature or a group a hand-width away; it now takes the pointer being on it (the lens still aims from afar).

### 0.2.0 — 2026-09-27

- **Lens**: a soft magnetic lens follows the pointer and gently enlarges what it lights; the scroll wheel sets its strength. The pointer is a warm light in a darker, more immersive deep.
- **Groups**: never more than 5 things on screen (3–10 in settings). Busy, struggling and favourite peers stay alone; the rest gather in automatic groups. Rest the pointer on one and the camera glides and zooms towards it until it opens in the middle of the view; move away and it glides back. Type anywhere to find, and everything else blurs.
- **Sonar fan**: the jellyfish sits at the top and peers fan out below it, farther when slower, with sonar rings in ms.
- **Grab and release**: drag any creature; it springs back to its place, like Orbit.
- **Peer card like Orbit**: the card rises and the creature dives toward it and rides up with it; on close it swims straight home.
- **Frosted glass card**: the deep shows through, blurred once as the card opens (nothing is re-blurred while it stays open). Every device gets the same compact height; the details scroll inside.
- **Step through devices** with ‹ › or <kbd>←</kbd> <kbd>→</kbd>: the circle stays still while the creature, the name and the status crossfade in place, and the previous creature fades back home.
- **The pointer light reveals the scenery** instead of glowing: a soft disc under the lens uncovers a reef in depth (far hills in a faint distant haze, rock spires and an arch, cliffs, the floor) with a little parallax, glowing coral tips, swaying kelp and gorgonians, sponges, anemones and a small shoal of fish passing now and then. Muted on purpose; it costs nothing measurable.
- Thinner traffic tentacles (a thread when idle, a ribbon when busy) and calmer motion.
- The jellyfish now has loose threads of light; each linked peer takes one over. Its bell fades smoothly between asleep and awake.
- Caves (routed networks) always glow a little, and burn when on. Their thread to the gateway only shows while you hover them, and leaves from above the name.
- **The desktop widget is a fishbowl**: round glass with a rim, highlights and a soft shadow on your wallpaper, water tinted by your theme and a bed of sand at the bottom. The deep fills the whole belly of the bowl without spilling past the glass. The top bar only shows while you use it. A group opening inside the bowl melts into the water at its edges.
- **A readable card in the bowl**: opening a device darkens the bowl's water and fades its glass behind the card, instead of a dark box spilling past the glass.
- **Inside a group**: the rest of the deep darkens and fades around it, and the group sits in a lit pool, its home; round it the water bends like a lens instead of a drawn circle. The opening animation is unchanged.
- **Steadier fan**: devices keep their side when their traffic changes, instead of swimming across the view; caves keep clear of them.
- **The top consumer label stops flickering**: its filled, coloured label only moves to another device when that one is clearly busier (30 % more).
- Fixed: a traffic spike each time the view opened; grabbing moved only the tentacle.
- Still to come: see the [Roadmap](#roadmap).

### 0.1.0 — 2026-09-26

- First preview: the whole deep (jellyfish, creatures by device type, traffic tentacles, relays, networks, exit node by drag, peer card, type to find) on a made-up demo mesh.
- Bar pill, Control Center tile and desktop widget; IPC; notifications; SSH in the terminal of your choice.

## Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

### Internet, the whole journey

Sending your Internet through a peer (a NetBird exit node) should explain itself at every step. The full list, from the user's side; ✓ = already in 0.3.0.

**Knowing where you stand**
- ✓ The light at the surface is your Internet; its label says where it goes out ("Internet via studio", or just "Internet" when it goes out directly).
- ✓ A soft beam falls from it onto the peer that lends it, and follows that peer when you drag it.
- The bar pill shows a small sun while your Internet goes out through a peer, so you know it away from the deep too.
- The beam's label shows the traffic going out through it (↓ ↑), and the card of the lending peer says "Lends you Internet".

**Choosing a peer**
- Hovering the light says what it does: "Drag onto a device to go out through it".
- ✓ While you carry it, the peers that can lend Internet (they offer an exit node) stay bright and the others dim, so you only aim at what works; dropping on one that cannot says why.
- ✓ Drop it on a peer: "Internet through X".
- ✓ Click the light (no dragging needed): a small file tree — your groups as folders (the name picks the whole group, the arrow unfolds it to pick one member), the peers in no group, and "Stop"; a turning sun marks what is in use.
- ✓ Wherever it is picked, the light glides to its new place rather than jumping.
- ✓ A peer's card: "Use for Internet" / "Lends you Internet ✓", only on a peer that can.
- ✓ The same in a peer's right-click menu.
- ✓ Escape while carrying puts the light back where it was.

**Choosing a group**
- ✓ Carrying the light over a shoal opens it; drop on a member for that one only. The light then rests just above that member, so you see who lends it, and you can take it up from there: onto another member, or back to the middle for the whole group.
- ✓ Drop it in the middle of the group for the whole group: the group lends its best member online, and switches by itself when that one goes offline.
- ✓ **While you carry it over the middle**, a ring appears where it will rest, faint tentacles reach out to every member, and the light says "Internet through all of Homelab": you see what dropping will do before you let go.
- ✓ **Once dropped**, the light settles in the middle and a bead of light runs once along the tentacles; the member that lends it is lit, the others wait on dotted lines.
- The members waiting on dotted lines say "ready to take over" when the lens is on them.
- With the group closed, its shoal wears a small sun and the beam falls on it, labelled "Internet via Homelab · studio".
- When the group switches member, a short note says so ("studio went offline, now via nas").
- ✓ Right-click a group: "Internet through it" / "Stop Internet through it"; ✓ right-click a creature to make a group of your own.

**Stopping or changing**
- ✓ Drag the light out of the group to stop it there.
- ✓ Drag the light back up to the surface, or anywhere empty: back to your own connection.
- ✓ Dropping it on another peer or group simply moves it there.
- A word under the light for a moment ("Direct", "Through studio") confirms each change.

**When something goes wrong**
- While NetBird switches, the light pulses once and says "Switching…"; if it fails, it goes back and says why.
- The lending peer goes offline (alone, not in a group): the beam goes out, the light turns to a warning colour with "studio is offline", and a click offers the next best peer.
- Disconnected: the light is dim and cannot be carried ("Connect first").

**Everywhere**
- ✓ Same gestures in the bar popout, the Control Center and the desktop bowl; ✓ `dms ipc call abyss exit <peer | group | off>`, plus `exit` with no argument to say where Internet goes out now.
- Reduce motion: no pulse and no travelling light, only the end states.

### Next

- **Tentacles that hold their device**: the tip wraps around the creature, as if the jellyfish really held it.
- **The card first, then the creature**: both finish landing at the same moment.
- **Rename a group**: click its name at the top of the group view; a small ⚙ opens its settings.
- **The jellyfish as the only on/off switch**: the extra toggle goes, and a small ON/OFF word sits by the jellyfish.
- **A cleaner layout**: one sector per relay, so no tentacle or lantern ever hides a device or a label.
- **Shoals**: the creatures of a group swim together like a real school of fish (only while you watch).
- **A goldfish companion** in every view (bar popout, Control Center, desktop): it waves when you click it and lives its life, eats, sleeps with little *z z z*, and cleans the bowl now and then. Still while nobody looks.
- Measured CPU cost while a view is open, and fresh screenshots.
- Naming a group types in the view: it needs keyboard focus, which the desktop widget may not get (the name stays "Group n" there; rename it from the popout).

### Later

- **Smart search bar**: understands words and synonyms, not only names.
- **Smart tags**: added automatically (from the name, services, machine type) or by hand.
- **Search the launcher by speed or tags**: `abyss >100ms`, `abyss proxmox`, `docker`… (the launcher shows rows, not the live scene: "Open Abyss" opens it).
- ✓ **Read the real NetBird daemon** (unreleased, see the changelog).
- Exit routes named after no peer: list them in the light's menu by name, or tie one to a peer once.
- Peers kept idle by NetBird's lazy connections: drawn as reachable rather than asleep.
- Bar count kept fresh without polling while nothing is open.
- Bar pill options: icon only, with peers online, or with the total rate.
- Show online peers only, or all of them.
- Ping a peer from its card, on demand only (never in the background).
- Open the admin console, a reconnect shortcut, the daemon version.
- A compact list for very large meshes (30+ peers).
- Maybe, if asked: a one-click debug bundle for support, and client settings (SSH server, Rosenpass, connect at startup).

## Credits

- The idea of a NetBird plugin for DMS comes from **NetbirdStatus** by [Dadangdut33](https://github.com/Dadangdut33), in [dms-plugins](https://github.com/Dadangdut33/dms-plugins). Thank you!
- The fishbowl desktop widget (and the goldfish to come) is a nod to Gumball and Darwin's bowl in *The Amazing World of Gumball* (Cartoon Network); everything here is drawn from scratch, no character is reproduced.
- The GitHub mark in the help notes is GitHub's logo, used only to link to this README, as [GitHub's logo guidelines](https://github.com/logos) allow.
- Built on [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [Quickshell](https://quickshell.org).

## License

MIT © lung595
