# Darwin model sheet

Our own vector drawing of Darwin, neutral pose. Work in progress: not yet
approved, and not used by the widget.

| File | View | Space |
|---|---|---|
| `darwin-front.svg` | front | 729 px wide, same as `components/assets/darwin/body.png`; the viewBox adds 12 px on the left for the tail fin, 4 px on the right, 8 px on top |
| `darwin-swim.svg` | swimming, turned | 680 x 480 |
| `darwin-three-quarter.svg`, `darwin-profile.svg` | three-quarter and profile, deduced from the front view | the front space, 660 and 500 wide |
| `darwin-front-25.svg`, `darwin-three-quarter-25.svg`, `darwin-profile-25.svg`, `darwin-swim-25.svg` | optical variants for the real widget size | 25 x 21, 22 x 21, 17 x 21 and 25 x 18, one unit = one pixel |
| `*@1x.png` | the optical variants rendered 1:1 (25 px wide, `unit` 0.034 in `Goldfish.qml`) | |
| `*@4x.png` | four times the real size: front and swimming 100 px wide, three-quarter 89, profile 67 (one scale, 100 / 745, for the three views of the front space) | |
| `scene-dark.png`, `scene-light.png`, `scene-wallpaper.png` | the four views at real size in the real desktop bowl (`scripts/preview/render.sh desk`, `desk-light`, and `desk` with a made-up warm wallpaper palette in the preview `Theme`), composited at +328+356 (front), +360+356 (three-quarter), +389+356 (profile) and +413+357 (swimming), with a 6x unsmoothed zoom below | |

Rebuild:

```sh
python3 build.py .
for v in front:100 three-quarter:89 profile:67 swim:100; do
  magick -background none darwin-${v%:*}-25.svg darwin-${v%:*}@1x.png
  magick -background none darwin-${v%:*}.svg -resize ${v#*:}x darwin-${v%:*}@4x.png
done
# scenes: <mode> is desk, desk-light, or desk with the wallpaper palette below
../../../scripts/preview/render.sh <mode> top.png
magick top.png darwin-front@1x.png -geometry +328+356 -composite \
  darwin-three-quarter@1x.png -geometry +360+356 -composite \
  darwin-profile@1x.png -geometry +389+356 -composite \
  darwin-swim@1x.png -geometry +413+357 -composite top.png
magick top.png \( top.png -crop 130x60+312+336 +repage -filter point -resize 600% \) \
  -append -strip scene-<name>.png
```

The offscreen scene is alive (the demo mesh moves), so two renders differ by
about 0.5 % of their pixels: the scenes are composited on fresh renders,
never patched in place. Checked after compositing: every opaque pixel of both
`@1x` files is found unchanged in the three scenes (0 differing pixels).

Wallpaper-generated theme: the preview has no wallpaper mode, so its `Theme`
stub is given this made-up warm palette for one render, then restored:
primary `#ffb77c`, primaryText `#4d2700`, secondary `#e3c0a5`, tertiary
`#c8ca94`, surface `#1a120c`, surfaceContainer `#271e17`, High `#322821`,
Highest `#3d332b`, surfaceText `#f0dfd4`, surfaceVariantText `#d6c3b6`,
outline `#9e8e81`.

The measured front overlay (outside the repository, it holds the reference):

```sh
magick <poster frame> -virtual-pixel white -define distort:viewport=745x612+0+0 \
  -distort SRT '666.35,207.92 1.762 0 0,0' +repage ref.png
magick -background none darwin-front.svg -alpha remove -background white -fuzz 12% \
  -fill white +opaque '#0A0A0A' -fill black -opaque '#0A0A0A' -negate \
  -morphology EdgeIn Diamond:1 edge.png
magick ref.png \( -size 745x612 xc:'#00E5FF' edge.png -alpha off \
  -compose CopyOpacity -composite \) -composite front-overlay-measured.png
```

