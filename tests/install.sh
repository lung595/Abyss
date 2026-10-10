#!/bin/sh
# The app installer in a scratch HOME: the install puts the command and the
# entry in place, the uninstall leaves the tree exactly as it was, and nothing
# that is not Abyss's is ever touched.
#   tests/install.sh
set -u
cd "$(dirname "$0")/.."
root=$PWD
fail=0
check() { [ "$2" = "$3" ] || { echo "FAIL $1: got $2, want $3"; fail=1; }; }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
# A space in HOME exercises the quoting of Exec
export HOME="$scratch/my home"
unset XDG_DATA_HOME
mkdir -p "$HOME/.local/bin"   # already there before the install: must survive
tree() { find "$HOME" -printf '%P %y\n' | sort; }

before=$(tree)
sh "$root/install-app.sh" >/dev/null 2>&1
check "the command is linked" "$(readlink "$HOME/.local/bin/abyss")" "$HOME/.local/share/abyss/abyss"
check "the entry quotes the path" "$(grep '^Exec=' "$HOME/.local/share/applications/abyss.desktop")" "Exec=\"$HOME/.local/share/abyss/abyss\""
sh "$root/install-app.sh" >/dev/null 2>&1
check "a second install works" "$?" 0
sh "$root/install-app.sh" --uninstall >/dev/null 2>&1
check "uninstall restores the tree" "$(tree)" "$before"

# The shared settings file: kept while the widget is installed, removed after it
check "the install ships the settings store" "$(sh "$root/install-app.sh" >/dev/null 2>&1; ls "$HOME/.local/share/abyss/components/settings" | tr '\n' ' ')" "qmldir SettingsFile.qml Store.js "
mkdir -p "$HOME/.config/abyss" "$HOME/.config/DankMaterialShell/plugins/Abyss"
echo '{}' >"$HOME/.config/abyss/settings.json"
touch "$HOME/.config/DankMaterialShell/plugins/Abyss/plugin.json"
sh "$root/install-app.sh" --uninstall >/dev/null 2>&1
check "the settings stay while the widget is installed" "$([ -f "$HOME/.config/abyss/settings.json" ] && echo kept)" kept
sh "$root/install-app.sh" >/dev/null 2>&1
rm -r "$HOME/.config/DankMaterialShell"
sh "$root/install-app.sh" --uninstall >/dev/null 2>&1
check "the settings go when the widget is gone" "$([ -e "$HOME/.config/abyss" ] && echo left || echo gone)" gone
rmdir "$HOME/.config" 2>/dev/null
check "uninstall restores the tree again" "$(tree)" "$before"

# Foreign files with Abyss's names are never overwritten or removed
mkdir -p "$HOME/.local/share/abyss"
echo mine >"$HOME/.local/share/abyss/data"
sh "$root/install-app.sh" >/dev/null 2>&1
check "a foreign data folder blocks the install" "$?" 1
sh "$root/install-app.sh" --uninstall >/dev/null 2>&1
check "uninstall keeps a foreign data folder" "$(cat "$HOME/.local/share/abyss/data")" mine
rm -rf "$HOME/.local/share/abyss"

mkdir -p "$HOME/.local/share/applications"
echo foreign >"$HOME/.local/share/applications/abyss.desktop"
sh "$root/install-app.sh" >/dev/null 2>&1
check "a foreign entry blocks the install" "$?" 1
rm "$HOME/.local/share/applications/abyss.desktop"
ln -s /nowhere "$HOME/.local/bin/abyss"
sh "$root/install-app.sh" >/dev/null 2>&1
check "a foreign command blocks the install" "$?" 1
rm "$HOME/.local/bin/abyss"
rmdir "$HOME/.local/share/applications" "$HOME/.local/share" 2>/dev/null

# Folders the install created go away; folders that were there stay
before=$(tree)
sh "$root/install-app.sh" >/dev/null 2>&1
sh "$root/install-app.sh" --uninstall >/dev/null 2>&1
check "uninstall restores the tree again" "$(tree)" "$before"

[ "$fail" = 0 ] && echo "✓ install: app installer and uninstaller" || echo "install: FAILED"
exit "$fail"
