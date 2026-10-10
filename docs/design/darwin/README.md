# Darwin model sheet

Our own vector drawing of Darwin, neutral pose. Work in progress: not yet
approved, and not used by the widget.

| File | View | Space |
|---|---|---|
| `darwin-front.svg` | front | 729 px wide, same as `components/assets/darwin/body.png` |
| `darwin-swim.svg` | swimming, turned | 680 x 480 |
| `*@1x.png` | real widget size (25 px wide, `unit` 0.034 in `Goldfish.qml`) | |
| `*@4x.png` | 100 px wide | |
| `scene-dark.png`, `scene-light.png` | both views on a plain dark and light backdrop | stand-in, not the real scene |

Rebuild: `python3 build.py .` then render the SVG files with ImageMagick.

## Sampled values

| Role | Value | Note |
|---|---|---|
| Outline | `#0a0a0a`, 7 px in the 729 space | |
| Body | `#f47e26` | |
| Highlight, cheeks | `#f6bc8c` | |
| Limbs | `#f49c52` | |
| Eye white | `#e4e3e8` | |

Contrast of the body colour: 6.94:1 on `#0e1418`, 2.46:1 on `#f3f6f9`; the
outline carries the shape on light backdrops (18.25:1) and disappears on
dark ones (1.07:1).

## Known differences from the references

- Front: legs are thinner and closer together, with a darker outline; tail
  fin shape and stripes are approximate; lower cheek arcs sit a few px high.
- Swimming: the top-right notch where the leg meets the body is missing; the
  arm joins the body with a visible corner; the tail fin is simplified; the
  mouth is a single curve; brows are neutral on purpose (the reference frowns).
- No three-quarter view yet. Shoes are not drawn: no reference shows them.
