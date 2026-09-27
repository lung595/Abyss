import QtQuick
import qs.Widgets
import "Mesh.js" as Mesh

// Who is online and the live totals, scratched into the fishbowl's glass
// in front of the sand. The bowl has no bar over the water: the jellyfish
// connects on click, and its right-click menu holds the rest.
// Scratched look: a faint cut whose lower lip catches the light (a pale
// copy one pixel off, Text.Sunken), slightly askew as if cut by hand. Painted text only, nothing runs.
StyledText {
    id: cut

    // Bowl.build() for this size, in the parent's coordinates
    property var b
    property var scene
    readonly property var v: scene.view

    x: b.cx - width / 2
    y: (b.gravelY + b.baseY) / 2 - height / 2
    rotation: -1.5
    text: v.state === "connected" ? v.online + "/" + v.total + " online  ·  ↓ " + Mesh.fmtRate(v.down) + "  ↑ " + Mesh.fmtRate(v.up) : ({
            "connecting": "connecting…",
            "needsLogin": "sign-in needed",
            "stopped": "NetBird is off"
        })[v.state] || "disconnected"
    wrapMode: Text.NoWrap
    font.pixelSize: 12
    font.weight: Font.Light
    font.letterSpacing: 1.2
    color: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.26)
    style: Text.Sunken
    styleColor: Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.16)
    // Fades with the glass while a card is open
    opacity: 1 - 0.8 * scene.cardMix
}
