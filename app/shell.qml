import QtQuick
import Quickshell
import Quickshell.Io
import "components/Cli.js" as Cli

// The Abyss app: one window, one process. Closing the window ends it (no tray,
// nothing left running). Quickshell only: no DMS import anywhere under app/.
ShellRoot {
    id: root

    // What the window shows: the parsed command line, until the views exist
    property var current: Cli.parse(Cli.split(Quickshell.env("ABYSS_ARGV")), Quickshell.env("ABYSS_CWD") ?? "")

    FloatingWindow {
        id: window

        title: "Abyss"
        visible: true
        implicitWidth: 640
        implicitHeight: 420
        // A closed window (its close button or the compositor) ends the process
        onVisibleChanged: if (!visible)
            Qt.quit()

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Abyss"
                font.pixelSize: 28
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.current.ok ? JSON.stringify(root.current) : root.current.error
            }
        }
    }

    // `abyss ...` from a second terminal lands here through the launcher
    // (`qs ipc call abyss go <cwd> <words joined by the unit separator>`)
    IpcHandler {
        function go(cwd: string, words: string): string {
            root.current = Cli.parse(Cli.split(words), cwd);
            window.visible = true;
            return root.current.ok ? "ok" : root.current.error;
        }

        target: "abyss"
    }
}
