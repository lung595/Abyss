# Abyss app — visual directions (reference wireframes)

> **Superseded.** These wireframes (A, B, C) were the input of the direction
> choice (D393). The approved pixel mockups are in `mockups/option-a/`
> (option A, D396, 2026-10-10); build from `mockups/README.md` and the knowledge
> base spec, not from these folders. Kept for the record of the reasoning.

Three candidate directions for the standalone Abyss app, drawn as schematic
wireframes from fictional data. They are not mockups: they fix layout, tokens
and states so that pixel mockups can follow. Regenerate with
`python3 docs/design/app/render.py`; `--table` prints the measured WCAG
contrast of the app palette.

| Dir | One strong idea | Send / settings live… |
|---|---|---|
| A · Porthole (recommended) | the window *is* the aquarium | on a diver's slate sliding over the dimmed sea |
| B · Deck | a research vessel: lit deck left, sea right | on plain pages next to the sea |
| C · Water column | depth is navigation (0 m settings, 200 m send, 4 000 m map) | at their own depth, light follows |

Shared rules: colours come from the DMS `Theme` when DMS runs, otherwise the
Abyss palette (dark "abyss", light "lagoon") exposed through the same API;
the sea only exists in the map and the first run; 4 px grid, 44 px targets;
recurring motion through a 30–60 Hz `Timer` that stops when the window is
hidden or covered, Reduce motion honoured. States per direction and theme:
`window-1280x800`, `window-900x600`, `map`, `send`, `settings`, `first-run`,
`empty`, `error`, `long-names`.
