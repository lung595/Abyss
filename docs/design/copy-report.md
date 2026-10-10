# Abyss - "Copy report" row in settings Help (NAK-521, D371, D453)

Mockup: `docs/design/copy-report/index.html` (one page, opens from a local file; switches for theme, light / dark, width, reduce motion, clipboard tool and state; every state also drawn side by side).
Check: `gjs docs/design/copy-report/tools/check.js "$PWD/docs/design/copy-report/index.html"` (240 cases: 3 themes x 2 modes x 4 widths x 10 states; overlap, overflow, clipped text, target sizes, contrast, dash and network checks; 0 failure at the time of writing).

Model (D453): the row approved on Sands (Sands commit `5ce1046`, `docs/design/copy-report.md`, section "GitHub mark beside the button"). Same layout and behaviour; only the colours and the "Copied" picture (water and bubbles instead of the sand heap) are Abyss' own. Kept from Abyss, admitted at review: button hover fill `surfaceContainerHighest`, DemiBold title, a pressed state drawn on the mark.

Built by the engineer in NAK-473. Nothing here is production code.

## Idea

In Abyss what is done comes up from the deep. "Copied" is not a toast nor a green tick: water rises in the button and three bubbles climb its right edge, then it leaves by itself.

## Where

Help section ("Quick guide") of `AbyssSettings.qml`, last child of the Help column: six guide cards, "Full user guide" button, then this row. Spacing above the row: `Theme.spacingL` (16 px; the column spacing 8 plus 8 of top padding).

## Anatomy and sizes (4 px grid)

| Part | Size | Tokens |
|---|---|---|
| Row | wrapping row of NAK-423; column gap 16, row gap 8 | none |
| Text block | grows, minimum 160 px before the controls drop under it | |
| Title | `Theme.fontSizeMedium` (14), DemiBold, line 20, wraps | `Theme.surfaceText` |
| Help line | `Theme.fontSizeSmall` (12), line 16, wraps | `Theme.surfaceVariantText` |
| Controls | button, 8 px, GitHub mark; they wrap too: the mark drops under the button, left aligned, 8 px below | |
| Button "Copy report" | 44 high, fixed 112 wide, label centred, radius `Theme.cornerRadius` (12, as the guide cards), 1 px border | border `Theme.outline` (full, not 35 %: a UI part needs 3:1), fill transparent, label `Theme.surfaceText` DemiBold 14 |
| Button hover fill | whole button | `Theme.surfaceContainerHighest` |
| Copied water | whole button | `Theme.primary` at 14 % (`Theme.withAlpha`) |
| Copied bubbles | 8 x 28 px at 8 px from the right and top edges; circles r 3, 2, 1.25, stroke 1.5 | `Theme.primary` |
| Copied check | 16 px, stroke 1.5, 8 px before the label | `Theme.primary` |
| GitHub mark button | 44 x 44 target, 8 px to the right of the button, always visible, existing `GitHubMark` at size 18 | glyph `Theme.surfaceVariantText`; hover, pressed, focus and after copy `Theme.primary`; no hover fill |
| Mark label (tooltip) | 12 / 16 px text, padding 4 / 8, radius `Theme.cornerRadius` (12), 4 px under the controls, wraps and never leaves the column | fill `Theme.surfaceContainerHigh`, 1 px edge `Theme.withAlpha(Theme.outline, 0.24)`, text `Theme.surfaceText` |
| Guided message | full row width under the controls, radius 12, padding 8 top and bottom, 16 left, 4 right; reason DemiBold 14, hint 12; its own `GitHubMark` 18 in a 44 x 44 target | fill `Theme.surfaceContainerHigh` (same as the guide cards), reason `Theme.surfaceText`, hint `Theme.surfaceVariantText`, mark `Theme.surfaceVariantText`, hover `Theme.primary` |
| Focus ring | 2 px, 2 px outside the control | `Theme.primary` |

The button width is fixed (112 px, the model of D453) so it never changes between "Copy report", "Collecting…" and "Copied".

## Widths

| Settings width (mockup) | Column | Layout |
|---|---|---|
| 680 | 448 | text and controls on one line, controls on the right |
| 518 | 286 | controls drop under the text, left aligned |
| 436 (narrow, with the rail) | 204 | same, title and help wrap more |
| 360 (stress) | 128 | the mark drops under the button |

Nothing overlaps or is clipped at any of them (checked).

## States

