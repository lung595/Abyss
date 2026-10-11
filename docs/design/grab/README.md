# Jellyfish grab: before / A / B (NAK-335, D407)

Design prototypes only. Nothing here is shipped or imported by the plugin.

- Board for the owner: `index.html` (one self-contained page, renders embedded, no network; theme switch, side by side / real size / narrow).
- Renders: `before-{dark,light}.gif`, `a-{dark,light}.gif`, `b-{dark,light}.gif` (65 frames, 3.9 s, under 0.6 MB each), `a-reduce-motion.png`, `b-reduce-motion.png`. Eight in all.
- Re-render everything and re-embed the page: `scripts/preview/grab.sh` (scene: `scripts/preview/grab.qml`, values in its `specs` map).

Demo creatures: lantern whale `harbor-vps`, manta `atlas-server`, shoal `4 phones`. Colours come from `Theme` only (`primary` for the tentacle, `tertiary` for the bodies, `surface`, `surfaceText`, `surfaceVariantText`).

## What the engineer builds

The embrace is a helix around the body's long axis, seen from the side. For each point, `u` runs 0 to 1 along the coil:

- `x` runs from one side of the body centre to the other (`span` x half-width, entering on the bell's side);
- `theta = -90 deg + 360 deg x turns x u`, `z = cos(theta)`;
- ring radius = local half-height of the real outline at that `x` (`Shapes.hull`, a 25 px circle for a shoal) + 4 px, times `slack`;
- the ring is tilted: `x += tilt x radius x z`, which is what makes each turn read as a loop and not a bar.

**Front / behind split.** `z > 0` is in front. Half of every turn is drawn after the body at level 0.8, the other half before the body at level 0.1 (depth by light, D232 ribbon unchanged). Stretches are cut where `z` changes sign, with one point of overlap to hide the seam.

| | A: tight coil | B: long embrace |
|---|---|---|
| Turns | 3 | 2.25 (ends in front, at mid height) |
| Span (share of the body length, centred) | 44 % | 62 % |
| Tilt | 0.42 | 0.30 |
| Tip | none | curl, radius 5.5 px, 0.75 turn, rolled back over the flank, always in front |
| Points per held device | 121 | 91 + 14 |
| Tighten: `slack = 1 + amp x e^(-decay x t) x cos(freq x t)` | amp 0.55, decay 7, freq 13 rad/s | amp 0.40, decay 5, freq 9 rad/s |
| Tighten settles (below 1 %) | 0.57 s | 0.74 s |
| Drag lag spring (coil trails the device) | k 90, zeta 0.40 | k 60, zeta 0.35 |
| Lag settles after release (about 4 / (zeta x sqrt(k))) | 1.05 s | 1.47 s |

Shared by A and B:

| State | Trigger | Motion | Duration |
|---|---|---|---|
| Takes hold | device comes online, or the view opens | the coil grows from the bell's side (ease-out cubic), loose (`slack = 1 + amp`), then tightens from 0.55 s with the damped oscillation above | reach 0.75 s, then the settle time |
| Held, at rest | settle finished | none, a still frame | 0 |
| Dragged | the user's drag (unchanged, out of scope) | each coil point follows the device with the lag spring, weighted `0.3 + 0.7 x u` so the tip trails most; the free ribbon's belly takes 0.8 of the lag | while the pointer moves |
| Released | pointer up | the lag spring returns to 0 | settle time above |
| Asleep or offline | D232, kept | `slack` x 1.5, the tip sags 16 px, the coil unwinds to 30 % of its length (smoothstep), the body dims | 0.9 s |
| Reduce motion | DMS setting | final pose painted once, every transition skipped | 0 |

The free ribbon from the bell to the coil is a cubic curve: it drops from the bell (first handle 30 px back, 58 px down), then sweeps in over the back (second handle 44 px to the bell's side of the coil entry). Never a straight segment.

## How movement stops (nothing runs at rest)

- Every movement starts on an event (online, view opened, drag, release, asleep) and has a finite length: at most reach 0.75 s + settle, about 1.3 s for A and 1.5 s for B.
- It is computed on the view's existing 30 to 60 Hz `Timer`, never by a QML `Animation` (a running animation redraws the whole shell).
- The step stops as soon as `|slack - 1| < 0.01` and the lag is under 0.5 px: the coil is then snapped to its final pose and painted once. No idle sway, no breathing.
- View closed, covered, locked or screens off: nothing is computed; on reopening the final pose is painted directly.

## Recommendation: A

A is the owner's red trace (several turns crossing in front of the body). It reads on the three silhouettes, including the shoal where room is short, settles faster (0.57 s against 0.74 s) and has no extra part. B is more generous on long bodies but its tip curl is one more detail to read at small size and one more piece to build.

## Not verified

- The board was not scored /100 here: the Design Director scores it.
- Measured cost of the helix in the real view: the code story measures it.
