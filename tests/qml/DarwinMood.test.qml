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

    Component {
        id: fresh
        DarwinMood {
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
    }

    // One fresh component per case: setup(m) runs while active, then the mood
    // is read after the weights had time to rise. Indexes: 1 curious, 2 scared,
    // 3 joy, 4 sleepy
    readonly property var cases: [
        {
            "name": "relay blink makes him curious",
            "setup": m => m.relay(100, 100),
            "mood": 1
        },
        {
            "name": "device joining makes him curious",
            "setup": m => {
                m.peers = up.concat([
                    {
                        "id": "c",
                        "online": true
                    }
                ]);
            },
            "mood": 1
        },
        {
            "name": "send started makes him curious",
            "setup": m => m.send("started", 50, 60),
            "mood": 1
        },
        {
            "name": "send succeeded makes him joyful",
            "setup": m => m.send("succeeded"),
            "mood": 3
        },
        {
            "name": "send failed scares him",
            "setup": m => m.send("failed"),
            "mood": 2
        },
        {
            "name": "click makes him joyful",
            "setup": m => m.click(100, 100),
            "mood": 3
        },
        {
            "name": "device down scares him",
            "setup": m => {
                m.peers = up;
                m.peers = [up[0],
                    {
                        "id": "b",
                        "online": false
                    }
                ];
            },
            "mood": 2
        },
        {
            "name": "empty list then refill stays calm",
            "setup": m => {
                m.peers = [];
                m.peers = up;
            },
            "mood": 0
        },
        {
            "name": "events while inactive are dropped",
            "setup": m => {
                m.active = false;
                m.relay(1, 1);
                m.send("failed");
                m.active = true;
            },
            "mood": 0
        },
        {
            "name": "bounds change keeps the mood",
            "setup": m => {
                m.send("failed");
                m.bounds = {
                    "l": 0,
                    "r": 800,
                    "top": 0,
                    "bottom": 600
                };
            },
            "mood": 2
        }
    ]
    property var cur: null

    function runCase(i) {
        if (i >= cases.length)
            return lifecycle();
        cur = fresh.createObject(test, {
            "active": true
        });
        cur.peers = up;
        cases[i].setup(cur);
        after(700, () => {
            check(cases[i].name, cur.mood === cases[i].mood, cur.mood);
            cur.destroy();
            runCase(i + 1);
        });
    }

    // The gaze follows the lamp-free default until the pointer moves
    function lifecycle() {
        const m = fresh.createObject(test);
        check("inactive: no timer", !m.ticking);
        m.active = true;
        check("active: timer runs", m.ticking);
        check("30 Hz by default", m.tickInterval === 33);
        m.onBattery = true;
        check("battery: slower", m.tickInterval === 66);
        m.reduceMotion = true;
        check("reduce motion: slowest", m.tickInterval === 250);
        m.reduceMotion = false;
        m.onBattery = false;
        m.pointerMoved(10, 20);
        m.lampMoved(300, 200);
        m.send("failed");
        after(500, () => {
            check("gaze moves toward the pointer", m.gazeX !== 0 || m.gazeY !== 0, [m.gazeX, m.gazeY]);
            m.active = false;
            check("inactive again: timer stopped", !m.ticking);
            const frozen = m.intensity;
            after(200, () => {
                check("stopped timer: nothing moves", m.intensity === frozen, m.intensity);
                finish();
            });
        });
    }

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

    function finish() {
        console.log(count + " checks, " + fails + " failed");
        Qt.exit(fails ? 1 : 0);
    }

    Component.onCompleted: {
        runCase(0);
    }
}
