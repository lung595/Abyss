import QtQuick
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "components"
import "components/Bowl.js" as Bowl

// Desktop surface: the deep in a round glass fishbowl standing on the
// wallpaper (FishBowl draws the glass, the water and the gravel around it). Still by
// default: no clock and no traffic reads until the pointer is over it
// (or "Keep the desktop alive" is on).
DesktopPluginComponent {
    id: root

    minWidth: 400
    minHeight: 340
    property real defaultWidth: 680
    property real defaultHeight: 560

    readonly property var daemon: PluginService.pluginDaemonInstances["abyss"] ?? null
    readonly property bool hot: hover.hovered
    // A desktop layer gets no keyboard by default. While a card is open it
    // may take it on click (DMS: OnDemand), so a name can be typed.
    readonly property bool acceptsKeyboardFocus: scene.cardId !== "" || scene.query !== ""

    function dismiss() {
        scene.cardId = "";
        scene.netsOpen = false;
        scene.query = "";
        scene.findId = "";
    }

    // A desktop layer never sees clicks made elsewhere, so the card closes
    // when the pointer leaves for good or another window takes focus
    onHotChanged: {
        if (hot)
            dismissTimer.stop();
        else if (scene.cardId !== "" || scene.netsOpen)
            dismissTimer.restart();
    }

    Timer {
        id: dismissTimer
        interval: 1200
        onTriggered: root.dismiss()
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            if (ToplevelManager.activeToplevel)
                root.dismiss();
        }
    }

    HoverHandler {
        id: hover
    }

    readonly property var bowl: Bowl.build(width, height, scene.topH)

    FishBowl {
        anchors.fill: parent
        part: "back"
        b: root.bowl
        ink: scene.ink
        shallow: scene.shallow
        abyss: scene.abyss
        tints: scene.reefTints
    }
    // The water darkens round an open group, so its pool stands out, and
    // behind an open card, so it reads clearly
    FishBowl {
        anchors.fill: parent
        part: "shade"
        b: root.bowl
        abyss: scene.abyss
        opacity: 0.85 * Math.max(scene.blurMix, scene.cardMix)
        visible: opacity > 0.01
    }
    AbyssScene {
        id: scene
        x: root.bowl.scene.x
        y: root.bowl.scene.y
        width: root.bowl.scene.w
        height: root.bowl.scene.h
        insetTop: root.bowl.scene.insetTop
        insetFloor: root.bowl.scene.insetFloor
        source: root.daemon ? root.daemon.source : null
        actions: root.daemon
        cornerRadius: Theme.cornerRadius
        borderless: true
        active: true
        freezeWhenIdle: true
        interacting: root.hot
    }
    // The glass over the scene (lets the pointer through); it fades while
    // a card is open, its highlights would streak across the text
    FishBowl {
        anchors.fill: parent
        part: "front"
        opacity: 1 - 0.8 * scene.cardMix
        b: root.bowl
        ink: scene.ink
        shallow: scene.shallow
        abyss: scene.abyss
        tints: scene.reefTints
    }
}
