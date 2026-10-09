#!/bin/sh
# Runs every test: the pure JavaScript ones with gjs, then the QML
# integration ones (tests/qml/) when Python has PySide6.
#   tests/run.sh            all of them
#   PYTHON=/path/to/python tests/run.sh
set -u
cd "$(dirname "$0")/.."
PYTHON=${PYTHON:-python3}
export LC_ALL=C.UTF-8
failed=0

for t in tests/*.test.js; do
    out=$(gjs "$t" 2>&1) || { failed=1; printf '%s\n' "$out" | grep -v '^✓'; }
    printf '%s\n' "$out" | tail -n 1
done

if "$PYTHON" -c "import PySide6" 2>/dev/null; then
    for t in tests/qml/*.test.qml; do
        out=$(QT_QPA_PLATFORM=offscreen "$PYTHON" tests/qml/qmltest.py "$t" 2>&1) || { failed=1; printf '%s\n' "$out" | grep -v '^qml: ✓'; }
        printf '%s\n' "$out" | tail -n 1
    done
else
    echo "- QML integration tests skipped: $PYTHON has no PySide6 (pip install PySide6-Essentials)"
fi

# The app launcher: single instance and quit on close, offscreen
tests/app.sh || failed=1

# The scene tests need qml-qt6 and the DMS Material Symbols font (see tests/scene/run.sh)
if command -v qml-qt6 >/dev/null; then
    tests/scene/run.sh || failed=1
else
    echo "- Scene tests skipped: qml-qt6 not found"
fi

[ "$failed" = 0 ] && echo "All tests passed" || echo "Some tests FAILED"
exit "$failed"
