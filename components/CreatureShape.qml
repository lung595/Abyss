import QtQuick

// One peer's silhouette, drawn as glowing line art. The creature says what
// the device is: manta = server, lantern whale = VPS, fish = laptop,
// nautilus = desktop, seahorse = phone, squid = Raspberry Pi, turtle = NAS.
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
        const n = _step / 4, col = color;
        const stroke = Qt.rgba(col.r, col.g, col.b, asleep ? 0.35 : 0.6 + 0.4 * n);
        const fill = Qt.rgba(col.r, col.g, col.b, asleep ? 0.06 : 0.12 + 0.22 * n);
        c.lineWidth = 1.7;
        c.lineJoin = "round";
        c.strokeStyle = stroke;
        c.fillStyle = fill;
        const both = () => {
            c.fill();
            c.stroke();
        };
        switch (kind) {
        case "server": // manta ray
            c.beginPath();
            c.moveTo(0, -12);
            c.quadraticCurveTo(16, -8, 34, 5);
            c.quadraticCurveTo(14, 6, 4, 14);
            c.lineTo(0, 30);
            c.lineTo(-4, 14);
            c.quadraticCurveTo(-14, 6, -34, 5);
            c.quadraticCurveTo(-16, -8, 0, -12);
            both();
            c.beginPath();
            c.moveTo(-5, -10);
            c.lineTo(-7, -17);
            c.moveTo(5, -10);
            c.lineTo(7, -17);
            c.stroke();
            break;
        case "vps": // lantern whale
            c.beginPath();
            c.moveTo(-30, 0);
            c.quadraticCurveTo(-26, -15, 0, -14);
            c.quadraticCurveTo(24, -12, 30, 0);
            c.quadraticCurveTo(24, 12, 0, 12);
            c.quadraticCurveTo(-24, 12, -30, 0);
            both();
            c.beginPath();
            c.moveTo(-30, 0);
            c.lineTo(-40, -9);
            c.lineTo(-38, 0);
            c.lineTo(-40, 9);
            c.closePath();
            both();
            c.beginPath();
            c.moveTo(20, -12);
            c.quadraticCurveTo(30, -26, 37, -19);
            c.stroke();
            c.fillStyle = Qt.rgba(col.r, col.g, col.b, asleep ? 0.3 : 0.95);
            c.beginPath();
            c.arc(37, -19, 3, 0, Math.PI * 2);
            c.fill();
            break;
        case "laptop": // fish
            c.beginPath();
            c.ellipse(-18, -9, 36, 18);
            both();
            c.beginPath();
            c.moveTo(-16, 0);
            c.lineTo(-28, -9);
            c.lineTo(-28, 9);
            c.closePath();
            both();
            c.beginPath();
            c.moveTo(-2, -8);
            c.quadraticCurveTo(4, -16, 10, -8);
            c.stroke();
            c.fillStyle = stroke;
            c.beginPath();
            c.arc(9, -2, 1.8, 0, Math.PI * 2);
            c.fill();
            break;
        case "phone": // seahorse
            c.beginPath();
            c.moveTo(4, -18);
            c.quadraticCurveTo(12, -14, 8, -8);
            c.quadraticCurveTo(0, 0, 6, 8);
            c.quadraticCurveTo(10, 16, 2, 20);
            c.quadraticCurveTo(-6, 22, -4, 14);
            c.lineWidth = 2.4;
            c.stroke();
            c.lineWidth = 1.7;
            c.beginPath();
            c.ellipse(-2, -20, 10, 8);
            both();
            c.beginPath();
            c.moveTo(7, -17);
            c.lineTo(15, -19);
            c.stroke();
            break;
        case "pi": // little squid
            c.beginPath();
            c.moveTo(0, -20);
            c.quadraticCurveTo(10, -8, 7, 4);
            c.lineTo(-7, 4);
            c.quadraticCurveTo(-10, -8, 0, -20);
            both();
            for (let k = -3; k <= 3; k++) {
                c.beginPath();
                c.moveTo(k * 2, 4);
                c.quadraticCurveTo(k * 3, 12, k * 2.5, 20 + Math.abs(k));
                c.stroke();
            }
            break;
        case "nas": // turtle
            c.beginPath();
            c.ellipse(-20, -14, 40, 28);
            both();
            c.beginPath();
            [[0, 0], [-10, -5], [10, -5], [-10, 5], [10, 5]].forEach(h => {
                for (let k = 0; k <= 6; k++) {
                    const a = k / 6 * Math.PI * 2, px = h[0] + Math.cos(a) * 4.5, py = h[1] + Math.sin(a) * 4.5;
                    k ? c.lineTo(px, py) : c.moveTo(px, py);
                }
            });
            c.stroke();
            c.beginPath();
            c.ellipse(18, -4.5, 12, 9);
            both();
            [[12, -15], [12, 9], [-19, -15], [-19, 9]].forEach(p => {
                c.beginPath();
                c.ellipse(p[0] - 3, p[1], 10, 6);
                both();
            });
            break;
        default: // nautilus (desktop)
            c.beginPath();
            c.arc(0, 0, 16, 0, Math.PI * 2);
            both();
            c.beginPath();
            for (let a = 0; a < 11; a += 0.2) {
                const r = 1.3 * Math.exp(a * 0.22), px = Math.cos(a) * r, py = Math.sin(a) * r;
                a ? c.lineTo(px, py) : c.moveTo(px, py);
            }
            c.stroke();
            for (let k = 0; k < 5; k++) {
                c.beginPath();
                c.moveTo(14, 4 + k * 2);
                c.quadraticCurveTo(24, 6 + k * 3, 28, 10 + k * 3);
                c.stroke();
            }
        }
    }
}
