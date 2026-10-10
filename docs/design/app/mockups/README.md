# Abyss app — pixel mockups (NAK-286)

Direction chosen by the owner (NAK-283): **C "Water column" — depth is the
navigation**, pushed much further into the deep-sea universe. Fictional data
only. Everything below uses the palette and rules of the knowledge base
`design.md` §2 (D393) and the Theme API of DMS; no other colour exists.

## 1. The one idea: the window is a dive

Three stations, one per view. Moving between views **is** descending or
ascending; the water around the content changes with the depth.

| Depth | View | Water (dark "abyss") | Water (light "lagoon") | Life |
|---|---|---|---|---|
| 0 m · Surface | Settings | `surfaceContainerHighest` | `surfaceContainerLowest` | sun ripples (static), bubbles rise on arrival |
| 200 m · Twilight | Send | `surfaceContainer` | `surfaceContainerLow` | marine snow falls on arrival, capsules |
| 4 000 m · Abyss | Map | `surfaceContainerLowest` (the sea) | `surfaceContainerHigh` | creatures, lanterns, bioluminescent halos |

The water is **stratified, not a gradient** (D393: no decorative gradient):
each view sits in one flat stratum; a 1 px `outline` line marks the
thermocline between two strata and is what the eye follows during a dive.
Every text sits on an opaque container (`surfaceContainer` panels) or on a
stratum whose contrast is measured (§5), never on a mixed background.

Why it is not generic: no sidebar, no tabs, no pages. The gauge on the left
is a real diving instrument; Darwin swims next to the current station; a file
being sent is a capsule going down the water column.

## 2. Anatomy (window 1280×800, minimum 900×600)

```
┌──72──┬──────────────────────── content ────────────────────────┐
│gauge │ 32 px padding · title row 44 · body · 32 px padding       │
│      │                                                           │
└──────┴───────────────────────────────────────────────────────────┘
```

- **Depth gauge** (left, 72 px wide, full height): a vertical scale with a
  tick every 4 px (minor) and a label every 100 m in mono 11; three station
  targets of 44×44 px (`Settings 0 m`, `Send 200 m`, `Map 4 000 m`), the
  current one filled `primary` with a 2 px ring, the others `outline`.
  Under the scale, the **instrument readouts** in mono 11, tabular: depth
  `m`, pressure `bar` (= depth / 10 + 1), temperature `°C` (18 → 6 → 2),
  and signal `●` (NetBird state: `success` connected, `warning` degraded,
  `error` stopped; the glyph changes too, never colour alone). Darwin
  (`components/assets/darwin`, 24 px) hangs beside the current target.
- **Content column**: `width − 72`, padding 32, title 22 DemiBold on a 44 px
  row with its depth in mono 13 `onSurfaceVariant` (`Send · 200 m`).
- 900×600: gauge 56 px, padding 24, title row 40; nothing else reflows.

## 3. Screens of v1 (AC1)

