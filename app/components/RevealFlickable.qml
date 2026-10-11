import QtQuick
import QtQuick.Controls
import "."

// A vertical list that scrolls by wheel and brings a focused child into view.
// No animation at rest: contentY is set once per focus change.
Flickable {
    id: root

    clip: true
    contentWidth: width
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    ScrollBar.vertical: ScrollBar {
        policy: root.contentHeight > root.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Theme.outlineStrong
        }
    }

    // Move contentY so an item that took keyboard focus is fully visible
    function reveal(item) {
        const top = item.mapToItem(contentItem, 0, 0).y;
        const bottom = top + item.height;
        if (top < contentY)
            contentY = top;
        else if (bottom > contentY + height)
            contentY = Math.min(bottom - height, contentHeight - height);
    }
}
