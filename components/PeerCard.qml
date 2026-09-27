import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets
import "Mesh.js" as Mesh

// Everything about one peer, opened by a click on its creature: live rates
// (either side of its medallion) and the last minute, its addresses to copy, and what you can do with it.
// Its creature is not drawn here: CardHero flies it onto the top edge, in a
// medallion that breaks out of the frame (topPad leaves room for it).
// Frosted glass over a still, blurred picture of the deep; always the same
// height, so ‹ › can step through peers with only a cross-fade in place.
Item {
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

    // The glass: a blurred still of the deep (a layered item the size of the
    // scene) and where the card sits over it
    property Item glass: null
    property point glassAt
    // In the fishbowl the deep has no water behind it, so the blurred
    // picture is mostly clear: the tint carries the card instead
    property bool clearWater: false

    // Stepping with ‹ ›: the peer shown before, fading out while this one
    // fades in (0 → 1); canStep hides the arrows when there is no other peer
    property var prevPeer: null
    property bool prevFavorite: false
    property bool prevIsTop: false
    property real swap: 1
    property bool canStep: false

    signal closed
    signal step(int dir)

    readonly property bool live: peer.online && scene.connected
    readonly property color ink: scene.ink
    // What you send: your own colour, as the "you" chip
    readonly property color upTint: Theme.tertiary
    readonly property real radius: 18

    // Only what sits under the scroll area changes the height: the card
    // itself keeps the size the scene gives it
    readonly property real headH: header.implicitHeight + 8

    // Swallow clicks so they do not reach the water behind
    MouseArea {
        anchors.fill: parent
    }

    // The deep behind, blurred once when the card opened, cut to the card's
    // rounded shape. Nothing is re-blurred while it is open: the cut only
    // follows the card while it rises or sinks.
    ShaderEffectSource {
        id: glassCut
        width: card.width
        height: card.height
        visible: false
        sourceItem: card.glass
        sourceRect: Qt.rect(card.glassAt.x, card.glassAt.y, card.width, card.height)
    }
    Rectangle {
        id: glassMask
        anchors.fill: parent
        radius: card.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        visible: !!card.glass
        source: glassCut
        maskEnabled: true
        maskSource: glassMask
        // Sharp enough for the rounded corner, soft enough to stay smooth
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.2
    }
    Rectangle {
        anchors.fill: parent
        radius: card.radius
        color: Qt.rgba(card.scene.abyss.r, card.scene.abyss.g, card.scene.abyss.b, card.clearWater ? 0.97 : card.glass ? 0.7 : 0.9)
        border.width: 1
        border.color: Qt.rgba(card.tint.r, card.tint.g, card.tint.b, 0.45)
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
            // A long name keeps its start and its domain
            elide: Text.ElideMiddle
        }
        ActionChip {
            id: copyBtn
            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            height: 26
            icon: "content_copy"
            tip: "Copy"
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

    // Live rates on either side of the creature's medallion, each on its
    // own small card: received on the left in the peer's colour (it comes
    // from them), sent on the right in yours (the "you" tint), the same
    // colours as the curve below. Just under the back button.
    component Rate: Rectangle {
        property real rate
        property string arrow
        property color hue
        // 4 px under the back button (y 10, 30 high)
        y: 44
        width: card.width / 2 - card.scene.medallion / 2 - 20
        height: Math.max(20, card.topPad - 44)
        radius: 9
        color: Qt.rgba(hue.r, hue.g, hue.b, 0.12)
        border.width: 1
        border.color: Qt.rgba(hue.r, hue.g, hue.b, 0.3)
        opacity: 0.4 + 0.6 * card.swap
        StyledText {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: parent.arrow + " " + Mesh.fmtRate(card.live ? parent.rate : 0)
            font.pixelSize: 14
            font.weight: Font.Bold
            font.family: Theme.monoFontFamily
            // A narrow card shrinks the figure rather than cutting it
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 10
            wrapMode: Text.NoWrap
            color: parent.hue
        }
    }
    Rate {
        x: 12
        arrow: "↓"
        rate: card.peer.down
        hue: card.tint
    }
    Rate {
        x: card.width - width - 12
        arrow: "↑"
        rate: card.peer.up
        hue: card.upTint
    }

    // Who it is, fixed under its creature; the peer before fades out in the
    // same place while this one fades in
    Item {
        id: header
        x: 44
        y: card.topPad + 4
        width: card.width - 88
        implicitHeight: now.implicitHeight
        CardHeader {
            width: parent.width
            visible: opacity > 0.01
            opacity: 1 - card.swap
            scene: card.scene
            peer: card.prevPeer
            favorite: card.prevFavorite
            isTop: card.prevIsTop
        }
        CardHeader {
            id: now
            width: parent.width
            opacity: card.swap
            scene: card.scene
            peer: card.peer
            favorite: card.favorite
            isTop: card.isTop
        }
    }
    // ‹ › and ←/→: the peer before or after, without leaving the card
    ActionChip {
        visible: card.canStep
        x: 8
        anchors.verticalCenter: header.verticalCenter
        height: 30
        icon: "chevron_left"
        ink: card.ink
        onClicked: card.step(-1)
    }
    ActionChip {
        visible: card.canStep
        x: card.width - width - 8
        anchors.verticalCenter: header.verticalCenter
        height: 30
        icon: "chevron_right"
        ink: card.ink
        onClicked: card.step(1)
    }

    Flickable {
        id: details
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: card.topPad + card.headH
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // The details of the new peer settle in as its name fades in
        opacity: 0.4 + 0.6 * card.swap

        Column {
            id: col
            width: parent.width
            spacing: 9

            Sparkline {
                width: parent.width
                height: 40
                points: card.history
                color: card.tint
                upColor: card.upTint
                ink: card.ink
            }

            // Address on the left, name on the right: one line, one copy each
            Row {
                width: parent.width
                spacing: 8
                CopyRow {
                    width: card.peer.fqdn !== "" ? (col.width - 8) * 0.42 : col.width
                    value: card.peer.ip
                    what: "IP of " + card.peer.name
                }
                CopyRow {
                    visible: card.peer.fqdn !== ""
                    width: (col.width - 8) * 0.58
                    value: card.peer.fqdn
                    what: "Name of " + card.peer.name
                }
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
                // Only for a peer that offers an exit node; through the scene so
                // a group chosen before is let go too
                ActionChip {
                    visible: !!card.peer && !!card.peer.exit
                    icon: "public"
                    text: card.isExit ? "Lends you Internet ✓" : "Use for Internet"
                    checked: card.isExit
                    accent: card.scene.sunColor
                    ink: card.ink
                    onClicked: card.scene.setExit(card.isExit ? "" : card.peer.name, "")
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

    // More below: the details fade out at the bottom edge instead of being cut
    Rectangle {
        visible: details.contentY < details.contentHeight - details.height - 1
        x: 1
        width: card.width - 2
        height: 22
        y: card.height - height - 1
        radius: card.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(card.scene.abyss.r, card.scene.abyss.g, card.scene.abyss.b, 0)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(card.scene.abyss.r, card.scene.abyss.g, card.scene.abyss.b, 0.95)
            }
        }
    }
}
