# Darwin model sheet

Our own vector drawing of Darwin, neutral pose. Work in progress: not yet
approved, and not used by the widget.

| File | View | Space |
|---|---|---|
| `darwin-front.svg` | front | 729 px wide, same as `components/assets/darwin/body.png`; the viewBox adds 12 px on the left for the tail fin, 4 px on the right, 8 px on top |
| `darwin-swim.svg` | swimming, turned | 680 x 480 |
| `darwin-front-25.svg`, `darwin-swim-25.svg` | optical variants for the real widget size | 25 x 21 and 25 x 18, one unit = one pixel |
| `*@1x.png` | the optical variants rendered 1:1 (25 px wide, `unit` 0.034 in `Goldfish.qml`) | |
| `*@4x.png` | 100 px wide | |
| `scene-dark.png`, `scene-light.png`, `scene-wallpaper.png` | both views at real size in the real desktop bowl (`scripts/preview/render.sh desk`, `desk-light`, and `desk` with a made-up warm wallpaper palette in the preview `Theme`), composited at +328+356 and +398+357, with a 6x unsmoothed zoom below | |

Rebuild:

```sh
python3 build.py .
for v in front swim; do
  magick -background none darwin-$v-25.svg darwin-$v@1x.png
  magick -background none darwin-$v.svg -resize 100x darwin-$v@4x.png
done
```

## Optical size (25 px)

At the widget size one pixel is about 30 units of the drawing, so the 7 px
outline, the lashes, the brows and the mouth are thinner than a third of a
pixel. The `-25` variants keep the silhouette of the drawing scaled down and
redraw on whole pixels what would otherwise blur: eye whites (6 px, 5 px
when swimming), pupils (3 px, 2 px), cheeks and legs (2 px wide). Lashes,
brows and mouth are left out. When swimming, one pixel of body is kept
between the two eyes. Checked on a 12x unsmoothed enlargement.

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

Contrast, measured on the real scene (the deep stays dark whatever the
theme):

| Backdrop sampled next to Darwin | Body | Eye white | Outline |
|---|---|---|---|
| dark theme, `#10101a` | 7.07:1 | 14.81:1 | 1.05:1 |
| light theme, `#0b0a15` | 7.36:1 | 15.40:1 | 1.01:1 |
| warm wallpaper-generated theme (made-up palette, primary `#ffb77c`, surface `#1a120c`), `#131013` | 7.07:1 | 14.81:1 | 1.05:1 |

The outline is invisible in the deep; the body colour and the eyes carry the
shape (outline on body: 7.41:1). On a plain light surface (`#f3f6f9`) the
body is 2.46:1 and the outline 18.25:1.

## Known differences from the references

Checked by drawing our ink edges over the reference frame brought into the
SVG space (front: reference scaled 1.762 from its 1280 px frame, the scale
being the ratio of the two body masks, 715 px against 406 px wide).

- Front: body outline, eyes, pupils, cheeks, mouth, legs and tail fin lie on
  the reference lines within about 3 px in the 729 space (looked at on the
  edge overlay, not computed part by part). The body outline alone was
  fitted by 48 rays: mask bounding box 724 x 453 against 725 x 453, 0.49 %
  of the pixels differ. The tail fin is
  redrawn from the reference: fused to the body, the body line curling into
  it at both ends, two short strokes. Brows are solid tapered wedges and the
  lashes short 5 px ticks on the upper outer arc of each eye, both placed
  from a 3x crop of the reference (by eye, about 3 px). Remaining: pupils are pure ink where the printed
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
