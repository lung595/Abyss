import QtQuick
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "components"

// Desktop surface: the deep as a window onto the wallpaper. Still by
// default: no clock and no traffic reads until the pointer is over it
// (or "Keep the desktop alive" is on).
DesktopPluginComponent {
    id: root

    minWidth: 340
    minHeight: 280
    property real defaultWidth: 580
    property real defaultHeight: 440

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

    AbyssScene {
        id: scene
        anchors.fill: parent
        source: root.daemon ? root.daemon.source : null
        actions: root.daemon
        cornerRadius: Theme.cornerRadius
        active: true
        freezeWhenIdle: true
        interacting: root.hot
    }
}
