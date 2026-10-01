# Changelog

All notable changes to Abyss are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- **Your real NetBird mesh**: peers, traffic, relays, networks, profiles and the Internet light come from the NetBird daemon through its `netbird` command: one read when the shell starts, then every 2 s only while a view is open. Connect, disconnect, sign in, start the service, switch profile, turn networks on or off and choose where Internet goes out all run the matching command; anything that fails says why.
- **Setting "Mesh source"**: automatic (NetBird when installed, else the test lab), NetBird, or test lab.
- **Test lab** in the settings, shown while it is the mesh source: a mesh of 1 to 120 made-up peers (or the home, work and crowd meshes), latency added to every peer, a trouble to try (a peer that stops answering, a peer that keeps dropping out, a relay or the management server down, signed out, service stopped) and calm, normal or rush-hour traffic. A one-line summary and *Reset* under its title. In memory only; NetBird is never touched. While the lab is the source, the profile chip wears a flask and the bowl's sand line starts with "test lab", so a made-up mesh is never taken for yours.
- **Tests**: QML integration tests through real processes against a fake `netbird`, `tests/run.sh` to run every test, and CI on every push. The tentacle layout check (P60) also runs on the test lab's meshes, from 1 to 120 peers.

- **Where Internet goes out, everywhere**: a small still sun in the bar pill while it goes out through a peer; the beam's traffic (↓ ↑) under the light's name; `dms ipc call abyss exit ""` says where it goes out, and `status` ends with it ("· Internet through studio"). After each change a short word under the light confirms it for two seconds ("Direct", "Through studio").
- **Rename a group from its title**: with a group of yours open, click its name at the top; a small ⚙ beside it opens the group's menu (Internet through it, rename, ungroup, or keep an automatic group).
- **Exit routes named after no peer**: listed by their own name at the bottom of the light's menu (and `dms ipc call abyss exit <route>`). Once one is used, the peer carrying it is learned and kept in the settings, so it lends from then on.
- **Choosing and groups**: pointed at, the light says how it is used ("Drag onto a device · click for the list"); a closed group lending Internet wears a small sun beside its name; when a group of yours hands the Internet to another member, a note says who took over.
- **When Internet goes wrong**: "Switching…" under the light until NetBird confirms the new exit; disconnected, the light stays, dim, and a click says "Connect first"; when the peer lending Internet goes offline, a note says so and names the next best peer.

### Changed

- **The jellyfish is the only on/off switch**: the switch at the top left is gone; a small ON / OFF under "you" says the state, and a click on the jellyfish connects or disconnects.
- Documentation split into `README.md`, `docs/GUIDE.md`, `CHANGELOG.md`, `ROADMAP.md` and `CONTRIBUTING.md`.
- **Internet through a peer, the NetBird way**: a peer can lend Internet when one of NetBird's exit routes (`0.0.0.0/0`) goes through it. A route is matched to the peer seen carrying it, or the peer it is named after (`exit-atlas`); otherwise dropping the light there says to name the route after the peer.
- **Commands pick the right peer**: `dms ipc call abyss ssh a` no longer picks whoever comes first when several peers start with "a"; it names them.

### Fixed

- **SSH with no terminal installed** did nothing, without a word: the terminal is now looked up first, and a missing one is said (the chosen one by name, or that none was found), with where to pick another.
- Copying an address from a peer's card showed two toasts.
- **SSH to a peer whose name looks like an option** (`-oProxyCommand=…`) could run a command on this machine; such names are refused, and `--` always ends ssh's options.
- Creatures were guessed from letters inside other words (`chair-pc` drawn as a laptop, `banana` as a NAS).
- Two peers with the same short name could be mixed up.
- "Connected since" read a field NetBird never prints (`statusSince` instead of `lastStatusUpdate`).
- A failing Internet switch was retried every 2 s while a group carried the Internet.
- A view kept watching a source that had been swapped.

## 0.3.0 - 2026-09-27

### Added

- **Never refused in silence**: drop the light on a peer that cannot lend Internet and it bounces home, with a short note saying why and what to do, and a GitHub mark that opens the right part of the docs. While you carry it, such peers step further back and the hint under the light starts with ⊘.
- **From the launcher**: Super+Space, type `abyss`: open the deep, connect, choose where Internet goes out, copy an address or SSH to a peer. Nothing runs between two uses; it reads NetBird once when you open it.
- **Livelier animals**: between trips every creature has its own life (the fish beats its tail and wanders, the manta flaps its wings, the squid jets upward, the seahorse sways, the turtle paddles, the whale and the nautilus roll slowly). Inside an open group the members live too. Calmer asleep, still with *Reduce motion*; idle CPU unchanged (3.7 % vs 3.6 % of one core).
- **Click the light** for where Internet can go, as a small file tree: your groups as folders, then the peers in no group, quickest first, and "Stop". What is in use wears a small turning sun.
- **Your own groups**: right-click a creature or a group to add it to a group, start one, rename, ungroup, or keep an automatic group. They come first and never reshuffle.
- **Internet through a whole group**: drop the light in the middle of a group; it stays there, tied to the member lending the Internet, and the next best member takes over if that one goes offline. Also `dms ipc call abyss exit <group or peer>`.
- **Preview before dropping on a group**: a ring where the light will rest and faint tentacles to every member; once dropped, a bead of light runs out to each of them.
- **Setting "Open groups"**: on hover and click (default), on hover only, or on click only.
- **Choose the screens for the desktop bowl** from a "Desktop" section in the settings.
- **How to use**: the docs explain every option, with pictures and GIFs.

