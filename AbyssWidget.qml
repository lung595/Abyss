import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "components"
import "components/Mesh.js" as Mesh

// Bar pill + bar popout + Control Center tile. All three show the same
// source, owned by the daemon. The popout keeps its content loaded, so its
// scene only runs while shown; the Control Center detail is created when
// the tile expands and destroyed when it collapses.
PluginComponent {
    id: root

    // What the bar pill says beside the jellyfish (setting "Bar pill")
    readonly property Prefs prefs: Prefs {}
    readonly property string pillText: !connected || !view || prefs.pill === "icon" ? "" : prefs.pill === "rate" ? Mesh.fmtRate(view.down + view.up) : String(view.online)

    readonly property var daemon: PluginService.pluginDaemonInstances["abyss"] ?? null
    readonly property var source: daemon ? daemon.source : null
    readonly property var view: source ? source.view : null
    readonly property string meshState: view ? view.state : "stopped"
    readonly property bool connected: meshState === "connected"

    // Internet goes out through a peer: a small still sun in the pill
    readonly property bool lending: connected && !!source && source.exitNode !== ""
    readonly property color dotColor: connected ? Theme.success : (meshState === "needsLogin" || meshState === "connecting") ? Theme.warning : Theme.error
    // The tooltip on the bar's jellyfish: everything in four short lines
    readonly property string tipText: {
        if (!view)
            return "Abyss is starting";
        const lines = [({
                    "connected": "NetBird connected · " + view.online + "/" + view.total + " online",
                    "connecting": "NetBird connecting…",
                    "disconnected": "NetBird off",
                    "needsLogin": "NetBird needs you to sign in",
                    "stopped": "The NetBird service is stopped"
                })[meshState] || meshState];
        if (connected) {
            lines.push("↓ " + Mesh.fmtRate(view.down) + "   ↑ " + Mesh.fmtRate(view.up));
            lines.push("Internet " + (daemon ? daemon.exitText() : "directly"));
        }
        lines.push("Click: open" + (prefs.middleToggle ? " · Middle: " + (connected ? "disconnect" : "connect") : "") + " · Right: " + (connected ? "disconnect" : "connect"));
        return lines.join("\n");
    }
    readonly property color stateColor: connected ? Theme.primary : (meshState === "needsLogin" || meshState === "stopped") ? Theme.warning : meshState === "connecting" ? Theme.withAlpha(Theme.primary, 0.7) : Theme.surfaceVariantText

    // --- Control Center -------------------------------------------------------
    ccWidgetIcon: connected ? "vpn_lock" : "vpn_key_off"
    ccWidgetPrimaryText: "NetBird"
    ccWidgetSecondaryText: ({
            "connected": view ? view.online + "/" + view.total + " online" : "",
            "connecting": "Connecting…",
            "disconnected": "Off",
            "needsLogin": "Sign in needed",
            "stopped": "Service stopped"
        })[meshState] ?? ""
    ccWidgetIsActive: connected
    // 360 px was too cramped for the labels
    ccDetailHeight: 440

    onCcWidgetToggled: {
        if (source)
            source.toggle();
    }

    ccDetailContent: Component {
        AbyssScene {
            source: root.source
            actions: root.daemon
            compact: true
            active: true
            cornerRadius: Theme.cornerRadius
        }
    }

    // --- Bar ------------------------------------------------------------------
    horizontalBarPill: Component {
        BarPill {
            widget: root
        }
    }

    verticalBarPill: Component {
        BarPill {
            widget: root
            vertical: true
        }
    }

    // Right click connects or disconnects without opening anything
    pillRightClickAction: () => {
        if (root.source)
            root.source.toggle();
    }

    popoutWidth: 580
    popoutHeight: 480

    popoutContent: Component {
        Item {
            id: pop
            property var parentPopout: null
            readonly property bool shown: pop.parentPopout ? pop.parentPopout.shouldBeVisible : true
            width: parent ? parent.width : 0
            implicitHeight: root.popoutHeight

            AbyssScene {
                id: scene
                anchors.fill: parent
                source: root.source
                actions: root.daemon
                cornerRadius: Theme.cornerRadius
                // The popout keeps its content loaded; only run while shown
                active: pop.shown
                // Typing a peer's name finds it as soon as the popout opens
                onActiveChanged: {
                    if (active)
                        forceActiveFocus();
                }
            }
        }
    }
}
