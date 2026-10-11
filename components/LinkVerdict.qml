import QtQuick
import qs.Common
import qs.Widgets
import "Slow.js" as Slow

// The peer card's answer to "why is it slow?": one plain sentence built
// from what Abyss already knows (direct or relayed, latency). Nothing is
// measured here. A relayed link adds a short piece of advice and the GitHub
// mark, which opens the guide section in the browser on click only.
Column {
    id: root

    required property var scene
    required property var peer
    required property color ink

    readonly property string guide: "https://github.com/lung595/Abyss/blob/main/docs/GUIDE.md#why-is-it-slow"
    readonly property bool live: !!peer && peer.online
    readonly property var verdict: Slow.verdict({
        "direct": live ? !peer.relayed : undefined,
        "relayReason": live && peer.relayed && peer.relay ? "via " + peer.relay : "",
        "latencyMs": live && peer.latencyMs > 0 ? peer.latencyMs : undefined
    })
    // Level colour from the theme, never fixed
    readonly property color levelColor: verdict.level === "good" ? Theme.primary : verdict.level === "fair" ? Theme.tertiary : verdict.level === "slow" ? Theme.error : scene.inkDim

    visible: live
    width: parent ? parent.width : 0
    spacing: 4

    StyledText {
        width: parent.width
        text: root.verdict.text
        font.pixelSize: 11
        color: root.levelColor
        wrapMode: Text.WordWrap
    }

    Row {
        visible: !!root.peer && root.peer.relayed
        width: parent.width
        spacing: 8
        StyledText {
            width: parent.width - 24
            text: "Traffic goes through a relay. A direct link is faster: allow UDP on both networks, or turn off a restrictive firewall."
            font.pixelSize: 11
            color: root.scene.inkDim
            wrapMode: Text.WordWrap
        }
        Item {
            width: 16
            height: 16
            GitHubMark {
                anchors.centerIn: parent
                size: 16
                color: link.containsMouse ? Theme.primary : root.scene.inkDim
            }
            MouseArea {
                id: link
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally(root.guide)
            }
        }
    }
}
