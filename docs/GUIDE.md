# Abyss: user guide

Everything Abyss can do, in detail. To install it and add a widget, see the [README](../README.md#getting-started).

Every refusal in Abyss says why in a short note, with a GitHub mark that opens the matching section of the docs.

## Contents

- [Widgets](#widgets)
- [Connect and disconnect](#connect-and-disconnect)
- [Open a peer's card](#open-a-peers-card)
- [Open a group](#open-a-group)
- [Make your own groups](#make-your-own-groups)
- [Internet through a peer](#internet-through-a-peer)
- [Internet through a whole group](#internet-through-a-whole-group)
- [Turn a network on or off](#turn-a-network-on-or-off)
- [Find a peer](#find-a-peer)
- [Ping](#ping)
- [From the launcher](#from-the-launcher)
- [Settings](#settings)
- [Privacy](#privacy)
- [Performance](#performance)

## Widgets

- **Bar**: a small jellyfish with the number of peers online. Click opens the deep, right click connects or disconnects.
- **Control Center**: a NetBird tile (toggle) with the deep underneath.
- **Desktop**: a round fishbowl with a sandy bed, glass and a water line; the deep lives inside it. It stays still until the pointer is over it. Who is online and the live totals are written in a fine line of coloured sand. Choose its screens in the settings.

| Desktop fishbowl | Control Center |
| --- | --- |
| ![The fishbowl desktop widget](../screenshots/desk.png) | ![Control Center](../screenshots/connected-cc.png) |

## Connect and disconnect

Click **the jellyfish** (you) to connect or disconnect: it is the only switch, and the small ON / OFF under "you" says where you stand; if NetBird needs it, the same click signs you in or starts the service. Right-click it for more: connect or disconnect, switch to the next profile, show or hide offline peers. From the bar, a right click on the small jellyfish does the same, and so does `dms ipc call abyss toggle`.

## Open a peer's card

Click a creature. Its card rises from the bottom and the creature flies onto it: live rates and a 60-second curve, copy its IP or name, SSH, open in the browser, use it for Internet, favorite, mute, latency, connected since, last handshake, totals, networks it opens. Click outside it or press <kbd>Esc</kbd> to close.

![Opening a card](../screenshots/card-open.gif)

<kbd>←</kbd> <kbd>→</kbd> (or the ‹ › arrows) step to the previous or next device without leaving the card.

![Stepping between cards](../screenshots/card-step.gif)

## Open a group

Peers that look alike swim together as a shoal ("3 busy", "2 quiet"). Rest the pointer on one, or click it: the camera glides in and the group opens in the middle. Move the pointer away to come back. The **Open groups** setting chooses how: on hover and click (default), hover only, or click only.

![Opening a group](../screenshots/group-open.gif)

## Make your own groups

Right-click a creature or a group: add it to one of your groups, start a new one, rename it, ungroup it, or keep an automatic group as yours. Your groups come first and never reshuffle. With a group open, click its name at the top to rename it; the small ⚙ beside the name opens the same menu as a right click.

![The right-click menu](../screenshots/groups-menu.png)

## Internet through a peer

The light at the surface is your Internet. **Drag it onto a peer** and all your Internet traffic goes out through that peer; a soft beam falls from the light onto it. Drag the light back to the surface, or drop it in open water, to go out directly again. <kbd>Esc</kbd> while carrying puts it back. Resting it on a group opens the group, so you can leave it on a member.

![Carrying the light onto a peer](../screenshots/internet.gif)

**Only a peer that offers an exit node can lend Internet** (NetBird's rule). NetBird does not say which peer serves an exit route until it is in use, so **name the route after its peer** (`exit-atlas` for *atlas*); a route named after no peer is listed by its own name at the bottom of the light's menu: choose it once and Abyss remembers, in your settings, which peer carries it. While you carry the light, the others step back and, over one of them, the light says so; drop it there anyway and it bounces home with a note. To let a device lend Internet, turn it into an exit node in NetBird's dashboard: *Network Routes* › *Add route* › *Exit node*, see [NetBird's guide](https://docs.netbird.io/how-to/configuring-default-routes-for-internet-traffic).

![Dropping the light on a peer that cannot lend Internet](../screenshots/cant-lend.gif)

**Click the light** instead of dragging it for the same choice as a list: your groups as folders (click a name for the whole group, its arrow to pick one member), then the other peers that can lend, quickest first, and "Stop". A small turning sun marks the one in use. Right-clicking a peer offers "Use for Internet" too.

![The light's menu](../screenshots/internet-menu.png)

## Internet through a whole group

Carry the light into one of your groups and let it go in the middle. It stays there, tied by a tentacle to the member lending the Internet (NetBird uses one exit node at a time) and by dashed lines to the ones ready to take over: if that member goes offline, the next best one (direct first, then the lowest latency) takes over by itself. Take the light from the middle and drop it on one member to use only that one; drag it out of the group to stop.

![The light in the middle of a group](../screenshots/internet-group.png)

## Turn a network on or off

The caves on the floor are your networks and routes. Click one to turn it on or off, or open the list from the network button at the top.

![Networks](../screenshots/networks.png)

## Find a peer

Just type a name: the deep keeps the matches (favorites first) and dims the rest. <kbd>Enter</kbd> opens the first one's card, <kbd>Esc</kbd> clears.

![Finding a peer](../screenshots/find.png)

## Ping

A peer's card has a **Ping** button: three echoes to its address, and a toast with the average, the best and worst time and how many answered. It runs only when you ask (also `dms ipc call abyss ping <peer>`); Abyss never pings by itself. In the test lab it says what the made-up mesh claims.

## From the launcher

Press Super+Space and type `abyss`: "Open Abyss" opens the deep from the bar; below it, connect, choose where Internet goes out (a sun marks the one in use), and, as you type a name (`abyss vega`), copy its address or SSH to it. The same words as the search in the deep pick peers by what they are: a speed (`abyss >100ms`, `abyss <20ms`), a state (`direct`, `relay`, `slow`, `busy`), a kind (`nas`, `phones`, `vps`) or a relay (`eu`); start with `ssh` or `copy` to keep one action (`abyss ssh nas`, `abyss copy >100ms`).

## Settings

| Section | Setting | Default | Description |
| --- | --- | --- | --- |
| Desktop | Screens | All | Which screens show the fishbowl |
| | Keep the desktop alive | Off | The bowl keeps moving when the pointer is away (off costs nothing) |
| The deep | Things on screen | 5 | How many creatures and groups show before the rest gather into shoals (3 to 10) |
| | Open groups | Hover and click | Hover and click, hover only, or click only. Carrying the light always opens them |
| | Show offline peers | On | Asleep on the floor, or hidden. With NetBird's lazy connections on, idle peers doze a little above the floor instead ("idle · wake on use"): NetBird does not say which of them are really off |
| | Light pulses | On | Pulses of traffic along the tentacles |
| | Companion | On | Darwin, a goldfish with a life of his own: he eats the crumbs the traffic drops, scrubs the glass as it clouds over, sleeps on the bottom while the mesh is down and waves when clicked. He only moves while a view is open, and stays still with *Reduce motion* |
| Peers | Bar pill | Peers online | What the small jellyfish in the bar says beside it: how many peers are online, the total traffic, or nothing |
| | Notifications | Off | When a peer comes or goes; muted peers stay quiet |
| | Terminal for SSH | Automatic | The terminal used for SSH |
| Source | Mesh source | Automatic | Your NetBird daemon, or the test lab's made-up mesh. Automatic reads NetBird when the `netbird` command is installed |
| Test lab | Mesh | Home | Home (10 peers), work (5), crowd (30), or a custom size from 1 to 120 peers, to see how groups form |
| | Added latency | 0 ms | Added to every peer: they sink deeper and may switch places |
| | Trouble | None | A peer stops answering (raised as silent after a few minutes without a handshake), a peer keeps dropping out (every 6 s, for notifications), a relay goes down, the management server is unreachable, signed out, service stopped. Applied when chosen; the jellyfish still connects and disconnects |
| | Traffic | Normal | Calm, normal, or rush hour (pulses and totals) |
| | Lazy connections | Off | As if NetBird's lazy connections were on: idle peers doze in the water instead of sleeping on the floor |

The test lab only shows while it is the mesh source. It never touches NetBird: the mesh is made up and lives in memory. Its title sums up what is set ("48 peers · +80 ms · a peer stops answering") and *Reset* brings back the quiet home mesh.

DMS's *Reduce motion* is respected: every movement stops.

## Privacy

- **No network access by the plugin itself, no telemetry.** NetBird is read through its local `netbird` command, never through a shell: no peer name or address can run anything.
- **Nothing written to disk except your settings** (favorites, muted peers, your groups, the group carrying the Internet, and which peer carries each exit route once seen). Peers, addresses and traffic stay in memory for the session.
- **Local tools only**: copy uses DMS's clipboard, SSH opens your own terminal, Ping runs your own `ping` to one peer of your mesh, only when you click it. The GitHub mark in help notes opens the docs in your browser, on click only.

## Performance

- Nothing runs while no view is open: no timer, no reads (one read of NetBird when the shell starts, so the bar shows the real state).
- While a view is open, NetBird is read every 2 s, one command at a time, never piled up.
- While a view is open, one 30 Hz timer moves the pulses and the marine snow; only this window redraws, never the whole shell.
- *Reduce motion* turns every movement off.

Measured numbers will be added before the first stable release.
