pragma Singleton
import QtQuick

// Test stand-in: records every toast
QtObject {
    property var shown: []
    function showInfo(title, text) {
        shown = shown.concat([text ? title + ": " + text : title]);
    }
}
