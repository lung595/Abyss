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
    // Same guard as the rest of the card: online and the mesh connected
    required property bool live

    readonly property var link: ({
            "direct": live ? !peer.relayed : undefined,
            "relayReason": live && peer.relayed && peer.relay ? "via " + peer.relay : "",
            "latencyMs": live && peer.latencyMs > 0 ? peer.latencyMs : undefined
        })
    readonly property var verdict: Slow.verdict(link)
    readonly property string tip: Slow.tip(link)
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
        visible: root.tip !== ""
        width: parent.width
        spacing: 8
        StyledText {
            width: parent.width - 32
            text: root.tip
            font.pixelSize: 11
            color: root.scene.inkDim
            wrapMode: Text.WordWrap
        }
        GuideLink {
            anchor: "why-is-it-slow"
            tint: root.scene.inkDim
        }
    }
}
