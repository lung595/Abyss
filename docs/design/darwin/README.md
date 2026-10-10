# Darwin model sheet

Our own vector drawing of Darwin, neutral pose. Work in progress: not yet
approved, and not used by the widget.

| File | View | Space |
|---|---|---|
| `darwin-front.svg` | front | 729 px wide, same as `components/assets/darwin/body.png`; the viewBox adds 12 px on the left for the tail fin, 4 px on the right, 8 px on top |
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
| Band at the tail base (swimming) | `#d9641c` | |
| Eye white | `#e4e3e8` | |

These are the character's own colours, sampled from the references. They do
not follow the DMS theme on purpose (decision D420 in the project notes): the
exception covers Darwin's drawing only.

Contrast, measured on the real scene (the deep stays dark in both themes:
`#0f0f19` dark, `#0a0914` light): body 7.13:1 and 7.40:1, eye white 14.92:1
and 15.49:1, outline 1.04:1 and 1.00:1. The outline is invisible in the deep;
the body colour and the eyes carry the shape. On a plain light surface
(`#f3f6f9`) the body is 2.46:1 and the outline 18.25:1.

## Known differences from the references

Checked by drawing our ink edges over the reference frame brought into the
SVG space (front: reference scaled 1.762 from its 1280 px frame, the scale
being the ratio of the two body masks, 715 px against 406 px wide).

- Front: body outline, eyes, pupils, cheeks, mouth, legs and tail fin lie on
  the reference lines within about 3 px in the 729 space (looked at on the
  edge overlay, not computed part by part). The body outline alone was
  fitted by 48 rays: mask bounding box 724 x 453 against 725 x 453, 0.49 %
  of the pixels differ. Remaining: brows are a single 18 px stroke where the
  reference draws a tapered wedge; pupils are pure ink where the printed
  frame shows dark grey; colours come from the swimming frame, the poster
  being a desaturated print (body `#d67028` there).
- Swimming: the body outline is fitted by 48 rays onto the reference
  (`SWIM_PTS` in `build.py`), 39 rays measured and 9 kept from the hand
  tracing where the leg, the arm or the tail fin hide the edge. Before the
  fit our outline was 9.1 px too far out on average (14.2 px at worst) in
  the 680 space; after it the same measurement gives 0.6 px on average and
  4.0 px at worst. Eyes, cheeks, arm and leg are still placed by eye, within
  about 10 px. The low fin is smaller than on the reference and the left
  eye slightly smaller. Brows are neutral on purpose (the reference
  frowns). The mouth is a single curve; the reference has a kink.
- Outline weight: 7 px in the 729 space and 5 px in the 680 space. The two
  bodies are 670 px and 460 px wide in their spaces, so the stroke is 1.04 %
  and 1.09 % of the body width: the same weight on the character.
- No three-quarter or true side view: no reference shows one. Shoes are not
  drawn: no reference shows them.
