# Changelog

All notable changes to Abyss are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- **The Abyss app, first step** (`app/`): Abyss as an app of its own, without DankMaterialShell, on Quickshell alone (`qs`, no DMS import under `app/`). The `abyss` command (POSIX `sh`, words only as `"$@"`) starts one window, or hands its request to the one already running through Quickshell IPC, so a second launch starts no second process; closing the window ends the process (no tray, no background). `abyss`, `abyss send <device> [files…]`, `abyss peer <device>`, `abyss map`, `abyss settings [category]`, `--help`, `--version`. `Cli.js` is pure: it validates and caps every word (count, length, device-name charset, absolute files, no control character) and answers with a short error and the guide anchor. `./install-app.sh` installs the command and `abyss.desktop` under `~/.local` only, `--uninstall` removes exactly that. The window is a placeholder until the views land. A word starting with `-` is handed to the running instance like any other (never read as a `qs` option), the working directory is validated like the words, the window's app id is `abyss` (`QS_APP_ID`) to match the desktop entry, and the installer leaves a folder, entry or command that is not Abyss's alone and removes only the folders it created.
- **Send engine** (`Send.js`, `SendRunner.qml`): sends files and folders to a device with `scp`, as an argument list with `--` before the paths, the card's user and port, and the SFTP protocol forced so the destination never reaches a remote shell. Items and the destination folder are checked first (absolute paths, 100 items, 200 GB, size looked at with `du -l`, so an item inside another is not taken for missing); a failure is explained in one sentence with advice and a link to the guide (refused login, changed key, SSH off, device unreachable, no space, folder missing, send stopped for taking too long, no `scp`). No password prompt (batch mode), nothing created or running until the first send. Not wired to any view yet.
- **Wake engine** (`Wake.js`, `WakeRunner.qml`): wakes a sleeping device with a Wake-on-LAN packet. `Wake.js` checks the MAC address, picks the route (direct, or through an online peer of the device's network), builds the argument lists and words each refusal with its advice; `WakeRunner.qml` runs them only on demand, with the tools checked first and the same hermetic fake `ssh` and `wakeonlan` in the tests. Not wired to a view yet.
- **Send a file, three ways, one scene**: right-click a creature → *Send a file…* / *Send a folder…* (a `zenity` picker), press Ctrl+V on its open card (files copied in the file manager, read with `wl-paste`), or use the launcher (`abyss send`) and `dms ipc call abyss send <device> <path>` (absolute path or `file://` URL, validated and capped). All of them play the same short "grab the file" scene (the file appears, the tentacle carries it, it drops in), drawn by a 30 Hz timer that only runs while it plays; the progress then runs along the creature's tentacle and it glows once when the send went through. *Reduce motion* skips the scene. With no view open, a notification says how it went. A refusal (device offline, another send under way, nothing copied, a missing tool) says why and links to the guide.
- **Tests for every send path**: `tests/qml/SendHub.test.qml` drives the real hub with fake `scp`, `wl-paste` and `zenity` (paste, picker chosen, cancelled and missing, busy, offline, the three modes), `tests/scene/SendPaths.test.qml` drives the scene (menu, Ctrl+V, view counting, no drop target) offscreen.
- **Setting** *Folder files are sent to* (default `~/Downloads` on the device).

### Removed

- **Drag-and-drop file sending**: dropping a file on a creature is gone. It could not work in practice (the view closes as soon as you click elsewhere), so the right-click menu is the main way: *Send a file…* / *Send a folder…*, then Ctrl+V on an open card, the launcher and `dms ipc call abyss send`. Dragging the surface light to give Internet through a peer or a group is unchanged.

### Fixed

- Ctrl+V on an open card now finds the peer (it looked it up by the wrong id and never pasted); two *Send a file…* pickers can no longer be open at once; a view is counted once, and released from a hub that is swapped out, so the notification-or-scene choice is right.

## 0.5.2 - 2026-10-03

### Documentation

- **Every screenshot and GIF redone for 0.5**: the README and the guide showed the deep of 0.1 and 0.2 (no search bar, no *+* button, no doors on the card). All of them are rendered again from the demo mesh: the deep, disconnected, relay down, exit node in a light theme, search, menus, networks, the card, the Control Center, the desktop fishbowl, and the five gesture GIFs.

### Fixed

- **Previews no longer catch two creatures crossing**: the demo traffic regroups the deep every second, and the preview script took its picture 1.6 s in, often in the middle of a swim, so a manta and a turtle could sit on top of each other with a hidden name. It now waits until nothing swims before taking the picture. The layout itself never overlaps resting creatures.
- **The top consumer's label no longer covers a cave's name**: its label is the tallest in the deep (*TOP CONSUMER*, the name, the rates), and when the deepest peer held the crown it could reach down onto the networks' row and hide a name. The layout now keeps that room above the caves for every peer, whoever is the top.

## 0.5.1 - 2026-10-02

### Security

- **The setup key no longer shows in `ps`**: joining used to run `netbird up --setup-key <key>`, and any program on the computer can read a command line while it runs. The key now goes through `netbird`'s environment (`NB_SETUP_KEY`), which only you can read, and is dropped once the command ends.
- **No command line in the log**: a failing callback used to write the whole command, a setup key included, to the shell's journal. Only the program name is written now.
- **`dms ipc call abyss join` takes a key file, not the key**: a key typed in a terminal stays in the shell history. `netbird` reads the file itself (`--setup-key-file`); a key passed directly is refused with a link to the guide.
- The setup key field of *Add a device* always shows dots, and is emptied when the sheet closes.
- **The copied setup key leaves the clipboard history** once the join has worked (pinned entries stay).
- **Self-hosted servers must use `https://`**, so the key never travels in clear.
- **Peer names stay plain text**: a name that looks like a web address is no longer turned into a link in a toast, and *Open page* only opens a plain host name or address, saying why otherwise.

### Fixed

- **Signing in or joining is no longer cut off after 15 s**: `netbird up` waits for you in the browser, so Abyss now gives it five minutes.
- **Nothing moves or reads NetBird while the screen is locked or off**: the desktop fishbowl kept reading the mesh every 2 s and animating behind the lock screen.

### Documentation

- The guide now covers the 0.5.0 features: connecting to a peer, search and commands, adding a device, joining a mesh, and letting peers SSH in. *Privacy* now lists exactly what the settings hold (peer names and identifiers, logins).

## 0.5.0 - 2026-10-02

### Added

- **Connect from Abyss, not only look**: a peer's card now opens **Files** (SFTP, in your file manager), **Screen** (VNC) and **RDP** next to SSH, with whichever viewer is installed (`gio`/`xdg-open`; `remmina`, `vncviewer`, `krdc`; `xfreerdp`, `remmina`, `krdc`). A missing viewer says what to install.
- **SSH as the right user, on the right port**: `dms ipc call abyss link <peer> <user|-> <port|->` remembers how to reach a peer (a phone running Termux: its own user, port 8022); SSH and SFTP use it. `ssh user@peer` logs in as that user once.
- **Join a mesh from Abyss**: `dms ipc call abyss join <setup key> [management url|-]` runs `netbird up --setup-key` (NetBird Cloud or self-hosted); `leave` signs this device out.
- **Let other peers in**: right-click the jellyfish, "Let peers SSH in here" (or `dms ipc call abyss share on|off`) turns NetBird's own SSH server on this device on or off, so your phone can open a session on your PC.
- IPC: `sftp`, `files`, `vnc`, `rdp`, `link`, `join`, `leave`, `share`.
- **A search bar**, always at the top (typing anywhere fills it): one-click shortcuts while empty, and a command palette (`add`, `share`, `disconnect`, `console`…; Enter runs the first).
- **Add a device**, step by step (the + at the top, the search, or the jellyfish's menu): this computer with a setup key, or your phone with QR codes for the NetBird app (click to enlarge), your server's address as a QR code when self-hosted, live detection of the new device with a burst of bubbles, and Termux steps to reach its terminal and files.
- **Device card**: four big doors (Terminal, Files, Screen, Desktop) with a plain line saying what each opens, and the login (user, port) shown and changed in place; a phone offers "Use 8022" in one click.
- **Errors that say how to fix them**: Abyss knocks on the device's port first; a device that does not answer, or a missing viewer, gets a toast with the reason and the command to copy (sshd, Termux, Remmina for your distribution).
- **Settings as tabs** (Connect, The deep, Effects & battery, Bar & alerts, Desktop, Source & lab, Help), each option with one short line; every effect shows its battery use. New switches: smooth motion (60/30 fps), creatures drift, celebrations, status dot, middle-click connects, search suggestions.
- **Bar**: a status dot, a tooltip summing everything up, middle click connects or disconnects.
- **Control Center**: starred devices along the bottom, one click from their terminal or files.
- **Desktop fishbowl**: a small Search / + pill under the surface while the pointer is over it.

### Changed

- **Tentacles grip what they reach**: each tentacle ends in a hook under the device's belly instead of stopping short of it.

### Fixed

- **Relay lanterns no longer sit on a tentacle**: a lantern is placed where no other device's tentacle passes through it, checked against the tentacles as they are drawn, and placed again once every lantern is known.
- **The bar's peer count follows a connect or disconnect** with every view closed: Abyss listens for NetBird's interface (`wt0`) coming or going, an event from the kernel, and reads once (and once more 5 s later). Peers joining a live mesh still show at the next opening.
- **Help links open the user guide** (`docs/GUIDE.md`) at the right section, not the README where those sections no longer are; "No exit node in a group" opens the group section.
- **Darwin's credits** now say where he comes from: Darwin Watterson, *The Amazing World of Gumball* (Ben Bocquelet, © Cartoon Network); his pictures are cut out of reference images, not drawn from scratch as the README said, and are not covered by the MIT license.
- The layout test now measures against the real body and lantern sizes; it used names that did not exist and could not fail.

Not done yet: managing access policies (who may talk to whom) needs a NetBird API token and is not part of this.

## 0.4.0 - 2026-10-01

### Added

- **Your real NetBird mesh**: peers, traffic, relays, networks, profiles and the Internet light come from the NetBird daemon through its `netbird` command: one read when the shell starts, then every 2 s only while a view is open. Connect, disconnect, sign in, start the service, switch profile, turn networks on or off and choose where Internet goes out all run the matching command; anything that fails says why.
- **Setting "Mesh source"**: automatic (NetBird when installed, else the test lab), NetBird, or test lab.
- **Test lab** in the settings, shown while it is the mesh source: a mesh of 1 to 120 made-up peers (or the home, work and crowd meshes), latency added to every peer, a trouble to try (a peer that stops answering, a peer that keeps dropping out, a relay or the management server down, signed out, service stopped) and calm, normal or rush-hour traffic. A one-line summary and *Reset* under its title. In memory only; NetBird is never touched. While the lab is the source, the profile chip wears a flask and the bowl's sand line starts with "test lab", so a made-up mesh is never taken for yours.
- **Tests**: QML integration tests through real processes against a fake `netbird`, `tests/run.sh` to run every test, and CI on every push. The tentacle layout check (P60) also runs on the test lab's meshes, from 1 to 120 peers.

- **Where Internet goes out, everywhere**: a small still sun in the bar pill while it goes out through a peer; the beam's traffic (↓ ↑) under the light's name; `dms ipc call abyss exit ""` says where it goes out, and `status` ends with it ("· Internet through studio"). After each change a short word under the light confirms it for two seconds ("Direct", "Through studio").
- **Rename a group from its title**: with a group of yours open, click its name at the top; a small ⚙ beside it opens the group's menu (Internet through it, rename, ungroup, or keep an automatic group).
- **Shoals**: in an open group, the awake members drift together around their places, one slow loop shared by the whole school, each a little behind the next (a few pixels, only while you watch; still with *Reduce motion*).
- **More search words**: the usual names of a kind find it (`iphone`, `proxmox`, `synology`, `hetzner`, `macbook`…), plus `exit` (can lend Internet) and `new` (online for under an hour), in English and French.
- **A compact list for big meshes**: from 12 peers on, a list icon in the top bar shows every peer as one line (name, kind, relay, traffic, latency), sorted like the deep, following the search and "Show offline peers"; a click opens the peer's card, Esc closes it.
- **Admin console and version**: right-click the jellyfish for "Open the admin console" (NetBird Cloud's dashboard, or your management server's host when self-hosted; opened on click only); pointing at it also says which NetBird version runs.
- **Ping a peer on demand**: a Ping button in the peer's card and `dms ipc call abyss ping <peer>` send three echoes and say the average (and how many came back) in a toast. Never on its own.
- **Setting "Bar pill"**: peers online (default), total traffic, or icon only.
- **Smart search from the launcher**: `abyss >100ms`, `abyss ssh nas`, `abyss copy phones`, `abyss ssh direct <5ms`: the deep's search words (speed, state, kind, relay) pick peers there too.
- **Darwin, the goldfish companion** (setting "Companion", on by default): the goldfish of the cartoon, drawn from pictures (cut out of reference images, in `components/assets/darwin/`) instead of shapes: his whole-body head with the face, and his two hands that move on their own, no legs. He eats the crumbs the traffic drops, scrubs the glass as it clouds over, sleeps on the bottom (lids drawn over his eyes) while the mesh is down, explores, and waves when clicked. Drawn behind every creature; he moves only while a view is open, on the clock the deep already runs.
- **Lazy connections**: when NetBird's lazy connections are on, idle peers doze in the water a little above the floor ("3 idle · wake on use"; the card says "Idle · lazy connection, wakes on first use") instead of lying asleep. NetBird does not say which idle peers are really off, so none is drawn as asleep then. The test lab can turn it on.
- **Exit routes named after no peer**: listed by their own name at the bottom of the light's menu (and `dms ipc call abyss exit <route>`). Once one is used, the peer carrying it is learned and kept in the settings, so it lends from then on.
- **Choosing and groups**: pointed at, the light says how it is used ("Drag onto a device · click for the list"); a closed group lending Internet wears a small sun beside its name; when a group of yours hands the Internet to another member, a note says who took over.
- **When Internet goes wrong**: "Switching…" under the light until NetBird confirms the new exit; disconnected, the light stays, dim, and a click says "Connect first"; when the peer lending Internet goes offline, a note says so and names the next best peer.

### Changed

- **The card first, then the creature**: opening a peer, the card leads and the creature flies into its medallion a beat later; both land together (480 ms), with a softer overshoot.
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
