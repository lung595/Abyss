pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets
import "MyGroups.js" as MyGroups

// The light's menu (a click on the Internet light): where Internet goes out,
// as a small file tree. A group of mine is a folder — its name picks the
// whole group, the arrow unfolds it to pick one of its peers — then come the
// lenders in no group. The current choice wears a turning sun (SunGlyph).
Column {
    id: tree
    required property var scene
    readonly property string exitNode: scene.source ? scene.source.exitNode : ""
    readonly property var rows: MyGroups.exitTree(scene.prefs.groups, scene.view.peers, scene.sunOpen, exitNode, scene.prefs.exitGroup, scene.source ? scene.source.looseExits : [])
    spacing: 2

    StyledText {
        leftPadding: 10
        topPadding: 2
        bottomPadding: 4
        text: tree.rows.length ? "Internet goes out through" : "No peer can lend Internet"
        font.pixelSize: 10
        color: tree.scene.inkDim
    }
    Repeater {
        model: tree.rows
        Rectangle {
            id: row
            required property var modelData
            readonly property bool isGroup: modelData.kind === "group"
            readonly property bool usable: isGroup ? !modelData.dim : modelData.online
            readonly property int indent: modelData.depth ? 26 : 0
            width: tree.width
            height: 30
            radius: 8
            color: pick.containsMouse && row.usable ? Qt.rgba(tree.scene.ink.r, tree.scene.ink.g, tree.scene.ink.b, 0.1) : "transparent"
            opacity: row.usable ? 1 : 0.45

            // The branch of a peer inside an open group: │ then └ on the last
            Rectangle {
                visible: row.indent > 0
                x: 17
                y: 0
                width: 1
                height: row.modelData.last ? parent.height / 2 : parent.height + 2
                color: Qt.rgba(tree.scene.ink.r, tree.scene.ink.g, tree.scene.ink.b, 0.22)
            }
            Rectangle {
                visible: row.indent > 0
                x: 17
                y: parent.height / 2
                width: 7
                height: 1
                color: Qt.rgba(tree.scene.ink.r, tree.scene.ink.g, tree.scene.ink.b, 0.22)
            }
            MouseArea {
                id: pick
                anchors.fill: parent
                hoverEnabled: true
                enabled: row.usable
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (row.isGroup)
                        tree.scene.setExit("", row.modelData.id);
                    else if (row.modelData.kind === "route")
                        tree.scene.setExitRoute(row.modelData.id);
                    else
                        tree.scene.setExit(row.modelData.name, "");
                    tree.scene.closeMenu();
                }
            }
            // The arrow of a folder: unfolds it, the menu stays open
            Item {
                id: fold
                visible: row.isGroup
                x: 2
                width: 24
                height: parent.height
                DankIcon {
                    anchors.centerIn: parent
                    name: "chevron_right"
                    size: 16
                    color: tree.scene.inkDim
                    rotation: row.modelData.open ? 90 : 0
                    Behavior on rotation {
                        NumberAnimation {
                            duration: tree.scene.reduceMotion ? 0 : 120
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tree.scene.foldSun(row.modelData.id)
                }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                x: row.isGroup ? 26 : row.indent + 10
                width: side.x - x - 6
                elide: Text.ElideRight
                text: row.modelData.name
                font.pixelSize: 12
                font.weight: row.isGroup ? Font.Medium : Font.Normal
                color: tree.scene.ink
            }
            // Right side: how quick, how many, and the sun on what is in use
            Row {
                id: side
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    // A route no peer is known for yet: no figure, just what it is
                    text: row.isGroup ? (row.modelData.open ? "" : row.modelData.count) : row.modelData.kind === "route" ? "route" : row.modelData.online ? row.modelData.ms + " ms" : "offline"
                    font.pixelSize: 10
                    color: tree.scene.inkDim
                }
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    SunGlyph {
                        anchors.centerIn: parent
                        visible: !!(row.modelData.on || row.modelData.serving)
                        // The chosen one turns; the member a group goes out
                        // through shows the same sun, smaller and still
                        spinning: !!row.modelData.on
                        scale: row.modelData.on ? 1 : 0.75
                        opacity: row.modelData.on ? 1 : 0.7
                        color: tree.scene.sunColor
                        reduceMotion: tree.scene.reduceMotion
                    }
                }
            }
        }
    }
    // Back to going out directly
    Rectangle {
        visible: tree.exitNode !== ""
        width: tree.width
        height: 9
        color: "transparent"
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            width: parent.width - 16
            height: 1
            color: Qt.rgba(tree.scene.ink.r, tree.scene.ink.g, tree.scene.ink.b, 0.12)
        }
    }
    Rectangle {
        visible: tree.exitNode !== ""
        width: tree.width
        height: 30
        radius: 8
        color: stop.containsMouse ? Qt.rgba(tree.scene.ink.r, tree.scene.ink.g, tree.scene.ink.b, 0.1) : "transparent"
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            x: 26
            text: "Stop · go out directly"
            font.pixelSize: 12
            color: tree.scene.ink
        }
        MouseArea {
            id: stop
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                tree.scene.setExit("", "");
                tree.scene.closeMenu();
            }
        }
    }
}
