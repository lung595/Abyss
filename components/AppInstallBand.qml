import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

// Inline band that offers to install the Abyss app (spec: design.md 8.4 bis.1).
// The float on the gauge is the progress: it only moves when a real step ends.
// Nothing here runs at rest: no timer, and animations are one-shot.
Rectangle {
    id: band

    required property var installer
    // send | expand | settings: the action that was asked and is waiting
    property string action: "send"
    property string deviceName: ""
    property bool reduceMotion: false

    // The user guide section the GitHub mark opens, on click only
    readonly property string guideUrl: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#"

    // not now / don't ask again / done: the caller falls back or proceeds
    signal dismissed(bool dontAskAgain)
    signal proceed(string action)
    // The 100 ms exit fade is over: the caller may unload the band
    signal faded
    // The caller sets this to false when the action ends; the band fades out
    property bool open: true

    readonly property string phase: installer.phase
    readonly property bool busy: phase === "checking" || phase === "installing"
    readonly property var _invite: ({
            "send": ["Send files with the Abyss app", "Not now opens the file picker, as before."],
            "expand": ["See the whole sea in the Abyss app", "Not now keeps the map in this popout."],
            "settings": ["All settings live in the Abyss app", "Not now opens the widget settings."]
        })
    readonly property var _steps: ["Check Quickshell", "Set up the app", "Add the abyss command"]

    // 0 asked, 1..3 steps; installed = 3, failed keeps the step that failed
    readonly property int position: phase === "idle" ? 0 : (phase === "installed" ? 3 : Math.max(1, installer.step))
    readonly property string title: phase === "idle" ? _invite[action][0] : (phase === "installed" ? "Abyss app installed" : (phase === "failed" ? "The app was not installed" : (phase === "missing" ? "Quickshell is missing" : "Installing the Abyss app")))
    readonly property bool showSteps: phase !== "idle" && phase !== "missing"

    // With no known command there is nothing to run: point to the guide
    readonly property string _missingText: {
        const h = installer.help;
        const seen = h.name ? "Detected: " + h.name + ". " : "";
        return h.command ? seen + "Run this in a terminal, then check again. Abyss never runs it for you." : seen + "Quickshell has no single command here. Open the guide with the GitHub mark, then check again. Abyss never installs it for you.";
    }

    // Names longer than 15 characters are cut in the middle
    function shortName(name) {
        return name.length > 15 ? name.slice(0, 7) + "…" + name.slice(-7) : name;
    }
    readonly property string doneLabel: action === "send" ? "Send a file to " + shortName(deviceName) : (action === "expand" ? "Open the map" : "Open Abyss settings")

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.margins: 16
    implicitHeight: column.implicitHeight + 32
    height: implicitHeight
    radius: 16
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Theme.outline
    focus: true
    Keys.onEscapePressed: band.dismissed(false)
    Keys.onReturnPressed: band.activate()
    Keys.onEnterPressed: band.activate()
    // The primary button, also on Enter
    function activate() {
        if (busy)
            return;
        if (phase === "installed")
            proceed(action);
        else
            installer.install();
    }
    Accessible.role: Accessible.Dialog
    Accessible.name: "Abyss app"
    Accessible.description: band.busy ? band._steps[Math.max(1, band.position) - 1] : band.title

    // Enter once, 200 ms; the exit is a 100 ms fade driven by the caller
    opacity: 0
    transform: Translate {
        id: lift
        y: 16
    }
    onOpenChanged: {
        if (open) {
            // Asked again during the fade: stay
            leave.stop();
            opacity = 1;
            return;
        }
        if (reduceMotion)
            faded();
        else
            leave.start();
    }
    NumberAnimation {
        id: leave
        target: band
        property: "opacity"
        to: 0
        duration: 100
        easing.type: Easing.OutCubic
        onFinished: band.faded()
    }
    Component.onCompleted: {
        if (reduceMotion) {
            opacity = 1;
            lift.y = 0;
        } else {
            enter.start();
        }
    }
    ParallelAnimation {
        id: enter
        NumberAnimation {
            target: band
            property: "opacity"
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: lift
            property: "y"
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Column {
        id: column
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12

        Row {
            width: parent.width
            // The gauge starts under the title block, which may take two lines
            height: Math.max(gauge.y + gauge.height, textColumn.height)
            spacing: 12

            // Gauge: wire, three graduations, float, ping ring
            Item {
                id: gauge
                y: titleText.height - 24
                width: 16
                height: 96
                Rectangle {
                    x: 7
                    y: 12
                    width: 1
                    height: 72
                    color: Theme.outline
                }
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        x: 4
                        y: 36 + index * 24
                        width: 8
                        height: 1
                        color: Theme.outline
                    }
                }
                Rectangle {
                    id: floater
                    x: 4
                    y: 4 + 24 * band.position
                    width: 8
                    height: 16
                    radius: 4
                    readonly property bool hollow: band.phase === "missing"
                    color: hollow ? Theme.surfaceContainerHigh : (band.phase === "failed" ? Theme.error : Theme.primary)
                    border.width: hollow ? 2 : 0
                    border.color: Theme.surfaceVariantText
                    Behavior on y {
                        NumberAnimation {
                            duration: band.reduceMotion ? 0 : 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    onYChanged: if (!band.reduceMotion && band.busy)
                        ping.restart()
                }
                Rectangle {
                    id: ring
                    width: 16
                    height: 16
                    radius: 8
                    x: 0
                    y: floater.y + floater.height / 2 - 8
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.primary
                    opacity: 0
                }
                ParallelAnimation {
                    id: ping
                    NumberAnimation {
                        target: ring
                        property: "opacity"
                        from: 0.6
                        to: 0
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: ring
                        property: "scale"
                        from: 1
                        to: 2.5
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Column {
                id: textColumn
                width: parent.width - 28
                spacing: 0
                StyledText {
                    id: titleText
                    width: parent.width
                    lineHeight: 24
                    lineHeightMode: Text.FixedHeight
                    text: band.title
                    wrapMode: Text.WordWrap
                    // The longest invite title wraps at the narrow popout instead of being cut
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }
                StyledText {
                    visible: band.phase === "idle" || band.phase === "missing"
                    width: parent.width
                    text: band.phase === "missing" ? band._missingText : "Not installed yet. It goes in your home folder: no password, nothing downloaded."
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
                Repeater {
                    model: band.showSteps ? band._steps : []
                    Row {
                        required property int index
                        required property string modelData
                        readonly property bool done: band.phase === "installed" || index + 1 < band.position
                        readonly property bool current: index + 1 === band.position && band.phase !== "installed"
                        readonly property bool failed: current && band.phase === "failed"
                        height: 24
                        spacing: 8
                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: parent.failed ? "close" : "check"
                            size: 16
                            color: parent.failed ? Theme.error : Theme.primary
                            visible: parent.done || parent.failed
                            opacity: visible ? 1 : 0
                        }
                        Item {
                            width: 16
                            height: 16
                            visible: !(parent.done || parent.failed)
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: parent.current ? Font.DemiBold : Font.Normal
                            color: parent.done || parent.current ? Theme.surfaceText : Theme.surfaceVariantText
                        }
                    }
                }
                StyledText {
                    topPadding: 4
                    width: parent.width
                    text: band.phase === "idle" ? band._invite[band.action][1] : (band.phase === "failed" ? band.installer.reason + " Nothing was changed." : "")
                    visible: text !== ""
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }

        // Quickshell missing: the command is shown and copied, never run
        Rectangle {
            visible: band.phase === "missing" && band.installer.help.command
            width: parent.width
            height: Math.max(48, cmdRow.implicitHeight + 4)
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: Theme.outline
            // Full command width, to decide between a labelled and an icon-only Copy
            TextMetrics {
                id: cmdMetrics
                text: band.installer.help.command || ""
                font.family: "monospace"
                font.pixelSize: Theme.fontSizeSmall
            }
            Flow {
                id: cmdRow
                x: 12
                y: 2
                width: parent.width - 24
                spacing: 8
                StyledText {
                    width: Math.max(0, parent.width - copy.width - 8)
                    height: 44
                    verticalAlignment: Text.AlignVCenter
                    text: band.installer.help.command || ""
                    // Break at spaces only: a command is never cut inside a word
                    wrapMode: Text.WordWrap
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                }
                BandButton {
                    id: copy
                    kind: "flat"
                    iconName: "content_copy"
                    // Icon only when the command and a labelled button share no line
                    readonly property bool compact: cmdMetrics.width + 24 + 8 + 96 > cmdRow.parent.width
                    label: compact ? "" : (copied ? "Copied" : "Copy")
                    tip: compact ? (copied ? "Copied" : "Copy") : ""
                    reduceMotion: band.reduceMotion
                    property bool copied: false
                    onClicked: {
                        Quickshell.clipboardText = band.installer.help.command;
                        copied = true;
                    }
                }
            }
        }

        // Actions: primary and secondary on the left; "Don't ask again" and the
        // GitHub mark on the right of the same row when they fit, else beneath
        Item {
            id: actions
            width: parent.width
            readonly property bool fits: left.natural + 8 + right.implicitWidth <= width
            height: fits ? left.height : left.height + (right.implicitWidth > 0 ? 8 + right.height : 0)

            Flow {
                id: left
                // An unsized Flow reports one column, so the row width is summed here
                readonly property real natural: {
                    let w = 0, n = 0;
                    for (const c of children) {
                        if (c.visible) {
                            w += c.implicitWidth;
                            n++;
                        }
                    }
                    return w + 8 * Math.max(0, n - 1);
                }
                width: actions.fits ? natural : parent.width
                spacing: 8

                BandButton {
                    kind: "primary"
                    visible: band.phase === "idle" || band.busy || band.phase === "failed" || band.phase === "missing" || band.phase === "installed"
                    enabled: !band.busy
                    reduceMotion: band.reduceMotion
                    label: band.phase === "idle" ? "Install the Abyss app" : (band.busy ? "Installing…" : (band.phase === "failed" ? "Try again" : (band.phase === "missing" ? "Check again" : band.doneLabel)))
                    // The full name, as the label may be shortened
                    tip: band.phase === "installed" && band.action === "send" ? "Send a file to " + band.deviceName : ""
                    onClicked: band.activate()
                }
                BandButton {
                    kind: "secondary"
                    visible: !band.busy
                    reduceMotion: band.reduceMotion
                    label: band.phase === "installed" ? "Close" : "Not now"
                    onClicked: band.dismissed(false)
                }
            }
            Row {
                id: right
                spacing: 8
                x: actions.width - width
                y: actions.fits ? 0 : left.height + 8

                BandButton {
                    kind: "quiet"
                    visible: band.phase === "idle"
                    reduceMotion: band.reduceMotion
                    label: "Don't ask again"
                    onClicked: band.dismissed(true)
                }
                BandButton {
                    kind: "mark"
                    visible: band.phase === "failed" || band.phase === "missing"
                    reduceMotion: band.reduceMotion
                    tip: "Open the guide: docs/GUIDE.md#install-the-app"
                    Accessible.name: "Open the guide on GitHub"
                    onClicked: Qt.openUrlExternally(band.guideUrl + (band.phase === "missing" ? "quickshell-is-missing" : "install-the-app"))
                }
            }
        }
    }
}
