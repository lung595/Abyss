import QtQuick

// Test stand-in for the preferences SendHub reads
QtObject {
    property bool reduceMotion: false
    property string sendFolder: ""
    function linkOf(id) {
        return {};
    }
}
