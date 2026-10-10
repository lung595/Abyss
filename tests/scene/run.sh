#!/bin/sh
# Runs the scene tests (tests/scene/*.test.qml) offscreen with qml-qt6 and
# the fake shell modules of scripts/preview/imports.
#   tests/scene/run.sh
set -u
cd "$(dirname "$0")/../.."
failed=0
for t in tests/scene/*.test.qml; do
    out=$(QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="qml.debug=true" timeout 120 qml-qt6 -I tests/scene/imports -I scripts/preview/imports "$t" 2>&1) || { failed=1; printf '%s\n' "$out" | grep -E 'FAIL|got:|Error|error|Warning: ' ; }
    printf '%s\n' "$out" | grep -E '^(qml: )?[✓✗] ' | tail -n 1
done
exit "$failed"
