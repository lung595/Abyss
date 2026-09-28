import QtQuick
import qs.Common
import "Ribbon.js" as Ribbon

// The end of a tentacle that grips a creature: the last fifth of the wrap,
// which crosses the ribbon's own path and closes under the belly. The deep
// draws the rest behind the creature (Tentacles.qml); this canvas draws the
// tail again in front of it, so a held body looks held and not ringed.
// It only paints when the tentacles change, like the other one.
Canvas {
    id: canvas

    property var scene
    // Same array as Tentacles.qml, read for the tail counts only
    property var tents: []
    // 0..1: how far tentacles have grown out of the bell
    property real ext: 1

    onTentsChanged: requestPaint()
    onExtChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        Ribbon.draw(c, tents, ext, { "warn": Theme.warning, "tail": true });
    }
}
