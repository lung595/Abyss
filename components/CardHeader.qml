import QtQuick
import qs.Common
import qs.Widgets

// Who a peer is, centred under its creature on the open card: its kind, its
// name and its state. PeerCard stacks two of them to cross-fade in place
// when ‹ › steps to another peer.
Column {
    id: head

    property var scene
    property var peer
    property bool favorite: false
    property bool isTop: false

    readonly property bool live: !!peer && peer.online && scene.connected
    readonly property color ink: scene.ink

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: ({
                "server": "SERVER",
                "vps": "VPS",
                "laptop": "LAPTOP",
                "desktop": "DESKTOP",
                "phone": "PHONE",
                "pi": "RASPBERRY PI",
                "nas": "NAS"
            })[head.peer ? head.peer.kind : ""] || ""
        font.pixelSize: 10
        font.letterSpacing: 1
        color: head.scene.inkDim
    }
    StyledText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: head.peer ? (head.favorite ? "★ " : "") + head.peer.name : ""
        font.pixelSize: 19
        font.weight: Font.Black
        color: head.ink
        // One line: the card keeps the same height whatever the name
        elide: Text.ElideMiddle
        wrapMode: Text.NoWrap
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        Rectangle {
            width: 8
            height: 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: head.live ? Theme.success : Qt.rgba(head.ink.r, head.ink.g, head.ink.b, 0.35)
        }
        StyledText {
            text: !head.peer ? "" : !head.peer.online ? "Offline" : !head.scene.connected ? "Mesh disconnected" : "Online · " + (head.peer.relayed ? "via " + head.peer.relay : "direct (P2P)") + (head.isTop ? " · top consumer" : "")
            font.pixelSize: 11
            color: head.scene.inkDim
            wrapMode: Text.NoWrap
        }
    }
}
