#!/bin/sh
# Renders the deep offscreen from the demo mesh (made-up names and
# addresses, no real device involved). Needs Qt 6 and a DMS install for
# the Material Symbols font.
# Usage: render.sh <mode> <out.png>   (modes: see shot.qml)
set -e
cd "$(dirname "$0")"
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl QT_FORCE_STDERR_LOGGING=1 \
    qml-qt6 -I imports shot.qml -- "$1" "$(realpath -m "$2")"
