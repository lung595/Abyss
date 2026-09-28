import QtQuick
import "Shapes.js" as Shapes

// One peer's silhouette, drawn as glowing line art. The creature says what
// the device is: manta = server, lantern whale = VPS, fish = laptop,
// nautilus = desktop, seahorse = phone, squid = Raspberry Pi, turtle = NAS.
// The paths live in Shapes.js, so the tentacle that holds a creature can walk
// the very same outline (Grips.js).
// Painted only when its look changes.
Canvas {
    id: shape

    property string kind: "desktop"
    property color color: "white"
    // 0..1: how bright (traffic)
    property real glow: 0.5
    property bool asleep: false

    width: 96
    height: 96
    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onAsleepChanged: requestPaint()
    // Brightness steps, not every tiny change
    readonly property int _step: Math.round(glow * 4)
    on_StepChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.translate(48, 48);
        Shapes.draw(c, kind, color, _step / 4, asleep);
    }
}
