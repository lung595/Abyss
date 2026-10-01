import QtQuick
import "QrCode.js" as Qr

// A QR code on a white rounded tile (phones read dark on light best), with
// the quiet margin scanners need. Drawn once per text and size.
Rectangle {
    id: qr

    property string text: ""
    readonly property var cells: text ? Qr.matrix(text) : []

    radius: Math.max(6, width * 0.06)
    color: "white"

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: qr.width * 0.07
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const ctx = getContext("2d"), n = qr.cells.length;
            ctx.reset();
            if (!n)
                return;
            const s = Math.min(width, height) / n;
            ctx.fillStyle = "#111018";
            for (let r = 0; r < n; r++)
                for (let c = 0; c < n; c++)
                    if (qr.cells[r][c])
                        // A hair wider, so no seam shows between modules
                        ctx.fillRect(c * s, r * s, s + 0.5, s + 0.5);
        }
        onWidthChanged: requestPaint()
        Connections {
            target: qr
            function onCellsChanged() {
                canvas.requestPaint();
            }
        }
    }
}
