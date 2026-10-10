import QtQuick
import "."
import "SendTransfer.js" as Transfer

// One row of the queue or of the history: name, device, the track (a real
// percentage with rsync, a moving segment with scp: never a guessed one) and
// the one action that fits the state.
Item {
    id: row

    required property var job
    property string rate: ""
    // Drives the indeterminate segment; the view stops it with the window
    property bool animate: false

    signal action(string kind)

    readonly property bool live: job.state === "queued" || job.state === "sending"
    readonly property string actionLabel: live ? "Cancel" : job.state === "done" ? "Dismiss" : "Retry"

    height: 56

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
    }

    Rectangle {
        x: 2
        y: 10
        width: 12
        height: 16
        radius: 6
        color: row.live ? Theme.primary : Theme.outline
    }

    Text {
        x: 28
        y: 8
        width: Math.max(0, track.x - 48)
        text: Transfer.middle(Transfer.baseName(row.job.path), 18, 10)
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Text {
        x: 28
        y: 32
        text: "→ " + Transfer.middle(row.job.device, 10, 8)
        color: Theme.onSurfaceVariant
        font.family: Theme.monoFontFamily
        font.pixelSize: 12
    }

    Rectangle {
        id: track

        x: parent.width - 100 - 12 - 120 - 130
        y: 24
        width: 120
        height: 8
        radius: 4
        color: Theme.surfaceContainerHighest
        visible: row.job.state === "sending" || row.job.state === "done"
        clip: true

        Rectangle {
            id: fill

            readonly property bool known: row.job.progress !== null
            width: known ? parent.width * row.job.progress : 36
            x: known ? 0 : seg
            height: parent.height
            radius: 4
            color: Theme.primary

            property real seg: 0
        }

        // Indeterminate: a Timer at 30 Hz moves the segment (no QML animation
        // runs, so the shell is not redrawn), and only while it is shown
        Timer {
            interval: 33
            repeat: true
            running: row.animate && row.job.state === "sending" && !fill.known && !Theme.reduceMotion
            onTriggered: fill.seg = (fill.seg + 3) % (track.width - 36)
        }
    }

    Text {
        x: track.x + 130
        y: 16
        width: 100
        text: row.job.state === "sending" ? (row.job.progress === null ? "Sending · scp, no progress" : Math.round(row.job.progress * 100) + " %  " + row.rate) : row.job.state === "failed" ? "Failed" : row.job.state === "cancelled" ? "Cancelled" : row.job.state === "done" ? "Done" : "Waiting"
        color: Theme.onSurfaceVariant
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeMedium
        elide: Text.ElideRight
    }

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            topMargin: 6
        }
        width: 100
        height: 44
        radius: Theme.cornerRadius
        color: "transparent"
        border.width: 1
        border.color: Theme.outlineStrong
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: row.actionLabel

        Text {
            anchors.centerIn: parent
            text: row.actionLabel
            color: Theme.primary
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        TapHandler {
            onTapped: row.action(row.actionLabel.toLowerCase())
        }
    }
}
