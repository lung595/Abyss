import QtQuick
import QtQuick.Window

// Bench scene for the send engine (NAK-222), run by send.sh through the QML
// test harness (Quickshell.Io's Process played by QProcess, scp is
// tests/qml/fake-scp). It sends bench-data/item again and again, each send
// as soon as the last one ends: a worst case for the engine's own cost
// (du, a child process per step, the runner made and dropped each time).
// The runner is made from its path, so on a revision without it the scene
// just idles: an A/B against such a base gives the cost of sending.
Window {
    id: scene

    readonly property string item: Qt.resolvedUrl("bench-data/item").toString().replace("file://", "")
    property var runner: null
    property int sends: 0

    width: 64
    height: 64
    visible: true

    function next() {
        scene.runner.send("bench.mesh", ({}), [scene.item], "", "Bench");
    }

    Component.onCompleted: {
        const c = Qt.createComponent("../../components/SendRunner.qml");
        if (c.status !== Component.Ready)
            return;
        scene.runner = c.createObject(scene);
        scene.runner.finished.connect((ok, text) => {
            scene.sends++;
            if (!ok)
                console.warn("send failed:", text);
            if (scene.sends % 10 === 0)
                console.warn("sends:", scene.sends);
        });
        pace.start();
    }

    Timer {
        id: pace
        interval: 1000
        repeat: true
        onTriggered: scene.next()
    }
}
