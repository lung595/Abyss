#!/bin/sh
# Offscreen capture of the app window (fictitious state only).
#   scripts/preview/app.sh <dark|light> <station> <out.png> [compact]
set -eu
cd "$(dirname "$0")/../.."
scheme=${1:-dark}; station=${2:-map}; out=${3:-app-$scheme-$station.png}; size=${4:-full}
case $out in /*) ;; *) out=$PWD/$out ;; esac
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl timeout 60 \
    qml-qt6 -I tests/scene/imports scripts/preview/app.qml "$size" "$station" "$out" "ABYSS_SCHEME=$scheme" 2>&1 | grep -v '^$' | head -5 || true
[ -s "$out" ] || { echo "app.sh: no capture written" >&2; exit 1; }
