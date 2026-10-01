# Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

## Next

- **Exit routes named after no peer**: list them in the light's menu by name, or tie one to a peer once (saved in the settings).
- **Peers kept idle by NetBird's lazy connections**: drawn as reachable rather than asleep.
- **Tentacles that hold their device**: the tip wraps around the creature.
- **The card first, then the creature**: both finish landing at the same moment.
- **Rename a group**: click its name at the top of the group view; a small ⚙ opens its settings.
- **The jellyfish as the only on/off switch**, with a small ON/OFF word beside it.
- **A cleaner layout**: one sector per relay, so no tentacle or lantern ever hides a device or a label.
- **Shoals**: the creatures of a group swim together like a real school of fish (only while you watch).
- **A goldfish companion** in every view: it waves when clicked, eats, sleeps and cleans the bowl. Still while nobody looks.
- Measured CPU cost while a view is open, and fresh screenshots.

## Internet, the whole journey

Sending your Internet through a peer should explain itself at every step. Already done in 0.3.0: the light and its label, the beam, dimming the peers that cannot lend, the light's menu, "Use for Internet" in cards and menus, gliding, <kbd>Esc</kbd> to put it back, whole groups with a preview ring, and the `exit` command. Still to come:

- **Where you stand**: a small sun in the bar pill while Internet goes out through a peer; the beam shows its traffic (↓ ↑); the lending peer's card says "Lends you Internet".
- **Choosing**: hovering the light says "Drag onto a device to go out through it"; members waiting on dotted lines say "ready to take over".
- **Groups**: a closed group lending Internet wears a small sun, its beam labelled "Internet via Homelab · studio"; a short note when the group switches member.
- **Confirming**: a word under the light for a moment ("Direct", "Through studio") after each change.
- **When something goes wrong**: "Switching…" while NetBird switches, and why if it fails; a warning and the next best peer when the lending peer goes offline; a dim light that cannot be carried while disconnected ("Connect first").
- **Everywhere**: `exit` with no argument says where Internet goes out now; with *Reduce motion*, only the end states.

## Later

- **Smart search**: understands words and synonyms, not only names.
- **Smart tags**: added automatically (from the name, services, machine type) or by hand.
- **Search the launcher by speed or tags**: `abyss >100ms`, `abyss proxmox`.
- Bar count kept fresh without polling while nothing is open.
- Bar pill options: icon only, with peers online, or with the total rate.
- Show online peers only, or all of them.
- Ping a peer from its card, on demand only.
- Open the admin console, a reconnect shortcut, the daemon version.
- A compact list for very large meshes (30+ peers).
- Maybe, if asked: a one-click debug bundle, and client settings (SSH server, Rosenpass, connect at startup).

## Known limits

- Naming a group needs keyboard focus, which the desktop widget may not get: the name stays "Group n" there; rename it from the bar popout.
- NetBird's CLI does not say which peer serves an exit route that is not in use: an exit route is matched to its peer by name until it has been used once.
- The bar count is read once when the shell starts and while a view is open; it goes stale in between.
- When `netbird up` cannot open a browser for the sign-in, the sign-in address is not shown in Abyss.
- Starting the NetBird service goes through `pkexec`, so it needs a polkit agent.
