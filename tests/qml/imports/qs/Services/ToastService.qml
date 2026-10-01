pragma Singleton
import QtQuick

// Test stand-in: records every toast
QtObject {
    property var shown: []
    function showInfo(title, text) {
        shown = shown.concat([text ? title + ": " + text : title]);
    }
    // A warning with a command to copy: recorded as "! title: text [command]"
    property var warned: []
    function showWarning(title, text, command, category) {
        warned = warned.concat(["! " + title + ": " + (text || "") + (command ? " [" + command + "]" : "")]);
    }
}
