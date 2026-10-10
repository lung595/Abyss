pragma Singleton
import QtQuick

// Test stand-in: records what would have been launched, and says whether the
// `abyss` command is "on PATH" for the stand-in Process of Quickshell.Io
QtObject {
    property var launched: []
    property bool installed: true
    function execDetached(argv) {
        launched = launched.concat([argv]);
    }
}
