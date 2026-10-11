import QtQuick
import qs.Common
import qs.Widgets
import ".."

// "Abyss app" settings row (design 8.4 bis.2): state text, then the buttons,
// which drop under the text when the room is missing. The version is read once
// when the page opens; nothing runs afterwards.
Rectangle {
    id: row

    required property var installer
    required property var prefs
    property bool reduceMotion: false

    // idle | confirm | removed, on top of the installer's own phase
    property string mode: "idle"
    readonly property string guideUrl: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#"
    readonly property string phase: installer.phase
    readonly property bool busy: phase === "checking" || phase === "installing"
    readonly property string version: installer.installedVersion
    readonly property bool present: installer.appState !== "install"

    readonly property string help: {
        if (busy)
            return "Installing, step " + Math.max(1, installer.step) + " of 3: " + ["checking Quickshell", "setting up the app", "adding the abyss command"][Math.max(1, installer.step) - 1];
        if (phase === "failed")
            return "Not installed: " + installer.reason + " Nothing was changed.";
        if (mode === "confirm")
            return "Remove the app from your home folder? Your settings stay with the widget.";
        if (mode === "removed" && !present)
            return "App removed. Nothing is left behind.";
        if (present)
            return "Installed · v" + version + (installer.appState === "ok" ? ", same as the widget" : ", the widget is newer");
        return "Not installed. Send queue, full map and every setting in one window.";
    }

    width: parent ? parent.width : 0
    height: layout.implicitHeight + 32
    radius: 12
    color: Theme.surfaceContainer

    Component.onCompleted: installer.refresh()
    onPhaseChanged: if (phase === "installed")
        mode = "idle"

    Flow {
        id: layout
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 16

        Column {
            // A base width of 160 lets the buttons wrap under the text
            width: Math.max(160, layout.width - ctl.implicitWidth - layout.spacing)
            spacing: 4
            StyledText {
                width: parent.width
                text: "Abyss app"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }
            StyledText {
                width: parent.width
                text: row.help
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }

        Flow {
            id: ctl
            spacing: 8
            width: Math.min(implicitWidth, layout.width)

            BandButton {
                visible: row.mode === "confirm"
                kind: "primary"
                label: "Remove the app"
                reduceMotion: row.reduceMotion
                onClicked: {
                    row.installer.uninstall();
                    row.mode = "removed";
                }
            }
            BandButton {
                visible: row.mode === "confirm"
                label: "Keep it"
                reduceMotion: row.reduceMotion
                onClicked: row.mode = "idle"
            }
            BandButton {
                visible: row.mode !== "confirm" && row.present && !row.busy
                label: "Uninstall the app"
                reduceMotion: row.reduceMotion
                onClicked: row.mode = "confirm"
            }
            BandButton {
                visible: row.mode !== "confirm" && !row.present
                kind: "primary"
                enabled: !row.busy
                label: row.busy ? "Installing…" : (row.phase === "failed" ? "Try again" : "Install the app")
                reduceMotion: row.reduceMotion
                onClicked: row.installer.install()
            }
            BandButton {
                visible: row.phase === "failed"
                kind: "mark"
                reduceMotion: row.reduceMotion
                tip: "Open the guide: docs/GUIDE.md#install-the-app"
                Accessible.name: "Open the guide on GitHub"
                onClicked: Qt.openUrlExternally(row.guideUrl + "install-the-app")
            }
            // Brings the invite back after "Don't ask again"
            BandButton {
                visible: row.prefs.appDontAsk && row.mode !== "confirm"
                kind: "quiet"
                label: "Ask me again"
                reduceMotion: row.reduceMotion
                onClicked: row.prefs.set("appDontAsk", false)
            }
        }
    }
}