1. **Map · 4 000 m** — the sea fills the content area; filters row (chips
   32 px: All, #tags, groups) at the top-left, zoom gauge (3 × 44) at the
   top-right, **never overlapping** the peer card (card is clamped inside
   the sea minus 56 px on the right). Peer card 300×240, radius 16,
   anchored to the creature: name 15 DemiBold, address · latency · uptime
   in mono 13, traffic sparkline 240×24 `primary`, short diagnosis verdict
   (`● Direct · 12 ms · healthy`), chips: **Send a file** (primary), Browse
   files, SSH, ★. Footer: `8/10 online · ↓ 21 Mb/s · ↑ 4.3 Mb/s`.
2. **Send · 200 m** — drop zone 120 px high (1 px `primary` border, inner
   dashed line, `Drop files here, or press Ctrl+O`); `To` chips, multi
   select; **queue of capsules**: each row = capsule glyph 16, name (middle
   ellipsis, extension kept), device, track 120×8 with the capsule knob
   sliding along it (`transform` only), `42 %` mono tabular, speed, action
   (Cancel / Retry / Dismiss, 44 px targets). rsync: percentage; scp
   fallback: `Sending…` with an indeterminate 120×8 bar driven by a Timer
   (stops when hidden) and the words `no progress with scp`. Failure row:
   `error` α 0.13 band, cause + action, GitHub mark → GUIDE anchor (value
   10). History: two lines per file (name → device · when · size).
3. **Settings · 0 m** — search field 44 px (`/`), categories 40 px on the
   left (one visible at a time, D241), rows: label 15 / help 12 / control
   right (switch 48×28, stepper, folder chip). Search filters rows across
   all categories and highlights the category chips that still match.
4. **Peer card** — see 1; `Browse files` opens `sftp://` in the file
   manager; the verdict is one line, full report in the diagnosis view.
5. **Add-device wizard** (over the Map, panel 560 px, radius 20): step 1
   name + species (kind), step 2 setup key **hidden** (`••••••••`, reveal
   44 px, copy), step 3 QR code (fictional payload) + `Scan it from the
   phone`. On finish, a capsule descends into the sea and the new creature
   appears asleep until NetBird sees it.
6. **Diagnosis** (panel over the Map): report lines (daemon, management,
   signal, relay/direct, latency, MTU, last handshake) each with a glyph +
   word, and **Measure throughput (10 s)** button, result in mono
   (`↓ 94 Mb/s · ↑ 41 Mb/s`) with a 240×24 sparkline.
7. **Tag/group editor** (panel over the Map): tags as chips with counts,
   `New tag` input, groups = named sets of tags, members listed as small
   creature glyphs; remove = ✕ inside the chip (44 px hit).

## 4. Edge states (AC2)

empty network (sea, the jellyfish `you`, `No creature yet` + one line of
help) · NetBird missing or stopped (first run at 0 m: Darwin explains,
`Install NetBird` · `I have a key`; stopped: `warning` band on every view
with `Start NetBird`) · send refused (`error` band + GitHub mark to the
GUIDE section, never a silent failure) · 30 peers (map clusters per group
into caves, compact list under the sea) · very long names (middle ellipsis,
extension kept, chips ≤ 28 chars + …) · light and dark for all of them.

## 5. Tokens and sizes (AC3)

| Token | Value | Where |
|---|---|---|
| Window | 1280×800 (min 900×600) | all |
| Gauge width | 72 (56 at 900×600) | gauge |
| Content padding | 32 (24) | content |
| Title row | 44 (40), title 22 DemiBold | all views |
| Type scale | 11 / 13 / 15 / 22, mono tabular for numbers | all |
| Radii | 12 control · 16 card · 20 panel | all |
| Border | 1 px `outlineStrong` on containers and controls (dark `#8592b8`, light `#5a6a82`: ≥ 3.57:1 on every stratum, measured) · `outline` for dividers only | all |
| States | hover `onSurface` α 0.08 · pressed α 0.12 · focus-visible 2 px `primary` ring, 2 px offset · selected `primary`/`onPrimary` (row: `surfaceContainerHigh`) · disabled 38 % content, no pointer (`08-states`) | all controls |
| Creatures | 24 grid scaled by r/12, 2 px stroke, at most 2 details (eye, one fin) | map, tags |
| GitHub mark | 24 px, `onSurface` disc, cat silhouette in `surface` → GUIDE anchor, click only | bands |
| Station target | 44×44, ring 2 px `primary` when current | gauge |
| Chip | 32 high, 44 hit, 12 padding, fill `surfaceContainerHigh` + 1 px `outlineStrong`; active `primary`, 13 DemiBold | all |
| Switch | 48×28 | settings |
| Drop zone | content width × 120 | send |
| Capsule track | 120×8, knob 12 | send |
| Peer card | 300×240 | map |
| Panel | 560 wide (width − 64 at 900), radius 20 | wizard, diagnosis, tags |
| Halo | `primary` α 0.13, 32 px blur budget | map |
| Dive transition | descend 200 ms, ascend 150 ms (kit scale), OutCubic, `transform` only | views |
| Chips / card / panel | 100 / 150 / 200 ms enter, exit 150 ms | all |
| Reduced motion | final state, no travel; snow and bubbles off | all |
| Contrast (measured) | text ≥ 4.5:1, borders ≥ 3:1 on every stratum (table printed by `render.py`); `primary` as text ≤ 15 px only on strata ≥ 4.5:1 (light: never on `surfaceContainerHigh`/`Highest`) | all |

Every surface a control can sit on and its measured pairs are printed by
`render.py`; a stratum that fails AA gets its text on a panel.

## 6. Files

- `option-a.html` — direction C pushed: strata + instrument gauge (above).
- Option B (continuous light falloff) was dropped after the Design Director's
  review: its captures carried no proof of the idea and it costs ~1.5× for
  the same information. Option A is the only candidate.
- `render.py` — real-size PNG renderer sharing the same token values
  (`option-a/<dark|light>/<screen>.png`); no browser exists on the machine,
  so the screenshots the owner sees are rendered by this script, not from
  the HTML (assumption recorded in the knowledge base `questions.md`).

## 7. Self-critique before review

- Glyphs (`●★✕⚠`) are drawn with the Noto Symbols faces: Noto Sans has none
  of them and printed boxes in the first render.
- The peer card stops 76 px from the right edge so it never sits under the
  zoom gauge (44 px + 16 px margin + 16 px gap).
- Send queue columns: name · track 120 · percentage 72 · speed 160 · action
  100, 16 px gaps; `scp · no progress` no longer touches the Cancel button.
- Depth labels on the gauge: `0 · 1k · 2k · 3k · 4k`, mono 11.

## 8. Fixes after the Design Director's review (73 → target 90+)

1. Search field, zoom buttons, cards, panels, switches: 1 px `outlineStrong`
   (≥ 3.57:1 on every stratum, printed by `render.py`); `outline` kept for
   dividers only.
2. Station 0 m: gauge scale starts at y 64, so the ring top sits at y 42 and
   the readouts end at y 758: same margin at both ends.
3. Zoom column: exactly 3 buttons (`+`, `−`, `⌖`), every one with a glyph
   (the old code iterated a string and drew its spaces).
4. GitHub mark drawn (disc + cat silhouette, 24 px); creatures share one
   stroke on the 24 grid (2 px, eye + one fin at most).
5. `08-states.png`: chip, primary and secondary button, zoom control,
   switch, queue row and station in default / hover / focus-visible /
   pressed / selected / disabled.
6. Durations on the kit scale: descend 200 ms, ascend 150 ms.
7. Inactive chips have a visible container (fill + border); the kerning
   gap (`#hom e`) came from the raqm engine on variable-font instances, the
   renderer now uses the basic layout.
8. Copy: `Sending · scp, no progress`.
9. `primary` text ≤ 15 px never sits on light `surfaceContainerHigh`
   (4.1:1): secondary buttons only appear on panels and the 0 m / 200 m
   strata (≥ 4.6:1).
