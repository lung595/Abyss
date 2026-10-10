#!/bin/sh
# Installs the Abyss app for the current user, under ~/.local only:
#   <data>/abyss/            the app (window, parser, launcher, usage text)
#   ~/.local/bin/abyss       a link to the launcher
#   <data>/applications/abyss.desktop
# The settings file (<config>/abyss/settings.json) is shared with the widget: the
# install never creates it, the uninstall removes it only when the widget is gone.
# `install-app.sh --uninstall` removes exactly these and the folders the install
# itself created, nothing else. Run it from a checkout; nothing is downloaded,
# nothing needs root.
set -eu

src=$(cd -- "$(dirname -- "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}
home_dir=$data/abyss
bin_dir=$HOME/.local/bin
# XDG: a relative XDG_CONFIG_HOME must be ignored (the app does the same)
case ${XDG_CONFIG_HOME:-} in
/*) config=$XDG_CONFIG_HOME ;;
*) config=$HOME/.config ;;
esac
settings_dir=$config/abyss
# The widget is installed when its plugin manifest is in the DMS plugins folder
widget_manifest=$config/DankMaterialShell/plugins/Abyss/plugin.json
link=$bin_dir/abyss
entry=$data/applications/abyss.desktop
# Proof the folder is ours; it also lists the folders the install had to create
marker=$home_dir/.abyss-app

# True when the command link is Abyss's own
ours() {
    [ -L "$link" ] && [ "$(readlink -- "$link")" = "$home_dir/abyss" ]
}

# True when the desktop entry is Abyss's own (it launches our launcher)
entry_ours() {
    [ -f "$entry" ] && grep -qxF "Exec=\"$home_dir/abyss\"" "$entry"
}

case "${1-}" in
--uninstall)
    if [ ! -f "$marker" ]; then
        echo "Nothing to remove: $home_dir is not an Abyss app install." >&2
        exit 0
    fi
    # The link and the entry only when they are ours, so a command or an entry
    # named abyss from elsewhere stays
    if ours; then
        rm -- "$link"
    fi
    if entry_ours; then
        rm -- "$entry"
    fi
    created=$(sed -n 's/^dir //p' "$marker")
    rm -rf -- "$home_dir"
    # The shared settings go with the app only when the widget no longer needs
    # them; the folder only when nothing else lives in it
    if [ ! -e "$widget_manifest" ]; then
        rm -f -- "$settings_dir/settings.json"
        rmdir -- "$settings_dir" 2>/dev/null || true
    fi
    # Folders the install made, deepest first, and only when nothing else lives in them
    printf '%s\n' "$created" | sort -r | while IFS= read -r dir; do
        [ -n "$dir" ] && rmdir -- "$dir" 2>/dev/null || true
    done
    echo "Abyss app removed."
    exit 0
    ;;
"") ;;
*)
    echo "Usage: install-app.sh [--uninstall]" >&2
    exit 2
    ;;
esac

if { [ -e "$link" ] || [ -L "$link" ]; } && ! ours; then
    echo "$link already exists and is not Abyss's: not touching it." >&2
    exit 1
fi
if [ -e "$home_dir" ] && [ ! -f "$marker" ]; then
    echo "$home_dir already exists and is not Abyss's: not touching it." >&2
    exit 1
fi
if { [ -e "$entry" ] || [ -L "$entry" ]; } && ! entry_ours; then
    echo "$entry already exists and is not Abyss's: not touching it." >&2
    exit 1
fi
# A quoted Exec path cannot hold these without escapes the desktop spec makes fragile
case $home_dir in
*[\"\`\$\\%]* | *'
'*)
    echo "The install path holds a character a desktop entry cannot quote: set XDG_DATA_HOME elsewhere." >&2
    exit 1
    ;;
esac

# Folders this install creates are remembered (an earlier install's too) so that
# the uninstall removes them and no folder that was already there
created=
[ -f "$marker" ] && created=$(sed -n 's/^dir //p' "$marker")
for dir in "$data" "$data/applications" "$bin_dir" "$home_dir"; do
    [ -d "$dir" ] || created="$created
$dir"
done

# Only the app's own files: the widget (QML at the repository root) is not part of it
rm -rf -- "$home_dir"
mkdir -p -- "$home_dir/components/settings" "$data/applications" "$bin_dir"
cp -- "$src/app/shell.qml" "$src/app/usage.txt" "$src/app/abyss" "$home_dir/"
cp -L -- "$src/app/components/"*.js "$src/app/components/"*.qml "$src/app/components/qmldir" "$home_dir/components/"
cp -rL -- "$src/app/components/assets" "$home_dir/components/"
mkdir -p -- "$home_dir/views"
cp -- "$src/app/views/"*.qml "$home_dir/views/"
cp -- "$src/components/settings/"* "$home_dir/components/settings/"
printf '%s\n' "$created" | sed -n 's/^\(..*\)$/dir \1/p' >"$marker"
ln -sf -- "$home_dir/abyss" "$link"

# The desktop entry gets the full quoted path: a menu does not always have
# ~/.local/bin in its PATH, and the path may hold a space
while IFS= read -r line; do
    case $line in
    Exec=abyss) printf 'Exec="%s/abyss"\n' "$home_dir" ;;
    *) printf '%s\n' "$line" ;;
    esac
done <"$src/app/abyss.desktop" >"$entry"

echo "Abyss app installed: run \`abyss\` (make sure ~/.local/bin is in your PATH)."
