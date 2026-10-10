import QtQuick
import Quickshell

// Test stand-in: "runs" and exits at once and exits 0 when the stand-in says the
// command exists, 1 otherwise
QtObject {
    id: root
    property var command: []
    property bool running: false
    signal exited(int exitCode, int exitStatus)

    onRunningChanged: {
        if (!running)
            return;
        root.running = false;
        root.exited(Quickshell.installed ? 0 : 1, 0);
    }
}
