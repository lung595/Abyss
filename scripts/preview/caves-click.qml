import QtQuick
import QtQuick.Window
import QtTest
import qs.Common
import qs.Services
import "../../components"

// Offscreen click test of the squeezed cave row: a real mouse (move, click)
// on the middle of every cave's name must hover and switch that cave and no
// other. Prints "PASS"/"FAIL" lines and exits with the failure count.
//   qml-qt6 -I imports caves-click.qml -- <width> <height>
Window {
    id: win
    readonly property var args: Qt.application.arguments
    width: parseInt(args[args.length - 2])
    height: parseInt(args[args.length - 1])
    visible: true
    color: "#141218"

    DemoSource {
        id: demo
        Component.onCompleted: networks = [...Array(15).keys()].map(i => ({ "id": ["lab", "office-lan", "backup-vault", "media", "printers", "cameras"][i % 6] + (i < 6 ? "" : "-" + i), "cidr": "10.20." + i + ".0/24", "via": "", "on": false }))
    }
    AbyssScene {
        id: scene
        markLab: false
        anchors.fill: parent
        interacting: true
        source: demo
    }
    TestCase {
        id: mouse
        when: false
        optional: true
    }
    function caves(o, acc) {
        if (o.net !== undefined && o.toggled !== undefined)
            acc.push(o);
        (o.children || []).forEach(c => caves(c, acc));
        return acc;
    }
    Timer {
        interval: 1500
        running: true
        onTriggered: {
            const list = win.caves(scene, []).sort((a, b) => a.index - b.index);
            let fails = 0;
            console.error("size " + win.width + "x" + win.height + ", caves " + list.length);
            list.forEach(cave => {
                // The name box: where the user aims at the label of this cave
                const label = cave.children.find(c => c.title !== undefined);
                const p = label.mapToItem(scene, label.width / 2, label.height / 2);
                const before = demo.networks.map(n => n.on);
                mouse.mouseMove(scene, p.x, p.y);
                mouse.mouseClick(scene, p.x, p.y);
                const changed = demo.networks.map((n, i) => n.on !== before[i] ? i : -1).filter(i => i >= 0);
                const ok = changed.length === 1 && changed[0] === cave.index;
                if (!ok)
                    fails++;
                console.error((ok ? "PASS" : "FAIL") + " name of cave " + cave.index + " switched " + JSON.stringify(changed));
            });
            Qt.exit(fails);
        }
    }
}
