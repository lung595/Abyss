#!/bin/sh
# Renders the grab design prototypes (grab.qml, NAK-335) offscreen from demo
# creatures: one looping GIF per proposal and theme, plus the still pose that
# Reduce motion shows. Nothing here is shipped with the plugin.
# Usage: grab.sh [out dir]   (default: docs/design/grab)
# Needs Qt 6 and ffmpeg. Frames go to a temporary folder, removed afterwards.
set -e
here=$(cd "$(dirname "$0")" && pwd)
out=$(realpath -m "${1:-$here/../../docs/design/grab}")
mkdir -p "$out"
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$here"
shot() {
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl QT_FORCE_STDERR_LOGGING=1 \
        timeout 120 qml-qt6 -I imports grab.qml -- "$@" >/dev/null 2>&1 || true
}
for look in dark light; do
    for variant in before a b; do
        rm -f "$dir"/f-*.png
        shot "$variant" "$look" anim "$dir/f.png"
        # A two-pass palette keeps the water smooth and the file small
        ffmpeg -loglevel error -y -framerate 50/3 -i "$dir/f-%d.png" \
            -vf "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a" \
            -loop 0 "$out/$variant-$look.gif"
        echo "$variant-$look.gif: $(ls "$dir" | grep -c '^f-') frames"
    done
done
for variant in a b; do
    shot "$variant" dark still "$out/$variant-reduce-motion.png"
done
