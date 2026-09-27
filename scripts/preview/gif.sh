#!/bin/sh
# Turns a frame-by-frame preview mode (fly, step, zoom, gif-sun,
# gif-refuse…) into a small looping GIF for the README, from the demo mesh.
# Usage: gif.sh <mode> <out.gif> <ms per frame> [width]
# Needs ffmpeg. The frames go to a temporary folder, removed afterwards.
set -e
mode=$1
out=$(realpath -m "$2")
ms=$3
width=${4:-580}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
"$(dirname "$0")/render.sh" "$mode" "$dir/f.png" >/dev/null 2>&1 || true
# A two-pass palette keeps the dark water smooth and the file small
ffmpeg -loglevel error -y -framerate "$((1000 / ms))" -i "$dir/f-%d.png" \
    -vf "scale=$width:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a" \
    -loop 0 "$out"
echo "$out: $(ls "$dir" | wc -l) frames"
