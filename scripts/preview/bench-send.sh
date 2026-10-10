#!/bin/sh
# Runs the Send view bench scene: bench-send.sh <idle|rsync|hidden>, from the
# plugin's root. PYTHON must have PySide6 (see tests/run.sh). exec, so the
# bench measures the Qt process itself (and the fake programs it reaps).
set -e
echo "${1:-idle}" > scripts/preview/mode
touch /tmp/a.txt
export QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1
exec "${PYTHON:-python3}" tests/qml/qmltest.py scripts/preview/bench-send.qml
