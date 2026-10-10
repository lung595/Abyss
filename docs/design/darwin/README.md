# Darwin model sheet

Our own vector drawing of Darwin, neutral pose. Work in progress: not yet
approved, and not used by the widget.

| File | View | Space |
|---|---|---|
| `darwin-front.svg` | front | 729 px wide, same as `components/assets/darwin/body.png` |
| `darwin-swim.svg` | swimming, turned | 680 x 480 |
| `*@1x.png` | real widget size (25 px wide, `unit` 0.034 in `Goldfish.qml`) | |
| `*@4x.png` | 100 px wide | |
| `scene-dark.png`, `scene-light.png` | both views at real size in the real desktop bowl (`scripts/preview/render.sh desk`, `desk-light`), composited, with a 6x zoom below | |

Rebuild:

```sh
python3 build.py .
for v in front swim; do
  magick -background none darwin-$v.svg -resize 25x darwin-$v@1x.png
  magick -background none darwin-$v.svg -resize 100x darwin-$v@4x.png
done
```

## Sampled values

| Role | Value | Note |
|---|---|---|
| Outline | `#0a0a0a`, 7 px in the 729 space | |
| Body | `#f47e26` | |
| Highlight, cheeks | `#f6bc8c` | |
| Limbs | `#f49c52` | |
| Eye white | `#e4e3e8` | |

Contrast, measured on the real scene (the deep stays dark in both themes:
`#0f0f19` dark, `#0a0914` light): body 7.13:1 and 7.40:1, eye white 14.92:1
and 15.49:1, outline 1.04:1 and 1.00:1. The outline is invisible in the deep;
the body colour and the eyes carry the shape. On a plain light surface
(`#f3f6f9`) the body is 2.46:1 and the outline 18.25:1.

## Known differences from the references

- Front: the body outline is fitted by measurement, 48 rays onto the
  reference silhouette in the 729 space. Silhouette mask against the
  reference, legs excluded: bounding box 724 x 453 against 725 x 453 (1 px),
  0.49 % of the pixels differ (1247 of 256487). Still by eye: the tail fin
  strokes, the brows (the reference ones sit a few px higher) and the lower
  cheek arcs (a few px lower on the reference). Pupils are pure ink where
  the printed frame shows dark grey. Colours come from the swimming frame,
  the poster being a desaturated print.
- Swimming: the tail fin is simplified; brows are neutral on purpose (the
  reference frowns).
- No three-quarter or true side view: no reference shows one. Shoes are not
  drawn: no reference shows them.
