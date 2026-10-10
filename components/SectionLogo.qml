import QtQuick
import QtQuick.Shapes
import qs.Common

// The logo of a settings section, drawn as vector paths and tinted by Theme.
// One path set per size so horizontals and verticals sit on the pixel grid:
// 24 px = 2 px stroke on whole coordinates, 20 px = 1.5 px stroke on quarter
// coordinates. "f" is the closed shape that fills when the section is open.
// Kept in one file so the app can reuse it.
Item {
    id: root

    // A section id from Sections.js
    required property string name
    property real size: 20
    property bool open: false

    readonly property bool big: size >= 24
    readonly property var paths: logos[name] ?? logos.help

    width: size
    height: size

    Shape {
        width: root.size
        height: root.size
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.open ? Qt.alpha(Theme.primary, 0.5) : "transparent"
            PathSvg {
                path: root.big ? root.paths.f24 : root.paths.f20
            }
        }
        ShapePath {
            strokeWidth: root.big ? 2 : 1.5
            strokeColor: root.open ? Theme.primary : Theme.surfaceVariantText
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: root.big ? root.paths.s24 : root.paths.s20
            }
        }
    }

    readonly property var logos: ({
            "connect": {
                "s24": "M2 15 H22 M3 15 a4 4 0 0 1 8 0 M7 11 V5 M13 15 a3 3 0 0 1 6 0 M5 19 H19",
                "f24": "M3 15 a4 4 0 0 1 8 0 Z M13 15 a3 3 0 0 1 6 0 Z",
                "s20": "M1.25 12.25 H18.75 M2.25 12.25 a3.5 3.5 0 0 1 7 0 M5.75 8.75 V4.25 M11.25 12.25 a2.5 2.5 0 0 1 5 0 M4.25 16.25 H15.75",
                "f20": "M2.25 12.25 a3.5 3.5 0 0 1 7 0 Z M11.25 12.25 a2.5 2.5 0 0 1 5 0 Z"
            },
            "appearance": {
                "s24": "M5 12 A7 7 0 0 1 19 12 Z M8 15 v4 M12 15 v6 M16 15 v4",
                "f24": "M5 12 A7 7 0 0 1 19 12 Z",
                "s20": "M4.25 10.25 A6 6 0 0 1 16.25 10.25 Z M7.25 12.75 v3 M10.25 12.75 v4.5 M13.25 12.75 v3",
                "f20": "M4.25 10.25 A6 6 0 0 1 16.25 10.25 Z"
            },
            "effects": {
                "s24": "M2 20 C3 15 9 15 11 20 M7 16 C7 9 10 5 14 5 C16 5 17 7 17 9 M14 12 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0",
                "f24": "M14 12 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0",
                "s20": "M1.75 16.75 C3 12.5 8 12.5 9.25 16.75 M5.75 13.5 C5.75 7.5 8.5 4.25 11.75 4.25 C13.5 4.25 14.25 5.75 14.25 7.25 M11.75 9.75 a2.5 2.5 0 1 0 5 0 a2.5 2.5 0 1 0 -5 0",
                "f20": "M11.75 9.75 a2.5 2.5 0 1 0 5 0 a2.5 2.5 0 1 0 -5 0"
            },
            "bar": {
                "s24": "M3 4 H21 V8 H3 Z M12 8 V11 M8 15 a4 4 0 0 1 8 0 Z M10 15 V20 M14 15 V20",
                "f24": "M3 4 H21 V8 H3 Z M8 15 a4 4 0 0 1 8 0 Z",
                "s20": "M2.25 3.25 H17.75 V6.75 H2.25 Z M10.25 6.75 V9.25 M6.75 12.75 a3.5 3.5 0 0 1 7 0 Z M8.75 12.75 V16.75 M11.75 12.75 V16.75",
                "f20": "M2.25 3.25 H17.75 V6.75 H2.25 Z M6.75 12.75 a3.5 3.5 0 0 1 7 0 Z"
            },
            "desktop": {
                "s24": "M8 4 h8 M8 4 C2 8 3 20 9 20 h6 C21 20 22 8 16 4 M5 11 q1.75 -2 3.5 0 t3.5 0 t3.5 0 t3.5 0",
                "f24": "M5 11 q1.75 -2 3.5 0 t3.5 0 t3.5 0 t3.5 0 C19 16 18 20 15 20 h-6 C6 20 5 16 5 11 Z",
                "s20": "M6.75 3.25 h6.5 M6.75 3.25 C1.75 6.5 2.5 16.75 7.5 16.75 h5 C17.5 16.75 18.25 6.5 13.25 3.25 M4 9.25 q1.5 -1.5 3 0 t3 0 t3 0 t3 0",
                "f20": "M4 9.25 q1.5 -1.5 3 0 t3 0 t3 0 t3 0 C16 13.5 15 16.75 12.5 16.75 h-5 C5 16.75 4 13.5 4 9.25 Z"
            },
            "alerts": {
                "s24": "M12 3 v2 M6 16 V11 a6 6 0 0 1 12 0 V16 Z M10 11 a2 2 0 1 0 4 0 a2 2 0 1 0 -4 0 M7 20 q2.5 2 5 0 t5 0",
                "f24": "M6 16 V11 a6 6 0 0 1 12 0 V16 Z",
                "s20": "M10.25 2.25 v2 M5.25 13.25 V9.25 a5 5 0 0 1 10 0 V13.25 Z M8.75 9.25 a1.5 1.5 0 1 0 3 0 a1.5 1.5 0 1 0 -3 0 M5.75 16.5 q2.25 1.5 4.5 0 t4.5 0",
                "f20": "M5.25 13.25 V9.25 a5 5 0 0 1 10 0 V13.25 Z"
            },
            "advanced": {
                "s24": "M9 4 h6 M10 4 v6 L5 18 a1.4 1.4 0 0 0 1.2 2 h11.6 a1.4 1.4 0 0 0 1.2 -2 L14 10 V4 M7.5 14 h9",
                "f24": "M7.5 14 h9 L19 18 a1.4 1.4 0 0 1 -1.2 2 H6.2 a1.4 1.4 0 0 1 -1.2 -2 Z",
                "s20": "M7.75 3.25 h5 M8.25 3.25 v5 L4.25 15 a1.2 1.2 0 0 0 1 1.75 h10 a1.2 1.2 0 0 0 1 -1.75 L12.25 8.25 V3.25 M6.25 11.75 h8",
                "f20": "M6.25 11.75 h8 L16.25 15 a1.2 1.2 0 0 1 -1 1.75 H5.25 a1.2 1.2 0 0 1 -1 -1.75 Z"
            },
            "help": {
                "s24": "M4 12 a8 8 0 1 0 16 0 a8 8 0 1 0 -16 0 M9 12 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0 M6.3 6.3 l3.6 3.6 M17.7 6.3 l-3.6 3.6 M6.3 17.7 l3.6 -3.6 M17.7 17.7 l-3.6 -3.6",
                "f24": "M4 12 a8 8 0 1 0 16 0 a8 8 0 1 0 -16 0 M9 12 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0",
                "s20": "M3.25 10 a6.75 6.75 0 1 0 13.5 0 a6.75 6.75 0 1 0 -13.5 0 M7.5 10 a2.5 2.5 0 1 0 5 0 a2.5 2.5 0 1 0 -5 0 M5.25 5.25 l3 3 M14.75 5.25 l-3 3 M5.25 14.75 l3 -3 M14.75 14.75 l-3 -3",
                "f20": "M3.25 10 a6.75 6.75 0 1 0 13.5 0 a6.75 6.75 0 1 0 -13.5 0 M7.5 10 a2.5 2.5 0 1 0 5 0 a2.5 2.5 0 1 0 -5 0"
            }
        })
}
