import QtQuick

// The life on the sea floor (placeholder: being drawn)
Canvas {
    id: reef

    property var frame
    property color abyss
    property color ink
    // How many caves sit on the left of the floor (kept clear)
    property int caves: 0
}