- **Where Internet goes out, everywhere**: a small still sun in the bar pill while it goes out through a peer; the beam's traffic (↓ ↑) under the light's name; `dms ipc call abyss exit ""` says where it goes out, and `status` ends with it ("· Internet through studio"). After each change a short word under the light confirms it for two seconds ("Direct", "Through studio").
- **Choosing and groups**: pointed at, the light says how it is used ("Drag onto a device · click for the list"); a closed group lending Internet wears a small sun beside its name; when a group of yours hands the Internet to another member, a note says who took over.
- **When Internet goes wrong**: "Switching…" under the light until NetBird confirms the new exit; disconnected, the light stays, dim, and a click says "Connect first"; when the peer lending Internet goes offline, a note says so and names the next best peer.

### Changed

- The light **glides** to its new place in 0.6 s instead of jumping, and the beam follows it; **Escape** while carrying puts it back; a peer's right-click menu has "Use for Internet".
- With a group open, the light can be taken from the middle and dropped on one member: it rests above that member, and goes back to the middle for the whole group.
- While you carry the light, only the peers that can lend Internet stay bright. In a peer's card, "Use for Internet" appears only when it can.
- Resting the light on a group opens it, so it can be left on any member; carrying it out of the bubble closes it.
- **No bar over the bowl**: who is online and the live totals are written in the bed of sand. Click the jellyfish to connect; right-click it to switch profile or show and hide offline peers.
- **Card**: received and sent sit either side of the creature's medallion; address and name share one line, each with its copy button.
- **The light that lends Internet** casts a soft beam onto the peer, holds still while you look around, and takes a deliberate pull to lift.
- **TOP CONSUMER** is told by its caption alone; its label no longer changes colour.

### Fixed

- A group could close again at once when reopened; leaving now only counts once the pointer has been inside, or has clearly moved on.
- A click, or resting the pointer, opened a creature or a group a hand-width away; it now takes the pointer being on it.

## 0.2.0 - 2026-09-27

### Added

- **Lens**: a soft magnetic lens follows the pointer and gently enlarges what it lights; the scroll wheel sets its strength.
- **Groups**: never more than 5 things on screen (3–10 in settings). Busy, struggling and favourite peers stay alone; the rest gather in automatic groups that open as the camera glides toward them. Type anywhere to find.
- **Sonar fan**: the jellyfish sits at the top and peers fan out below it, farther when slower, with sonar rings in ms.
- **Grab and release**: drag any creature; it springs back to its place.
- **Step through devices** with ‹ › or <kbd>←</kbd> <kbd>→</kbd> on the card.
- **The pointer light reveals the scenery**: a reef in depth with parallax, glowing coral tips, swaying kelp and a small shoal of fish passing now and then.
- **The desktop widget is a fishbowl**: round glass with a rim, highlights and a soft shadow, water tinted by your theme and a bed of sand.

- **Where Internet goes out, everywhere**: a small still sun in the bar pill while it goes out through a peer; the beam's traffic (↓ ↑) under the light's name; `dms ipc call abyss exit ""` says where it goes out, and `status` ends with it ("· Internet through studio"). After each change a short word under the light confirms it for two seconds ("Direct", "Through studio").
- **Choosing and groups**: pointed at, the light says how it is used ("Drag onto a device · click for the list"); a closed group lending Internet wears a small sun beside its name; when a group of yours hands the Internet to another member, a note says who took over.
- **When Internet goes wrong**: "Switching…" under the light until NetBird confirms the new exit; disconnected, the light stays, dim, and a click says "Connect first"; when the peer lending Internet goes offline, a note says so and names the next best peer.

### Changed

- **Peer card**: the card rises and the creature rides up with it; frosted glass, blurred once as it opens; the same compact height for every device.
- Thinner traffic tentacles (a thread when idle, a ribbon when busy) and calmer motion.
- The jellyfish has loose threads of light; its bell fades smoothly between asleep and awake.
- Caves always glow a little and burn when on; their thread to the gateway only shows on hover.
- A readable card in the bowl: the water darkens and the glass fades behind it.
- Inside a group, the rest of the deep darkens and the water bends like a lens around it.
- Devices keep their side when their traffic changes; caves keep clear of them.
- The top consumer label only moves when another device is clearly busier (30 % more).

### Fixed

- A traffic spike each time the view opened.
- Grabbing moved only the tentacle.

## 0.1.0 - 2026-09-26

### Added

- First preview: the whole deep (jellyfish, creatures by device type, traffic tentacles, relays, networks, exit node by drag, peer card, type to find) on a made-up demo mesh.
- Bar pill, Control Center tile and desktop widget; IPC; notifications; SSH in the terminal of your choice.
