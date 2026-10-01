# Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

## Next

- **The card first, then the creature**: both finish landing together.
- Measured CPU cost while a view is open, and fresh screenshots.

## Later

- **Smart search**: synonyms, tags, `abyss >100ms`.
- Bar count kept fresh without polling.
- Ping a peer on demand.
- A compact list for large meshes (30+ peers).
- Bar pill options, admin console link, daemon version.
- Maybe: a debug bundle and client settings.

## Known limits

- Naming a group needs keyboard focus, which the desktop widget may not get: rename it from the bar popout.
- An exit route named after no peer shows by its name, not on its peer, until it has been used once.
- The bar count goes stale while no view is open.
- When `netbird up` cannot open a browser, the sign-in address is not shown.
- Starting the NetBird service needs a polkit agent.
