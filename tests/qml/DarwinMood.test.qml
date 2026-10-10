import QtQuick
import "../../components"

// DarwinMood: the timer runs only while active (and slows down on battery or
// with Reduce motion), and each input reaches the expected mood. The mood
// indexes are Mood.js: 0 calm, 1 curious, 2 scared, 3 joy, 4 sleepy.
// Run: tests/qml/qmltest.py tests/qml/DarwinMood.test.qml
Item {
    id: test

    property int fails: 0
    property int count: 0
    property int stage: 0
    readonly property var up: [
        {
            "id": "a",
            "online": true
        },
        {
            "id": "b",
            "online": true
        }
    ]

    function check(name, cond, detail) {
        count++;
        if (cond) {
            console.log("✓ " + name);
        } else {
            fails++;
            console.log("FAIL " + name + (detail !== undefined ? "\n  got: " + JSON.stringify(detail) : ""));
        }
    }

    DarwinMood {
        id: m
        bounds: ({
                "l": 0,
                "r": 400,
                "top": 0,
                "bottom": 300
            })
        hides: [
            {
                "x": 20,
                "y": 280
            },
            {
                "x": 380,
                "y": 280
            }
        ]
    }

    // Lets the timer run for ms, then calls next
    function after(ms, next) {
        wait.interval = ms;
        wait.next = next;
        wait.restart();
    }

    Timer {
        id: wait
        property var next
        onTriggered: next()
    }

    function run() {
        if (stage === 0) {
            check("inactive: no timer", !m.ticking);
            m.peers = up;
            m.relay(100, 100);
            m.active = true;
            check("active: timer runs", m.ticking);
            check("30 Hz by default", m.tickInterval === 33);
            m.onBattery = true;
            check("battery: slower", m.tickInterval === 66);
            m.reduceMotion = true;
            check("reduce motion: slowest", m.tickInterval === 250);
            m.reduceMotion = false;
            m.onBattery = false;
            // Weights rise over time: wait until the new mood outweighs calm
            after(1000, run);
        } else if (stage === 1) {
            check("relay blink makes him curious", m.mood === 1, m.mood);
            m.peers = [up[0],
                {
                    "id": "b",
                    "online": false
                }
            ];
            after(700, run);
        } else if (stage === 2) {
            check("device down scares him", m.mood === 2, m.mood);
            check("intensity rises with the fright", m.intensity > 0.3, m.intensity);
            m.active = false;
            check("inactive again: timer stopped", !m.ticking);
            const frozen = m.intensity;
            after(200, run);
            test._frozen = frozen;
        } else if (stage === 3) {
            check("stopped timer: nothing moves", m.intensity === test._frozen, m.intensity);
            finish();
        }
        stage++;
    }
    property real _frozen: 0

    function finish() {
        console.log(count + " checks, " + fails + " failed");
        Qt.exit(fails ? 1 : 0);
    }

    Component.onCompleted: {
        // The first device list only seeds: no event before it
        m.peers = [up[0]];
        run();
    }
}
