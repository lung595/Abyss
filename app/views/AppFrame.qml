pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../components/Stations.js" as Stations

// The window's content: depth gauge on the left, then a 24 px padded column
// with a 40 px title row and the current station's view. Switching stations
// is the dive (a brief translate, nothing else moves). Kept free of any
// window type so it can be tested and captured offscreen.
Item {
    id: frame

    property string station: "map"
    // A peer the command line asked for; "" when none
    property string device: ""
    // The peers once read; null while unknown, so nothing is called unknown yet
    property var peers: null
    property string netbirdState: "unknown"
    // 900 x 600 and below: gauge 56, padding 24, title row 40 (else 72 / 32 / 44)
    readonly property bool compact: width < 1100
    readonly property int pad: compact ? 24 : 32
    readonly property int titleHeight: compact ? 40 : 44
    readonly property alias gaugeWidth: gauge.width
    readonly property alias signalWidth: gauge.signalWidth
    // The dive, for tests: running, its length and the view's offset
    readonly property alias diving: slide.running
    readonly property alias diveDuration: slide.duration
    readonly property alias diveShift: shift.y
    readonly property var current: Stations.byId(station)
    readonly property bool deviceUnknown: device !== "" && Array.isArray(peers) && Stations.findPeer(peers, device) === null

    // Lands a parsed command line (Cli.parse) on its station
    function go(target) {
        const l = Stations.landing(target);
        device = l.device;
        show(l.station);
    }

    function show(id) {
        if (id === station || Stations.byId(id) === null)
            return;
        _diveDir = Stations.indexOf(id) > Stations.indexOf(station) ? 1 : -1;
        _diveMs = Stations.transitionMs(station, id, Theme.reduceMotion);
        station = id;
        if (_diveMs > 0)
            slide.restart();
    }

    property int _diveDir: 1
    property int _diveMs: 0

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    DepthGauge {
        id: gauge

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        compact: frame.compact
        current: frame.station
        netbirdState: frame.netbirdState
        onChosen: id => frame.show(id)
    }

    Item {
        id: body

        anchors {
            left: gauge.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: frame.pad
        }
        clip: true

        Row {
            id: titleRow

            height: frame.titleHeight
            spacing: Theme.spacingS

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: frame.current.title
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.DemiBold
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u00B7 " + Stations.depthLabel(frame.current.depth)
                color: Theme.onSurfaceVariant
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeMedium
            }
        }

        GuideBand {
            id: guide

            visible: frame.deviceUnknown
            anchors {
                left: parent.left
                right: parent.right
                top: titleRow.bottom
            }
            message: "No device called “" + Stations.shortName(frame.device) + "” on your network."
            anchor: "a-device-is-not-found"
        }

        Item {
            id: viewHolder

            anchors {
                left: parent.left
                right: parent.right
                top: guide.visible ? guide.bottom : titleRow.bottom
                topMargin: guide.visible ? Theme.spacingM : 0
                bottom: parent.bottom
            }

            // The dive: the new view slides in a few pixels, transform only
            transform: Translate {
                id: shift
            }

            NumberAnimation {
                id: slide

                target: shift
                property: "y"
                from: 24 * frame._diveDir
                to: 0
                duration: frame._diveMs
                easing.type: Easing.OutCubic
            }

            // One placeholder until the views of the other stories exist
            PlaceholderView {
                anchors.fill: parent
                title: frame.current.title
                note: Array.isArray(frame.peers) && frame.station === "map" && frame.device !== "" && !frame.deviceUnknown ? "Map · " + frame.device : ""
            }
        }
    }
}
