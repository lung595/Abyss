#!/bin/sh
# Runs the Send view bench scene: bench-send.sh <idle|rsync|hidden>, from the
# plugin's root. PYTHON must have PySide6 (see tests/run.sh).
set -e
echo "${1:-idle}" > scripts/preview/mode
touch /tmp/a.txt
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 "${PYTHON:-python3}" tests/qml/qmltest.py scripts/preview/bench-send.qml &
pid=$!
trap 'kill $pid 2>/dev/null; wait $pid' INT TERM
wait $pid
