import QtQuick
import qs.Common
import qs.Widgets

// The settings section menu: a sounding line (a depth gauge) with a mark
// every 4 px, a long one at each row and a weight that sinks to the open
// section. 176 px wide, 44 px rows, the search field drawn above (static: its
// behaviour is another story). Nothing runs at rest: the only animation is
// the one a section change starts, and it ends by itself.
FocusScope {
    id: root

    // Rows to show, from Sections.js shown(): { id, text, ... }
    required property var rows
    // Index of the section open at first; the rail owns it afterwards
    property int start: 0
    property bool reduceMotion: false

    // The open section, and the one the mark is leaving, for the travel
    property int sel: start
    property int prev: start
    // 0..1 progress of a section change
    property real progress: 1
    // Row under the pointer, row held down, row the keyboard points at
    property int hovered: -1
    property int pressed: -1
    property int pointed: sel

    // The section the page shows. Without motion it swaps at once; with it,
    // at half the travel, so the body is faded out when it changes.
    readonly property int shownIndex: reduceMotion || progress > 0.5 ? sel : prev
    readonly property real markY: rowHeight * (reduceMotion ? sel : prev + (sel - prev) * progress)
    readonly property alias travelling: travel.running

    readonly property int searchHeight: 40
    readonly property int rowHeight: 44
    readonly property int rowsTop: searchHeight + 12

    readonly property int railWidth: 176
    readonly property int rowInset: 16
    readonly property int rowWidth: railWidth - rowInset
    implicitWidth: railWidth
    implicitHeight: rowsTop + rowHeight * rows.length
    activeFocusOnTab: true

    function open(i) {
        if (i < 0 || i >= rows.length || i === sel)
            return;
        prev = sel;
        sel = i;
        travel.restart();
    }

    // Keep the row the keyboard points at inside the scrolling window
    function reveal(i) {
        const y = i * rowHeight;
        if (y < flick.contentY)
            flick.contentY = y;
        else if (y + rowHeight > flick.contentY + flick.height)
            flick.contentY = y + rowHeight - flick.height;
    }
    function point(i) {
        pointed = Math.max(0, Math.min(rows.length - 1, i));
        reveal(pointed);
    }

    onActiveFocusChanged: if (activeFocus)
        point(sel)
    Keys.onUpPressed: point(pointed - 1)
    Keys.onDownPressed: point(pointed + 1)
    Keys.onReturnPressed: open(pointed)
    Keys.onEnterPressed: open(pointed)
    Keys.onSpacePressed: open(pointed)

    NumberAnimation {
        id: travel
        target: root
        property: "progress"
        from: 0
        to: 1
        // Reduce motion: no travel, a short fade of the mark in place
        duration: root.reduceMotion ? 100 : 200
        easing.type: Easing.OutCubic
    }

    // Search field, drawn only: disabled, nothing to type into yet
    Rectangle {
        width: parent.width
        height: root.searchHeight
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outline
        StyledText {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Search settings"
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
        }
    }

    // Rows scroll under the fixed search field when they outgrow the height
    Flickable {
        id: flick
        objectName: "rows"
        y: root.rowsTop
        width: parent.width
        height: Math.max(0, root.height - root.rowsTop)
        contentWidth: width
        contentHeight: root.rowHeight * root.rows.length
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        // The line, on the weight's axis
        Rectangle {
            x: 4
            width: 1
            height: flick.contentHeight
            color: Theme.outline
        }
        // Marks: 11 per row, the middle one long. Pressing a row makes its
        // long mark reach out, so the press is told by form and not by tone.
        Repeater {
            model: 11 * root.rows.length
            Rectangle {
                required property int index
                readonly property bool major: index % 11 === 5
                readonly property bool reach: major && root.pressed === Math.floor(index / 11)
                x: 5
                y: 2 + 4 * index
                width: reach ? 12 : major ? 8 : 4
                height: 1
                color: reach ? Theme.primary : major ? Theme.outline : Qt.alpha(Theme.outline, 0.4)
            }
        }

        // The open section: wash and weight
        Rectangle {
            x: root.rowInset
            y: root.markY
            width: root.rowWidth
            height: root.rowHeight
            radius: Theme.cornerRadius
            color: Qt.alpha(Theme.primary, 0.24)
            opacity: root.reduceMotion ? root.progress : 1
        }
        Rectangle {
            x: 0
            y: root.markY + 8
            width: 8
            height: 28
            radius: 4
            color: Theme.primary
            opacity: root.reduceMotion ? root.progress : 1
        }

        Repeater {
            model: root.rows
            Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: root.shownIndex === index
                readonly property bool isPressed: root.pressed === index
                // Pressed: logo and label sink 1 px
                readonly property int sink: isPressed ? 1 : 0
                x: root.rowInset
                y: root.rowHeight * index
                width: root.rowWidth
                height: root.rowHeight

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
                Accessible.selected: on

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius
                    color: Qt.alpha(Theme.surfaceText, 0.08)
                    opacity: root.hovered === row.index || row.isPressed ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.reduceMotion ? 0 : root.hovered === row.index ? 150 : 100
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius
                    color: Qt.alpha(Theme.surfaceText, 0.12)
                    opacity: row.isPressed ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.reduceMotion ? 0 : 100
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                // Keyboard focus: a ring concentric with the row, inset 2 px
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.cornerRadius - 2
                    visible: root.activeFocus && root.pointed === row.index
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                }
                SectionLogo {
                    x: 8
                    y: 12 + row.sink
                    name: row.modelData.id
                    open: row.on
                }
                StyledText {
                    x: 36
                    width: parent.width - x - 4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: row.sink
                    text: row.modelData.text
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: row.on ? Font.DemiBold : Font.Normal
                    color: row.on ? Theme.surfaceText : Theme.surfaceVariantText
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hovered = row.index
                    onExited: root.hovered = -1
                    onPressed: root.pressed = row.index
                    onReleased: root.pressed = -1
                    onCanceled: root.pressed = -1
                    onClicked: {
                        root.forceActiveFocus();
                        root.pointed = row.index;
                        root.open(row.index);
                    }
                }
            }
        }
    }
}
