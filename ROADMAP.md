# Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

## Next

- Measured CPU cost while a view is open, and fresh screenshots.

## Later

- **Tags**: your own words on a peer, searched like a kind.
- Bar count kept fresh as peers come and go, without polling (needs NetBird's event stream, a gRPC call the CLI does not offer).
- Maybe: a debug bundle and client settings.

## Known limits

- Naming a group needs keyboard focus, which the desktop widget may not get: rename it from the bar popout.
- An exit route named after no peer shows by its name, not on its peer, until it has been used once.
- While no view is open, the bar count follows connecting and disconnecting, not peers joining or leaving a live mesh.
- When `netbird up` cannot open a browser, the sign-in address is not shown.
- Starting the NetBird service needs a polkit agent.
