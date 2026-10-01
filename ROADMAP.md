# Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

## Next

- **Exit routes named after no peer**: listed by name in the light's menu, or tied to a peer once.
- **Lazy connections**: peers NetBird keeps idle are drawn as reachable, not asleep.
- **Rename a group**: click its title in the group view; a small ⚙ opens its settings.
- **Shoals**: the members of a group swim together (only while you watch).
- **A goldfish companion**: purely decorative, with a life of its own: it sleeps, cleans the bowl, eats, explores, waves when clicked. Still while nobody looks.
- **The card first, then the creature**: both finish landing together.
- Measured CPU cost while a view is open, and fresh screenshots.

## Internet, the whole journey

Already done: the light, the beam and its traffic, dimming, the menu, gliding, Esc, whole groups, the `exit` command (alone, it says where Internet goes out), a sun in the bar pill, a short word under the light after each change, and what goes wrong ("Switching…", "Connect first", the next best peer when one drops). Still to come:

- **Choosing**: hints while hovering and carrying the light.
- **Groups**: a sun on a group lending Internet, a note when it switches member.

## Later

- **Smart search**: synonyms, tags, `abyss >100ms`.
- Bar count kept fresh without polling.
- Ping a peer on demand.
- A compact list for large meshes (30+ peers).
- Bar pill options, admin console link, daemon version.
- Maybe: a debug bundle and client settings.

## Known limits

- Naming a group needs keyboard focus, which the desktop widget may not get: rename it from the bar popout.
- An exit route is matched to its peer by name until it has been used once.
- The bar count goes stale while no view is open.
- When `netbird up` cannot open a browser, the sign-in address is not shown.
- Starting the NetBird service needs a polkit agent.
