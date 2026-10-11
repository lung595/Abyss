# Roadmap

No promises, no dates. Everything here was asked for and is not in a release yet.

## Next

- Measured CPU cost while a view is open, from a repeatable bench (the shell is too busy on a desktop in use for honest numbers).

## Later

- **Tags**: your own words on a peer, searched like a kind.
- Bar count kept fresh as peers come and go, without polling (needs NetBird's event stream, a gRPC call the CLI does not offer).
- Maybe: a debug bundle and client settings.

## Known limits

- About 24 caves or more in a 480 px wide deep: the names on one height touch (the name width stops at 48 px, below that it is not readable).
- Waking a device (not wired yet) identifies a network by its IPv4 subnet only: on a foreign network with the same numbers the magic packet would go out there. The wiring will add a discriminator such as the gateway MAC.
- A file send shows no percentage: `scp` prints no count without a terminal, so progress is a moving mark.
- Naming a group needs keyboard focus, which the desktop widget may not get: rename it from the bar popout.
- An exit route named after no peer shows by its name, not on its peer, until it has been used once.
- While no view is open, the bar count follows connecting and disconnecting, not peers joining or leaving a live mesh.
- When `netbird up` cannot open a browser, the sign-in address is not shown.
- Starting the NetBird service needs a polkit agent.
