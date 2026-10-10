import QtQuick
import "Mood.js" as Mood
import "MoodEvents.js" as Events

// Darwin's mood, as state with no drawing. It owns the Mood.js automaton, turns
// mesh changes into its events (MoodEvents.js) and exposes what a view needs:
// the dominant mood, its weight and the gaze. One Timer steps it, and only
// while `active`; when inactive nothing runs at all. Not wired yet (NAK-239).
Item {
    id: root

    // False while the view is closed, hidden, covered, the session locked or
    // the companion off: the timer is then stopped, not just idle
    property bool active: false
    property bool reduceMotion: false
    property bool onBattery: false
    // The water he may use, his hiding spots, and the seed of his chance
    property var bounds: ({
            "l": 0,
            "r": 100,
            "top": 0,
            "bottom": 100
        })
    property var hides: []
    property int seed: 7

    // Inputs: the device list ([{ id, online }]) is diffed on every change
    property var peers: []
    // "started", "succeeded", "failed" or anything else for none
    property string sendPhase: ""

    // Outputs, refreshed by each tick: a Mood.js mood index and its weight
    readonly property int mood: _mood
    readonly property real intensity: _intensity
    readonly property real gazeX: _gx
    readonly property real gazeY: _gy
    readonly property alias tickInterval: tick.interval
    readonly property bool ticking: tick.running

    property int _mood: Mood.CALM
    property real _intensity: 1
    property real _gx: 0
    property real _gy: 0
    property double _last: 0
    readonly property var _state: Mood.create(bounds, hides, seed)
    readonly property var _events: Events.create()

    // Relay blink, click on Darwin and lamp moves come from the view
    function relay(x, y) {
        _emit(Events.relay(_events, _now(), x, y));
    }
    function click(x, y) {
        _emit(Events.click(_events, _now(), x, y));
    }
    function rush(x, y) {
        Mood.event(_state, "rush", x, y);
    }
    function lampMoved(x, y) {
        Mood.lamp(_state, x, y);
    }
    function pointerMoved(x, y) {
        Mood.pointer(_state, x, y);
    }
    // Hunger and dirt (0..1) are fed by the caller; they steer the needs
    property real hunger: 0
    property real dirt: 0

    // Seconds on a clock that runs even while the timer is stopped, so the
    // cooldowns of MoodEvents.js expire
    function _now() {
        return Date.now() / 1000;
    }

    function _emit(ev) {
        if (ev)
            Mood.event(_state, ev.kind, ev.x, ev.y);
    }

    function _apply(list) {
        for (let i = 0; i < list.length; i++)
            _emit(list[i]);
    }

    onPeersChanged: _apply(Events.devices(_events, peers, _now()))
    onSendPhaseChanged: _emit(Events.send(_events, sendPhase, _now()))

    function _step() {
        const now = Date.now();
        // A long gap (resumed after being inactive) must not jump the fish
        const dt = Math.min((now - _last) / 1000, 0.25);
        _last = now;
        Mood.step(_state, dt, {
            "hunger": hunger,
            "dirt": dirt
        });
        const w = _state.w;
        let best = 0;
        for (let i = 1; i < w.length; i++)
            if (w[i] > w[best])
                best = i;
        _mood = best;
        _intensity = w[best];
        _gx = _state.gx;
        _gy = _state.gy;
    }

    onActiveChanged: if (active)
        _last = Date.now()

    // 30 Hz normally, 15 Hz on battery, 4 Hz with Reduce motion (no smooth
    // motion to feed, the mood itself still moves on)
    Timer {
        id: tick
        interval: root.reduceMotion ? 250 : root.onBattery ? 66 : 33
        repeat: true
        running: root.active
        onTriggered: root._step()
    }
}
