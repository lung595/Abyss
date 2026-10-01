import QtQuick
import qs.Common
import qs.Widgets

// The jellyfish in the bar, either way round: its state as a colour and a
// dot, what the "Beside the jellyfish" setting asks for, and a sun while
// Internet goes out through a peer. Hovering says everything in a tooltip;
// a middle click connects or disconnects (both can be turned off).
Item {
    id: pill

    property var widget
    property bool vertical: false

    implicitWidth: lay.implicitWidth
    implicitHeight: lay.implicitHeight

    Grid {
        id: lay
        columns: pill.vertical ? 1 : 3
        spacing: pill.vertical ? 2 : Theme.spacingXS
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        Item {
            width: pill.widget.iconSize
            height: pill.widget.iconSize
            JellyGlyph {
                anchors.fill: parent
                color: pill.widget.stateColor
                asleep: !pill.widget.connected
            }
            // Green in, orange needs you, red off: the state at a glance
            Rectangle {
                visible: pill.widget.prefs.statusDot
                width: Math.max(6, parent.width * 0.3)
                height: width
                radius: width / 2
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -1
                color: pill.widget.dotColor
                border.width: 1.5
                border.color: Theme.surface
                // A connection under way breathes
                SequentialAnimation on opacity {
                    running: pill.widget.meshState === "connecting" && !pill.widget.prefs.reduceMotion
                    loops: Animation.Infinite
                    onStopped: parent.opacity = 1
                    NumberAnimation {
                        to: 0.3
                        duration: 600
                    }
                    NumberAnimation {
                        to: 1
                        duration: 600
                    }
                }
            }
        }
        StyledText {
            visible: pill.widget.pillText !== ""
            text: pill.widget.pillText
            color: Theme.primary
            font.pixelSize: Theme.fontSizeSmall
        }
        // Never turns here: the bar stays still
        SunGlyph {
            visible: pill.widget.lending
            spinning: false
            color: Theme.primary
        }
    }

    // Passive: the bar's own clicks still reach the pill
    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered)
                tipDelay.restart();
            else {
                tipDelay.stop();
                if (tip.item)
                    tip.item.hide();
                tip.active = false;
            }
        }
    }
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        enabled: pill.widget.prefs.middleToggle
        onTapped: {
            if (pill.widget.source)
                pill.widget.source.toggle();
        }
    }

    Timer {
        id: tipDelay
        interval: 450
        onTriggered: {
            tip.active = true;
            if (!tip.item)
                return;
            const w = pill.widget, scr = w.parentScreen || Screen;
            const at = pill.mapToItem(null, pill.width / 2, pill.height / 2);
            const edge = w.axis ? w.axis.edge : "top";
            const gap = w.barThickness + w.barSpacing + Theme.spacingXS;
            if (edge === "left" || edge === "right")
                tip.item.show(w.tipText, edge === "left" ? gap : scr.width - gap, at.y, scr, edge === "left", edge === "right");
            else
                tip.item.show(w.tipText, at.x, edge === "bottom" ? scr.height - gap - 90 : gap, scr, false, false);
        }
    }
    Loader {
        id: tip
        active: false
        sourceComponent: DankTooltip {}
    }
}
