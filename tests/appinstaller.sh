#!/bin/sh
# The app installer's version probe with a real Quickshell Process, offscreen:
# `abyss` absent from PATH must still answer (state "install"), a fake `abyss`
# of the widget's version must answer "ok". Quickshell never emits `exited` for
# a binary it cannot start, so the probe runs through sh (regression test).
#   tests/appinstaller.sh
set -u
cd "$(dirname "$0")/.."
command -v qs >/dev/null || { echo "- App installer test skipped: qs not found"; exit 0; }
export QT_QPA_PLATFORM=offscreen
qsbin=$(command -v qs)
sh=$(command -v sh)

tmp=$(mktemp -d)
trap 'pkill -f "qs -p $tmp/scene" 2>/dev/null; rm -rf "$tmp"' EXIT

mkdir -p "$tmp/scene" "$tmp/bin" "$tmp/out"
cp components/AppInstall.js components/AppInstaller.qml "$tmp/scene/"
# Writes the answer to a file named after it, then quits
cat >"$tmp/scene/shell.qml" <<QML
import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
    AppInstaller {
        id: installer
        pluginDir: "$tmp"
        widgetVersion: "1.2.3"
        onChecked: state => {
            Quickshell.execDetached(["$(command -v touch)", "$tmp/out/" + state]);
            Qt.quit();
        }
        Component.onCompleted: refresh()
    }
}
QML
ln -s "$sh" "$tmp/bin/sh"
fail=0
run() { # name, expected state
    rm -f "$tmp/out/"*
    timeout 20 env PATH="$tmp/bin" "$qsbin" -p "$tmp/scene" >"$tmp/log" 2>&1
    [ -e "$tmp/out/$2" ] || { echo "FAIL $1: no '$2' answer "; tail -n 5 "$tmp/log"; fail=1; }
}
run "abyss absent from PATH answers" install
printf '#!/bin/sh\necho 1.2.3\n' >"$tmp/bin/abyss" && chmod +x "$tmp/bin/abyss"
run "abyss of the widget version" ok
printf '#!/bin/sh\necho 0.9\n' >"$tmp/bin/abyss"
run "abyss of another version" update

[ "$fail" = 0 ] && echo "✓ appinstaller: version probe with a real Process" || echo "appinstaller: FAILED"
exit "$fail"