The two side-by-side boards (outside the repository, they hold the
references): reference, ours, 50 % overlay, at one scale. Front: the poster
frame brought into the SVG space as above, ours on the poster's backdrop
colour. Swimming: the 1400 x 700 frame is cropped, not scaled; the SVG origin
is at +352+50 in it (found by an exact sub-image match).

```sh
magick -background '#bcd3e6' darwin-front.svg -alpha remove -alpha off ours.png
magick ref.png ours.png -compose blend -define compose:args=50 -composite mix.png
magick ref.png ours.png mix.png +append -strip front-ref-vs-ours.png

magick <swimming frame> -crop 684x480+350+50 +repage ref.png
magick -size 684x480 xc:white \( -background none darwin-swim.svg \) \
  -geometry +2+0 -composite -alpha off ours.png
magick ref.png ours.png -compose blend -define compose:args=50 -composite mix.png
magick ref.png ours.png mix.png +append -strip swim-ref-vs-ours.png
```

Both were rebuilt from the smoothed drawings and looked at: the front
overlay shows one line; the swimming overlay still shows a double line on the
right edge of the body and along the arm (the 4 px worst case below).

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

| Backdrop, every pixel of the 130x60 px zone around both views, Darwin excluded (darkest to lightest) | Body | Eye white | Outline |
|---|---|---|---|
| dark theme, `#0e0e18` to `#1d1d27` | 7.18 to 6.25:1 | 15.03 to 13.09:1 | 1.03 to 1.19:1 |
| light theme, `#090814` to `#171622` | 7.44 to 6.69:1 | 15.57 to 14.01:1 | 1.00 to 1.11:1 |
| warm wallpaper-generated theme, `#100e11` to `#211d20` | 7.19 to 6.23:1 | 15.05 to 13.04:1 | 1.03 to 1.19:1 |

Zone: origin (310,336) in each 780x980 scene frame, 7199 backdrop pixels per
scene. The lightest pixels are on the thread that crosses the deep behind
Darwin. An independent measurement on a slightly different zone found
`#1f1e29` as the lightest pixel of the dark scene: body 6.16:1, eye white
12.89:1. That is the worst case to quote; it stays above 4.5:1 for the body
and the eyes.

The outline is invisible in the deep; the body colour and the eyes carry the
shape (outline on body: 7.41:1). On a plain light surface (`#f3f6f9`) the
body is 2.46:1 and the outline 18.25:1.

## Known differences from the references

Checked by drawing our ink edges over the reference frame brought into the
SVG space (front: reference scaled 1.762 from its 1280 px frame, the scale
being the ratio of the two body masks, 715 px against 406 px wide).
The overlay was rebuilt from the final drawing and looked at: outline, eyes,
pupils, cheeks and both brows sit on the reference ink.

- Front: body outline, eyes, pupils, cheeks, mouth, legs and tail fin lie on
  the reference lines within about 3 px in the 729 space (looked at on the
  edge overlay, not computed part by part). The body outline alone was
  fitted by 48 rays: mask bounding box 724 x 453 against 725 x 453, 0.49 %
  of the pixels differ. The tail fin is
  redrawn from the reference: fused to the body, the body line curling into
  it at both ends, two short strokes. Brows are the ink blobs of the
  reference traced every 6 px at half coverage (`BROW_L`, `BROW_R` in
  `build.py`): 225 of 2032 and 296 of 1746 brow pixels differ from the
  reference, about 1 px along the edge. Lashes are short 5 px ticks on the
  upper outer arc of each eye, placed from a 3x crop of the reference (by
  eye, about 3 px). Remaining: pupils are pure ink where the printed
  frame shows dark grey; colours come from the swimming frame, the poster
  being a desaturated print (body `#d67028` there).
