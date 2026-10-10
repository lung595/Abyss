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
    readonly property real _top: 64
    readonly property real _readoutsRoom: 280
    // Targets hug the left edge, the ticks the right one, so they never touch
    readonly property int _targetX: compact ? 0 : 4
    readonly property int _majorTick: compact ? 10 : 16
    readonly property int _minorTick: compact ? 5 : 8
    readonly property int _tickGap: 4
    // The 0 m and 200 m centres are never closer than one target, so both stay
    // fully tappable at 900 x 600 where the true scale puts them 16 px apart
    readonly property int _minGap: 44
    readonly property real _span: Math.max(1, height - _readoutsRoom)
    readonly property int _depth: (Stations.byId(current) ?? Stations.STATIONS[0]).depth
    readonly property var _readouts: Stations.readouts(_depth)
    readonly property var _signal: Stations.signal(netbirdState)

    signal chosen(string stationId)

    function centerY(depth: real): real {
        const natural = _top + Stations.fraction(depth) * _span;
        const first = _top + Stations.fraction(Stations.STATIONS[0].depth) * _span;
        return depth > Stations.STATIONS[0].depth ? Math.max(natural, first + _minGap) : natural;
    }

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

    // Scale: a minor tick every 4 px of the span, a longer one every 1 000 m
    Repeater {
        model: Math.floor(gauge._span / 4) + 1

        Rectangle {
            required property int index
            x: gauge.width - 1 - width
            y: gauge._top + index * 4
            width: gauge._minorTick
            height: 1
            color: Theme.outline
        }
    }

    Repeater {
        model: 5

        Rectangle {
            required property int index
            x: gauge.width - 1 - width
            y: gauge._top + Stations.fraction(index * 1000) * gauge._span
            width: gauge._majorTick
            height: 1
            color: Theme.outline
        }
    }

    Repeater {
        model: [1000, 2000, 3000]

        Text {
            required property int modelData
            // Right-aligned just above its long tick, clear of the targets
            x: gauge.width - 1 - gauge._tickGap - width
            y: gauge._top + Stations.fraction(modelData) * gauge._span - height
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
            y: gauge.centerY(modelData.depth) - height / 2
            z: current ? 2 : 0
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
        y: gauge.centerY(gauge._depth) - height / 2
        z: 3
        width: 24
        height: 24
        source: "assets/darwin/body.png"
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(24, 24)
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
                required property int index
                required property string modelData
                anchors.right: parent.right
                text: modelData
                // The depth leads, pressure and temperature support it
                color: index === 0 ? Theme.surfaceText : Theme.onSurfaceVariant
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
