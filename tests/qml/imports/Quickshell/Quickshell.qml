pragma Singleton
import QtQuick

// Test stand-in: records what would have been launched
QtObject {
    property var launched: []
    function execDetached(argv) {
        launched = launched.concat([argv]);
    }
}
