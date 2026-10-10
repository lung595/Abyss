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

    // Inputs: the device list ([{ id, online }]) is diffed on every change;
    // hunger and dirt (0..1) are fed by the caller and steer the needs
    property var peers: []
    property real hunger: 0
    property real dirt: 0

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
    // Created on first use and never rebuilt: a resize must not reset the mood
    property var _state: null
    readonly property var _events: Events.create()
    // Reused by every step: nothing is allocated per tick
    readonly property var _env: ({
            "hunger": 0,
            "dirt": 0
        })

    // Events come from the view as calls, so a repeat (two sends ending the
    // same way) still counts. phase: "started", "succeeded" or "failed"
    function relay(x, y) {
        _emit(Events.relay(_events, _now(), x, y));
    }
    function click(x, y) {
        _emit(Events.click(_events, _now(), x, y));
    }
    function rush(x, y) {
        _emit(Events.rush(_events, _now(), x, y));
    }
    function send(phase, x, y) {
        _emit(Events.send(_events, phase, _now(), x, y));
    }
    function lampMoved(x, y) {
        Mood.lamp(_st(), x, y);
    }
    function pointerMoved(x, y) {
        Mood.pointer(_st(), x, y);
    }

    function _st() {
        if (!_state)
            _state = Mood.create(bounds, hides, seed);
        return _state;
    }

    // Seconds on a clock that runs even while the timer is stopped, so the
    // cooldowns of MoodEvents.js expire
    function _now() {
        return Date.now() / 1000;
    }

    // Events that happen while inactive are dropped: a device that went away
    // hours ago must not scare him when the view opens
    function _emit(ev) {
        if (ev && active)
            Mood.event(_st(), ev.kind, ev.x, ev.y);
    }

    onPeersChanged: {
        // Diffed even while inactive, so the known devices stay right
        const list = Events.devices(_events, peers, _now());
        for (let i = 0; i < list.length; i++)
            _emit(list[i]);
    }
    onBoundsChanged: if (_state)
        Mood.resize(_state, bounds, hides)
    onHidesChanged: if (_state)
        Mood.resize(_state, bounds, hides)

    function _step() {
        const now = Date.now();
        // A long gap (resumed after being inactive) must not jump the fish, and
        // the wall clock stepping back must not run the mood backwards; the cap
        // is twice the slowest tick so a late tick at 4 Hz loses no time
        const dt = Math.max(0, Math.min((now - _last) / 1000, 0.5));
        _last = now;
        _env.hunger = hunger;
        _env.dirt = dirt;
        const st = _st();
        Mood.step(st, dt, _env);
        const w = st.w;
        let best = 0;
        for (let i = 1; i < w.length; i++)
            if (w[i] > w[best])
                best = i;
        _mood = best;
        _intensity = w[best];
        _gx = st.gx;
        _gy = st.gy;
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
