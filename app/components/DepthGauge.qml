pragma ComponentBehavior: Bound

import QtQuick
import "."
import "Stations.js" as Stations

// The 72 px depth gauge: scale, labels, the three station targets, the
// instrument readouts and Darwin beside the current target. Static: nothing
// here moves or polls, the readouts change with the station.
Rectangle {
    id: gauge

    required property string current
    // "connected" | "stopped" | "missing" | "unknown"
    property string netbirdState: "unknown"

    // Compact window (900 x 600): the gauge narrows to 56 px
    property bool compact: false

    // Room above the 0 m target, and below the deepest one for the readouts
    readonly property real _top: 63
    readonly property real _readoutsRoom: 280
    readonly property int _targetX: (width - 44) / 2
    readonly property real _span: Math.max(1, height - _readoutsRoom)
    readonly property int _depth: (Stations.byId(current) ?? Stations.STATIONS[0]).depth
    readonly property var _readouts: Stations.readouts(_depth)
    readonly property var _signal: Stations.signal(netbirdState)

    signal chosen(string stationId)

    width: compact ? 56 : 72
    color: Theme.surfaceContainerLow

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 1
        color: Theme.outline
    }

    // Scale: a tick every 100 m, a longer one with a label every 1 000 m
    Repeater {
        model: 41

        Rectangle {
            required property int index
            readonly property bool major: index % 10 === 0
            x: gauge.width - 16 - (major ? 16 : 8)
            y: gauge._top + Stations.fraction(index * 100) * gauge._span
            width: major ? 16 : 8
            height: 1
            color: Theme.outline
        }
    }

    Repeater {
        model: [1000, 2000, 3000]

        Text {
            required property int modelData
            x: 8
            y: gauge._top + Stations.fraction(modelData) * gauge._span - height / 2
            text: modelData / 1000 + "k"
            color: Theme.onSurfaceVariant
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    Repeater {
        model: Stations.STATIONS

        StationTarget {
            required property var modelData
            x: gauge._targetX
            y: gauge._top + Stations.fraction(modelData.depth) * gauge._span - height / 2
            stationId: modelData.id
            mark: modelData.mark
            label: modelData.title + " " + modelData.depth + " m"
            current: gauge.current === modelData.id
            onActivated: id => gauge.chosen(id)
        }
    }

    // Darwin beside the current target; he hangs half over the content padding
    Image {
        x: gauge.width - 12
        y: gauge._top + Stations.fraction(gauge._depth) * gauge._span - height / 2
        z: 1
        width: 24
        height: 24
        source: "assets/darwin/body.png"
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    // Instrument readouts
    Column {
        anchors {
            bottom: parent.bottom
            bottomMargin: 40
            right: parent.right
            rightMargin: 8
        }
        spacing: Theme.spacingXS

        Repeater {
            model: [gauge._readouts.depth, gauge._readouts.pressure, gauge._readouts.temperature]

            Text {
                required property string modelData
                anchors.right: parent.right
                text: modelData
                color: Theme.onSurfaceVariant
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Text {
            anchors.right: parent.right
            // The word does not fit 56 px: the glyph alone says it, as it does by shape
            text: gauge.compact ? gauge._signal.glyph : gauge._signal.glyph + " " + gauge._signal.label
            color: Theme[gauge._signal.role]
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