- Swimming: the body outline is fitted by 48 rays onto the reference
  (`SWIM_PTS` in `build.py`), 39 rays measured and 9 kept from the hand
  tracing where the leg, the arm or the tail fin hide the edge. Before the
  fit our outline was 9.1 px too far out on average (14.2 px at worst) in
  the 680 space; after it the same measurement gives 0.6 px on average and
  4.0 px at worst. Eyes, pupils and cheek spots are set from the connected
  regions of the reference (centroid and bounding box): right eye white
  within 1.6 px, pupils 0.7 px, cheek spots 1.0 px; the left eye white is
  2.5 px higher than the reference region because the reference brow cuts
  its top and ours is neutral. Cheek arcs are least-squares circles on the
  reference ink (mean residual 1.3 px and 1.2 px). The mouth follows the ink
  read every 6 px, a shallow curve from cheek to cheek. The low fin follows
  the ink line read every 8 px (`SWIM_FIN`), with the two long strokes and
  the tick under the arm that the reference shows (it has two strokes, not
  three). Arm, leg, lashes and brows are still placed by eye. Brows are
  neutral on purpose (the reference frowns).
- Outline weight: 7 px in the 729 space and 5 px in the 680 space. The two
  bodies are 670 px and 460 px wide in their spaces, so the stroke is 1.04 %
  and 1.09 % of the body width: the same weight on the character.
- No three-quarter or true side view: no reference shows one. Shoes are not
  drawn: no reference shows them.

## Smoothness and deduced views (owner feedback, 2026-10-10)

- **Smoother outlines.** The body outline of both views is no longer a spline
  through the 48 measured points (their 1 px rounding showed as a wobble). The
  48 radii are kept as a periodic function of the angle, cut to 12 harmonics,
  and drawn with 24 anchors and analytic tangents (`outline()` in `build.py`).
  Measured: curvature sign changes 26 to 8 (front) and 32 to 8 (swimming);
  distance to the measured points 1.10 px mean, 4.97 px max (front, 729 space)
  and 0.87 px mean, 4.17 px max (swimming, 680 space), under 0.2 px at 25 px.
  Front brows are a smooth closed curve through every other traced point
  instead of a polygon. Proportions, colours and expression are unchanged.
- **Three-quarter and profile views** (`darwin-three-quarter.svg`,
  `darwin-profile.svg`, `@4x` PNG) are **deduced, not traced**: no reference
  shows them. Rule: the front body is turned about its vertical axis as an
  ellipsoid 0.6 times as deep as wide (assumed ratio), 40 degrees and 90
  degrees; the silhouette narrows toward the tail, the tail fin, legs, stroke
  and colours are the front ones; face parts are the front ones moved onto the
  turned surface (far eye narrower). In profile one eye, one cheek and the end
  of the mouth are shown.
- **Turned views, second pass (score 83, 2026-10-10).** Three-quarter: the far
  eye is pulled back until it clears the body line by two stroke widths over
  its whole height (computed on the outline, `right_edge()` in `build.py`), its
  pupil, cheek and brow move with it, the far brow is cut at the body line and
  the far lashes, on the side turned away, are not drawn. Profile: the eye and
  the brow are set the same way, two stroke widths inside the body line; both
  legs are on the view axis, the far one shows 22 px behind the near one.
- 25 px optical variants of both turned views, at the front view's scale
  (22 and 17 px wide); the four views are in the three scenes. Contrast
  measured again on every backdrop pixel of the 130 x 60 zone outside the four
  drawings (6006 pixels per scene): body 6.25 to 7.18:1 (dark), 6.63 to 7.44:1
  (light), 6.23 to 7.19:1 (wallpaper theme); eye white 13.04 to 15.57:1;
  outline 1.00 to 1.19:1 (invisible, the body carries the shape).
- The inset is taken along x (14 px between the two stroke centres, so 7 px
  of body on a horizontal line). Where the body line slants, the gap measured
  across it is smaller: 9.0 and 9.5 px between centres, that is 5.5 to 6 px
  of visible body (measured by the UI Designer), not a full stroke width.
- Not done: the 0.6 depth ratio is an assumption (Q129); the profile keeps the front
  tail fin seen flat (a real profile would show it edge-on or fanned, no
  reference says which).
