import QtQuick
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

// Everything about one peer, opened by a click on its creature: live rates
// and the last minute, its addresses to copy, and what you can do with it.
// Its creature is not drawn here: CardHero flies it onto the top edge, in a
// medallion that breaks out of the frame (topPad leaves room for it).
Rectangle {
    id: card

    property var scene
    property var peer
    property var source
    property color tint: Theme.primary
    property var history: []
    property bool isTop: false
    property bool isExit: false
    property bool favorite: false
    property bool muted: false
    property var viaNetworks: []

    // Room at the top for the lower half of the creature's medallion
    property real topPad: 0

    signal closed

    readonly property bool live: peer.online && scene.connected
    readonly property color ink: scene.ink

    implicitHeight: col.implicitHeight + 24 + topPad
    radius: 18
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.9)
    border.width: 1
    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.45)

    // Swallow clicks so they do not reach the water behind
    MouseArea {
        anchors.fill: parent
    }

    component Line: Row {
        property string k
        property string v
        width: parent ? parent.width : 0
        StyledText {
            width: parent.width * 0.5
            text: parent.k
            font.pixelSize: 11
            color: card.scene.inkDim
            wrapMode: Text.NoWrap
        }
        StyledText {
            width: parent.width * 0.5
            text: parent.v
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 11
            font.family: Theme.monoFontFamily
            color: card.ink
            wrapMode: Text.NoWrap
        }
    }

    component CopyRow: Rectangle {
        property string value
        property string what
        width: parent ? parent.width : 0
        height: 32
        radius: 9
        color: Qt.rgba(card.ink.r, card.ink.g, card.ink.b, 0.06)
        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: copyBtn.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            font.pixelSize: 12
            font.family: Theme.monoFontFamily
            color: card.ink
            wrapMode: Text.NoWrap
        }
        ActionChip {
            id: copyBtn
            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            height: 26
            icon: "content_copy"
            text: "Copy"
            ink: card.ink
            onClicked: card.scene.copy(parent.value, parent.what)
        }
    }

    // Back, top left (as in Orbit); Esc or a click outside also closes
    ActionChip {
        x: 10
        y: 10
        z: 1
        height: 30
        icon: "arrow_back"
        ink: card.ink
        onClicked: card.closed()
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 12 + card.topPad
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 9

            // Who it is, centred under its creature
            Column {
                width: parent.width
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
                        })[card.peer.kind] || ""
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    color: card.scene.inkDim
                }
                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (card.favorite ? "★ " : "") + card.peer.name
                    font.pixelSize: 19
                    font.weight: Font.Black
                    color: card.ink
                    wrapMode: Text.WrapAnywhere
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: card.live ? Theme.success : Qt.rgba(card.ink.r, card.ink.g, card.ink.b, 0.35)
                    }
                    StyledText {
                        text: !card.peer.online ? "Offline" : !card.scene.connected ? "Mesh disconnected" : "Online · " + (card.peer.relayed ? "via " + card.peer.relay : "direct (P2P)") + (card.isTop ? " · top consumer" : "")
                        font.pixelSize: 11
                        color: card.scene.inkDim
                        wrapMode: Text.NoWrap
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [["Received", card.peer.down], ["Sent", card.peer.up]]
                    Rectangle {
                        required property var modelData
                        width: (col.width - 8) / 2
                        height: 46
                        radius: 10
                        color: Qt.rgba(card.ink.r, card.ink.g, card.ink.b, 0.06)
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                text: modelData[0]
                                font.pixelSize: 10
                                color: card.scene.inkDim
                            }
                            StyledText {
                                text: (modelData[0] === "Received" ? "↓ " : "↑ ") + Mesh.fmtRate(card.live ? modelData[1] : 0)
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                font.family: Theme.monoFontFamily
                                color: card.ink
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
                }
            }

            Sparkline {
                width: parent.width
                height: 54
                points: card.history
                color: card.tint
                ink: card.ink
            }

            CopyRow {
                value: card.peer.ip
                what: "IP of " + card.peer.name
            }
            CopyRow {
                visible: card.peer.fqdn !== ""
                value: card.peer.fqdn
                what: "Name of " + card.peer.name
            }

            Flow {
                width: parent.width
                spacing: 6
                ActionChip {
                    primary: true
                    icon: "terminal"
                    text: "SSH"
                    accent: card.tint
                    ink: card.ink
                    onClicked: card.scene.ssh(card.peer)
                }
                ActionChip {
                    icon: "open_in_browser"
                    text: "Browser"
                    ink: card.ink
                    onClicked: card.scene.openWeb(card.peer)
                }
                ActionChip {
                    icon: "public"
                    text: card.isExit ? "Internet exit ✓" : "Internet exit"
                    checked: card.isExit
                    accent: card.scene.sunColor
                    ink: card.ink
                    onClicked: card.source && card.source.setExitNode(card.isExit ? "" : card.peer.name)
                }
                ActionChip {
                    icon: "star"
                    text: "Favorite"
                    checked: card.favorite
                    ink: card.ink
                    onClicked: card.scene.prefs.toggleFavorite(card.peer.id, card.peer.name)
                }
                ActionChip {
                    icon: card.muted ? "notifications_off" : "notifications"
                    text: "Mute"
                    checked: card.muted
                    ink: card.ink
                    onClicked: card.scene.prefs.toggleMuted(card.peer.id, card.peer.name)
                }
            }

            Column {
                width: parent.width
                spacing: 3
                Line {
                    k: "Latency"
                    v: card.live ? Math.round(card.peer.latencyMs) + " ms" : "—"
                }
                Line {
                    k: "Connected for"
                    v: card.peer.online && card.peer.since ? Mesh.fmtAgo(Date.now() - card.peer.since) : "—"
                }
                Line {
                    k: "Last handshake"
                    v: card.live && card.peer.handshake ? Mesh.fmtAgo(Date.now() - card.peer.handshake) + " ago" : "—"
                }
                Line {
                    k: "Total"
                    v: "↓ " + Mesh.fmtBytes(card.peer.rx) + " · ↑ " + Mesh.fmtBytes(card.peer.tx)
                }
            }

            Repeater {
                model: card.viaNetworks
                Rectangle {
                    required property var modelData
                    width: col.width
                    height: 34
                    radius: 9
                    color: Qt.rgba(card.ink.r, card.ink.g, card.ink.b, 0.06)
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        StyledText {
                            text: modelData.id
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: card.ink
                        }
                        StyledText {
                            text: modelData.cidr
                            font.pixelSize: 10
                            font.family: Theme.monoFontFamily
                            color: card.scene.inkDim
                        }
                    }
                    ActionChip {
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        height: 26
                        text: modelData.on ? "On" : "Off"
                        checked: modelData.on
                        accent: Theme.tertiary
                        ink: card.ink
                        onClicked: card.source && card.source.toggleNetwork(modelData.id)
                    }
                }
            }
        }
    }
}
