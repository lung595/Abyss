import QtQuick

// Test stand-in: reads nothing
QtObject {
    property string splitMarker: "\n"
    signal read(string data)
}
