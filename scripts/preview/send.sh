#!/bin/sh
# Runs the send bench scene: send.sh file|folder, from the plugin's root.
# file: one 100 MB file; folder: a folder of 1000 files of 2 KB.
# PYTHON must have PySide6 (see tests/run.sh).
set -e
data=scripts/preview/bench-data
rm -rf "$data"
mkdir -p "$data"
if [ "$1" = folder ]; then
    mkdir "$data/item"
    i=0
    while [ $i -lt 1000 ]; do head -c 2048 /dev/zero > "$data/item/f$i"; i=$((i + 1)); done
else
    head -c 100000000 /dev/zero > "$data/item"
fi
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 "${PYTHON:-python3}" tests/qml/qmltest.py scripts/preview/send.qml &
pid=$!
# Stopped by the bench: take the scene and the data with it
trap 'kill $pid 2>/dev/null; wait $pid; rm -rf "$data"' INT TERM
wait $pid
rm -rf "$data"
