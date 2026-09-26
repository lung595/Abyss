import QtQuick
import qs.Common

// You: a giant jellyfish just below the surface. Lit when connected, dim when
// not. Its bell breathes slowly while the scene runs (a scale, no repaint).
Item {
    id: jelly

    property var scene
    property real r: 60
    property color tint: Theme.tertiary
    property color tint2: Theme.primary
    // 0 (asleep) .. 1 (connected)
    property real lit: 1

    width: 0
    height: 0

    Halo {
        width: jelly.r * 5
        height: width
        x: -width / 2
        y: -width / 2
        color: jelly.tint
        strength: 0.4
        opacity: 0.15 + 0.85 * jelly.lit
    }

    Canvas {
        id: body
        width: jelly.r * 2.6
        height: jelly.r * 3.2
        x: -width / 2
        y: -jelly.r * 1.1
        scale: jelly.scene && jelly.scene.flowing ? 1 + 0.025 * Math.sin(jelly.scene.t * 1.5) : 1
        transformOrigin: Item.Top
        readonly property int _lit: Math.round(jelly.lit * 5)
        on_LitChanged: requestPaint()
        onWidthChanged: requestPaint()
        Connections {
            target: jelly
            function onTintChanged() {
                body.requestPaint();
            }
        }

        onPaint: {
            const c = getContext("2d");
            c.reset();
            const g = _lit / 5, R = jelly.r, cx = width / 2, cy = R * 1.1;
            const t1 = jelly.tint, t2 = jelly.tint2;
            const a = (col, al) => Qt.rgba(col.r, col.g, col.b, al);
            // Oral arms, then the bell over them
            for (let k = -2; k <= 2; k++) {
                c.beginPath();
                c.moveTo(cx + k * R * 0.16, cy + 6);
                for (let s = 1; s <= 10; s++)
                    c.lineTo(cx + k * R * 0.16 + Math.sin(s * 0.7 + k) * (3 + s * 0.6), cy + 6 + s * R * 0.16);
                c.strokeStyle = a(Qt.lighter(t1, 1.2), 0.15 + 0.35 * g);
                c.lineWidth = 4.5 - Math.abs(k);
                c.stroke();
            }
            c.beginPath();
            c.moveTo(cx - R, cy + 6);
            c.bezierCurveTo(cx - R, cy - R * 1.05, cx + R, cy - R * 1.05, cx + R, cy + 6);
            for (let k = 8; k >= 1; k--) {
                const px = cx - R + k * (2 * R / 8);
                c.quadraticCurveTo(px - R / 8, cy + 18, px - R / 4, cy + 6);
            }
            const bell = c.createRadialGradient(cx - R * 0.25, cy - R * 0.55, 4, cx, cy - R * 0.1, R * 1.15);
            bell.addColorStop(0, a(Qt.lighter(t1, 1.6), 0.3 + 0.45 * g));
            bell.addColorStop(0.6, a(t1, 0.12 + 0.3 * g));
            bell.addColorStop(1, a(t2, 0.05 + 0.15 * g));
            c.fillStyle = bell;
            c.fill();
            c.strokeStyle = a(Qt.lighter(t1, 1.4), 0.3 + 0.55 * g);
            c.lineWidth = 1.5;
            c.stroke();
            // Four gonads, the jellyfish's signature, and a lit rim
            for (let k = 0; k < 4; k++) {
                const ang = k / 4 * Math.PI * 2 + 0.4;
                c.beginPath();
                c.ellipse(cx + Math.cos(ang) * R * 0.27 - R * 0.16, cy - R * 0.36 + Math.sin(ang) * R * 0.12 - R * 0.08, R * 0.32, R * 0.16);
                c.strokeStyle = a(Qt.lighter(t2, 1.3), 0.25 + 0.55 * g);
                c.lineWidth = 2;
                c.stroke();
            }
            for (let k = 0; k <= 16; k++) {
                c.fillStyle = a(Qt.lighter(t1, 1.5), (0.2 + 0.8 * g) * (0.6 + 0.4 * Math.sin(k * 1.7)));
                c.beginPath();
                c.arc(cx - R + k * (2 * R / 16), cy + 10, 1.8, 0, Math.PI * 2);
                c.fill();
            }
        }
    }
}
