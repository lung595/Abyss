import QtQuick
import qs.Common
import "Health.js" as Health

// The health of the mesh as the bar shows it: a verdict, its reason and
// the theme colour to draw the jellyfish with. Pure bindings, no timer: it
// is recomputed only when the NetBird view changes.
QtObject {
    // False when the setting is off or the mesh is not connected
    property bool active: false
    property var view: null
    property string exitNode: ""

    readonly property var verdict: active ? Health.evaluate(Health.inputOf(view, exitNode)) : ({
            "state": "ok",
            "reason": ""
        })
    readonly property string state: verdict.state
    readonly property string reason: verdict.reason
    readonly property color tint: Theme[Health.colorRole(state)]
}
