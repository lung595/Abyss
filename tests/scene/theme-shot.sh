#!/bin/sh
# Renders the Theme strata (sea, sand, container, high, highest, chips) in one
# scheme, offscreen, to compare with the mockups: tests/scene/theme-shot.sh dark out.png
# qml-qt6 has no Quickshell module, so the one env lookup is replaced in a copy.
set -eu
cd "$(dirname "$0")/../.."
scheme=${1:-dark}; out=${2:-theme-$scheme.png}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp app/components/Palette.js app/components/qmldir "$tmp/"
sed -e '/^import Quickshell/d' \
    -e "s/Quickshell.env(\"ABYSS_SCHEME\") ?? \"\"/\"$scheme\"/" \
    -e 's/Quickshell.env("ABYSS_REDUCE_MOTION") ?? ""/""/' app/components/Theme.qml > "$tmp/Theme.qml"
cat > "$tmp/shot.qml" <<QML
import QtQuick
import QtQuick.Window
import "."
Window {
    visible: true; width: 640; height: 420
    Rectangle { id: page; anchors.fill: parent; color: Theme.surface
    Column {
        anchors.centerIn: parent; spacing: Theme.spacingS
        Repeater {
            model: ["surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest"]
            Rectangle {
                required property string modelData
                width: 480; height: 52; radius: Theme.cornerRadiusLarge
                color: Theme[modelData]; border.color: Theme.outlineStrong
                Text { x: Theme.spacingL; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData
                    color: Theme.surfaceText; font.family: Theme.monoFontFamily; font.pixelSize: Theme.fontSizeMedium }
                Rectangle { anchors { right: parent.right; rightMargin: Theme.spacingL; verticalCenter: parent.verticalCenter }
                    width: 40; height: 24; radius: Theme.cornerRadius; color: Theme.primary
                    Text { anchors.centerIn: parent; text: "ok"; color: Theme.primaryText; font.pixelSize: Theme.fontSizeSmall } }
            }
        }
        Text { text: "Abyss"; color: Theme.primary; font.pixelSize: Theme.fontSizeXLarge; font.weight: Font.DemiBold }
    }
    Timer { interval: 300; running: true; onTriggered: page.grabToImage(function (r) { r.saveToFile("$PWD/$out"); Qt.quit() }) }
    }
}
QML
QT_QPA_PLATFORM=offscreen timeout 60 qml-qt6 "$tmp/shot.qml" 2>&1 | grep -v '^$' | head -5
