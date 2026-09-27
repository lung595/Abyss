import QtQuick

// Now and then a fish crossing near the floor (placeholder: being drawn)
Item {
    id: fish

    property var frame
    // The scene clock (seconds); it only runs while someone watches
    property real t: 0
    // Only while the deep flows
    property bool live: false
}
