import QtQuick
import Quickshell.Io

// Asks once whether the `abyss` command is on PATH (the app is installed).
// Started on demand, it ends by itself; nothing runs otherwise.
Process {
    id: root

    signal found(bool installed)

    function start() {
        root.running = true;
    }

    // The name travels as a positional parameter, never in the string
    command: ["sh", "-c", "command -v -- \"$1\"", "sh", "abyss"]
    onExited: exitCode => root.found(exitCode === 0)
}
