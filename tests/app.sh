#!/bin/sh
# The app's launcher, offscreen: a second `abyss` must wake the first instead
# of starting another process, and closing the window must end the process.
#   tests/app.sh
set -u
cd "$(dirname "$0")/.."
command -v qs >/dev/null || { echo "- App launcher test skipped: qs not found"; exit 0; }
export QT_QPA_PLATFORM=offscreen

# A private copy under a unique path: pgrep then sees only this test's process
tmp=$(mktemp -d)
trap 'pkill -f "qs -p $tmp/app" 2>/dev/null; rm -rf "$tmp"' EXIT
# -L: the app reaches the shared settings folder through a symlink
cp -rL app "$tmp/app"
# The app writes its settings file: keep it out of the real config
export XDG_CONFIG_HOME="$tmp/config"
count() { pgrep -fc "[q]s -p $tmp/app"; }
fail=0
check() { [ "$2" = "$3" ] || { echo "FAIL $1: got $2, want $3"; fail=1; }; }

"$tmp/app/abyss" send atlas /tmp/a >/dev/null 2>&1 &
for _ in 1 2 3 4 5 6 7 8 9 10; do [ "$(count)" = 1 ] && break; sleep 0.5; done
sleep 1
check "first launch starts one process" "$(count)" 1
"$tmp/app/abyss" map >/dev/null 2>&1
check "second launch creates no second process" "$(count)" 1
"$tmp/app/abyss" map extra >/dev/null 2>&1
check "a refused request still creates none" "$(count)" 1
"$tmp/app/abyss" --wat >/dev/null 2>&1
check "an option-like word creates no second process" "$(count)" 1
check "help starts nothing" "$("$tmp/app/abyss" --help | head -n 1)" "Usage: abyss [command]"

# Closing the window quits: a copy whose window closes itself after a moment
rm -rf "$tmp/app" && cp -rL app "$tmp/app"
sed -i 's|^        visible: true|        visible: true\n        Timer { running: true; interval: 1000; onTriggered: window.visible = false }|' "$tmp/app/shell.qml"
pkill -f "qs -p $tmp/app" 2>/dev/null
"$tmp/app/abyss" >/dev/null 2>&1 &
sleep 4
check "closing the window ends the process" "$(count)" 0

[ "$fail" = 0 ] && echo "✓ app: launcher and single instance" || echo "app: FAILED"
exit "$fail"
