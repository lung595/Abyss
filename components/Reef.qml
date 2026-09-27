pragma ComponentBehavior: Bound
import QtQuick
import "ReefPlan.js" as Plan

// The life of the deep, in depth: a far ridge in the haze, a middle ridge and
// cliffs, then the floor with corals, sponges, anemones, sea fans and algae
// swaying in one slow current, and small schools passing. Two copies exist:
// the dark one (lit: false) is always there, a shade darker than the water;
// the lit one (lit: true) is only seen in a soft disc under the pointer's
// lamp. Both come from the same seed and the same clock, so they match
// shape for shape. Planes are painted once per size, theme or number of
// caves; only cheap moves (slide, turn) follow the clock.
Item {
    id: reef

    property var frame
    property bool lit: false
    property color ink
    property color shadow
    property color stone
    property color sand
    // The water around, which far things melt into
    property color water
    property var tints: []
    // How many caves sit on the left of the floor (kept clear)
    property int caves: 0
    // The scene clock (s) and whether the deep flows
    property real t: 0
    property bool live: false
    // Where the lens is, from -1 (left edge) to 1 (right edge): the parallax
    property real drift: 0

    readonly property var f: frame || { "w": 0, "h": 0, "surfaceY": 0, "floorY": 0 }
    readonly property var plan: frame ? Plan.build(frame, caves, 7) : null
    readonly property var pal: ({
            "lit": lit,
            "ink": ink,
            "shadow": shadow,
            "stone": stone,
            "sand": sand,
            "water": water,
            "tints": tints
        })
    readonly property real cliffW: Math.max(16, f.w * 0.04) + 26

    visible: !!frame

    ReefPlane {
        part: "far"
        depth: 3
        baseX: -40
        baseY: reef.f.floorY - reef.f.h * 0.3
        width: reef.f.w + 80
        height: reef.f.h - baseY
        frame: reef.frame
        plan: reef.plan
        pal: reef.pal
        drift: reef.drift
    }
    ReefPlane {
        part: "mid"
        depth: 7
        baseX: -30
        baseY: reef.f.floorY - reef.f.h * 0.2
        width: reef.f.w + 40
        height: reef.f.h - baseY
        frame: reef.frame
        plan: reef.plan
        pal: reef.pal
        drift: reef.drift
    }
    ReefPlane {
        // The left cliff's band
        part: "cliffs"
        depth: 8
        baseX: -30
        baseY: reef.f.surfaceY
        width: reef.cliffW + 30
        height: reef.f.h - baseY
        frame: reef.frame
        plan: reef.plan
        pal: reef.pal
        drift: reef.drift
    }
    ReefPlane {
        // The right cliff's band
        part: "cliffs"
        depth: 8
        baseX: reef.f.w - reef.cliffW
        baseY: reef.f.surfaceY
        width: reef.cliffW + 30
        height: reef.f.h - baseY
        frame: reef.frame
        plan: reef.plan
        pal: reef.pal
        drift: reef.drift
    }
    ReefFish {
        anchors.fill: parent
        frame: reef.frame
        t: reef.t
        live: reef.live
        lit: reef.lit
        body: reef.lit ? reef.stone : reef.shadow
        shift: -reef.drift * 10
    }
    ReefPlane {
        part: "floor"
        depth: 14
        baseX: -20
        baseY: reef.f.floorY - 12
        width: reef.f.w + 40
        height: reef.f.h - baseY
        frame: reef.frame
        plan: reef.plan
        pal: reef.pal
        drift: reef.drift
    }
    Repeater {
        model: reef.plan ? reef.plan.life : []
        ReefPlant {
            required property var modelData
            it: modelData
            pal: reef.pal
            t: reef.t
            live: reef.live
            shift: -reef.drift * (modelData.ledge ? 8 : 14)
        }
    }
}
