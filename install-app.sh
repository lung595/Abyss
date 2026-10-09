#!/bin/sh
# Installs the Abyss app for the current user, under ~/.local only:
#   <data>/abyss/            the app (window, parser, launcher, usage text)
#   ~/.local/bin/abyss       a link to the launcher
#   <data>/applications/abyss.desktop
# `install-app.sh --uninstall` removes exactly these three and nothing else.
# Run it from a checkout; nothing is downloaded, nothing needs root.
set -eu

src=$(cd -- "$(dirname -- "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}
home_dir=$data/abyss
link=$HOME/.local/bin/abyss
entry=$data/applications/abyss.desktop

# True when the command link is Abyss's own
ours() {
    [ -L "$link" ] && [ "$(readlink -- "$link")" = "$home_dir/abyss" ]
}

case "${1-}" in
--uninstall)
    # The link only when it is ours, so a command named abyss from elsewhere stays
    if ours; then
        rm -- "$link"
    fi
    rm -f -- "$entry"
    rm -rf -- "$home_dir"
    # Folders the install may have made, only when nothing else lives in them
    rmdir -- "$data/applications" "$HOME/.local/bin" "$data" 2>/dev/null || true
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

# Only the app's own files: the widget (QML at the repository root) is not part of it
rm -rf -- "$home_dir"
mkdir -p -- "$home_dir/components" "$data/applications" "$HOME/.local/bin"
cp -- "$src/app/shell.qml" "$src/app/usage.txt" "$src/app/abyss" "$home_dir/"
cp -- "$src/app/components/"*.js "$home_dir/components/"
ln -sf -- "$home_dir/abyss" "$link"

# The desktop entry gets the full path: a menu does not always have ~/.local/bin in its PATH
sed "s|^Exec=abyss|Exec=$home_dir/abyss|" "$src/app/abyss.desktop" >"$entry"

echo "Abyss app installed: run \`abyss\` (make sure ~/.local/bin is in your PATH)."
