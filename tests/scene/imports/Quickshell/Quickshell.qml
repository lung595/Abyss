pragma Singleton
import QtQuick

// Test stand-in: records what would have been launched, and says whether the
// `abyss` command is "on PATH" for the stand-in Process of Quickshell.Io
QtObject {
    property var launched: []
    property bool installed: true
    // The app Theme reads its forced scheme and Reduce motion here
    property var envValues: ({})
    function env(name) {
        // Also NAME=value words on the command line: qml-qt6 cannot read the environment
        const arg = Qt.application.arguments.find(a => a.startsWith(name + "="));
        return arg ? arg.slice(name.length + 1) : (envValues[name] ?? null);
    }
    function execDetached(argv) {
        launched = launched.concat([argv]);
    }
}
