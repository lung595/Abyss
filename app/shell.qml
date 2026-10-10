import QtQuick
import Quickshell
import Quickshell.Io
import "components"
import "components/Cli.js" as Cli
import "views"

// The Abyss app: one window, one process. Closing the window ends it (no tray,
// nothing left running). Quickshell only: no DMS import anywhere under app/.
ShellRoot {
    id: root

    FloatingWindow {
        id: window

        title: "Abyss"
        visible: true
        implicitWidth: 1280
        implicitHeight: 800
        minimumSize: Qt.size(900, 600)
        color: Theme.surface
        // A closed window (its close button or the compositor) ends the process
        onVisibleChanged: if (!visible)
            Qt.quit()

        AppFrame {
            id: frame

            anchors.fill: parent
            Component.onCompleted: go(Cli.parse(Cli.split(Quickshell.env("ABYSS_ARGV")), Quickshell.env("ABYSS_CWD") ?? ""))
        }
    }

    // `abyss ...` from a second terminal lands here through the launcher. The
    // window is already up (closing it quits), and Quickshell has no way to
    // raise it: the compositor decides focus (Q105).
    // (`qs ipc call abyss go <cwd> <words joined by the unit separator>`)
    IpcHandler {
        function go(cwd: string, words: string): string {
            const target = Cli.parse(Cli.split(words), cwd);
            frame.go(target);
            return target.ok ? "ok" : target.error;
        }

        target: "abyss"
    }
}