| State | Button | Mark | Help line |
|---|---|---|---|
| Rest | outline, "Copy report" | variant colour | help |
| Hover | highest fill | (its own hover: primary glyph alone, no fill, label shown) | |
| Pressed | highest fill, scale 0.97 | (its own: scale 0.97, primary glyph) | |
| Focus-visible | 2 px primary ring | 2 px primary ring, 2 px offset, primary glyph, label shown | |
| Collecting (2 s at most) | "Collecting…" in variant colour, no hover, press ignored (`aria-disabled`, keeps focus) | unchanged | |
| Copied (4 s, then back to rest alone) | primary border, 14 % primary water, check + "Copied", bubbles | primary glyph: the next step | "Report copied. Read it, then paste it in a GitHub issue." |
| No clipboard tool | back to rest | unchanged | guided message under the row; it stays until the next press or until the section is left |
| Disabled, empty, error, loading | no disabled state (the row always works); loading is "Collecting"; error is the guided message | | |

Long text: title and help wrap (`wrapMode: Text.WordWrap`), never elide.

## Motion (kit durations, OutCubic, exit faster than enter)

| What | Property | In | Out |
|---|---|---|---|
| Hover fill (button) | opacity | 150 ms | 100 ms |
| Mark hover | glyph colour to primary | 150 ms | 100 ms |
| Press | scale to 0.97 | 100 ms | 100 ms |
| Label swap | opacity | 150 ms | 100 ms |
| Water rises | scaleY 0.2 to 1 from the bottom, opacity | 200 ms | 100 ms |
| Bubbles climb 8 px | y, opacity | 200 ms | 100 ms |
| Guided message, mark label | opacity | 150 ms | 100 ms |

Reduce motion (`SettingsData.reduceMotion`): opacity only, 150 ms; nothing scales, rises or climbs.
Cost: brief transitions on a direct gesture only. Nothing moves at rest and no timer runs at rest; the single 4 s `Timer` runs only while "Copied" is shown (value 6). No battery pill: the row has no lasting cost.

## Exact copy (English, no em dash)

| Part | Text |
|---|---|
| Title | Anonymous report |
| Help line | Versions, states and error codes only. It stays on this PC until you paste it. |
| Button | Copy report |
| Button while collecting | Collecting… |
| Button once copied | Copied |
| Help line once copied | Report copied. Read it, then paste it in a GitHub issue. |
| Guided message, reason | The report could not be copied |
| Guided message, what to do | Install wl-clipboard, or run dms ipc call abyss diagnostics in a terminal. |
| Mark beside the button, accessible name | Open a new issue for Abyss on GitHub |
| Mark beside the button, label on hover or focus | Open an issue on GitHub |
| Mark in the guided message, accessible name | Open the guide: Report a problem |

## Links (on click only, `Qt.openUrlExternally`; the plugin never touches the network)

- Mark beside the button: `https://github.com/lung595/Abyss/issues/new/choose` (D453, the model of every plugin; assumption Q153: what GitHub shows at this address while the repo has no bug form is not checked here). Constant address: the report is never put in it, nothing is prefilled.
- Mark in the guided message: `docs/GUIDE.md`, section "Report a problem" (anchor `#report-a-problem`, to be written with NAK-473).

## Accessibility

- Contrast: measured in the page for the palette shown (table "Contrast"), text pairs at 4.5:1 or more, UI parts at 3:1 or more, in the three fictitious themes, light and dark; the check fails on any value below.
- Targets: button 112 x 44, both marks 44 x 44.
- Focus order: "Full user guide", "Copy report", mark, then the mark of the guided message when shown.
- The help line and the guided message are announced when they change (`Accessible.announce` or equivalent); the state never rests on colour alone (label, check, text change).

## What the engineer builds (NAK-473)

1. The row in the Help column, on the wrapping row of NAK-423, with the sizes and tokens above.
2. The button states, the "Copied" water and bubbles, the 4 s timer that exists only while "Copied" shows.
3. The always visible `GitHubMark` button with its label and accessible name.
4. The guided message when no clipboard tool is found, with its mark to the guide.
5. An offscreen test that fails on any overlap at the narrow width.

## Assumptions and limits

- The IPC name in the guided message (`abyss diagnostics`) must match the call built in NAK-473.
- The widths 518 / 436 / 360 are the family's mockup widths (Sands NAK-535); 680 is added to show the one-line form. The real panel width was not measured in this story.
- "Full user guide" is drawn 44 px high here; it is built 34 px. Raising it is outside this story: the engineer keeps it as built unless asked.
- The rail and the cards' icons are simplified stand-ins in the mockup; they are not part of this spec.
- The page was verified by the offscreen geometry and contrast check, not by a pixel comparison.
