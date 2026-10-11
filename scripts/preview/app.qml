import QtQuick
import QtQuick.Window
import "../../app/views"
import "../../app/components/SendQueue.js" as Queue

// The app window content with fictitious state, saved as a PNG:
//   scripts/preview/app.sh <dark|light> <station> <out.png> [compact] [state]
Window {
    id: root

    visible: true
    // "compact" renders the 900 x 600 minimum
    readonly property bool compact: Qt.application.arguments[Qt.application.arguments.length - 4] === "compact"

    // connected | stopped | missing | unknown, or "longname": an unknown device
    readonly property string scene: Qt.application.arguments[Qt.application.arguments.length - 5]

    width: compact ? 900 : 1280
    height: compact ? 600 : 800

    AppFrame {
        id: frame

        anchors.fill: parent
        station: Qt.application.arguments[Qt.application.arguments.length - 3]
        netbirdState: ["stopped", "missing", "unknown"].includes(root.scene) ? root.scene : "connected"
        device: root.scene === "longname" ? "workstation-with-a-very-long-device-name.netbird.cloud" : ""
        peers: root.scene === "longname" ? [] : [
            {
                id: "p1",
                name: "laptop-anna",
                fqdn: "laptop-anna.netbird.cloud",
                ip: "100.64.0.11",
                online: true
            },
            {
                id: "p2",
                name: "nas-box",
                fqdn: "nas-box.netbird.cloud",
                ip: "100.64.0.12",
                online: true
            },
            {
                id: "p3",
                name: "phone-tab",
                fqdn: "phone-tab.netbird.cloud",
                ip: "100.64.0.13",
                online: false
            }
        ]
    }

    // Send scenes with a filled queue (mockups 02-send, e3, e5): the state is
    // set on the view directly, so no program is started
    function fillSend() {
        const long = root.scene === "send-long";
        const names = long ? ["/x/quarterly-report-final-version-2-reviewed-by-everyone-and-signed-off.pdf", "/x/holiday-photos-from-the-long-weekend-in-the-mountains-2026.zip"] : ["/x/report.pdf", "/x/photos.zip", "/x/notes.txt"];
        let q = Queue.add(Queue.empty(), names, (long ? ["laptop-anna", "workstation-in-the-basement-lab-rack-07"] : ["laptop-anna", "nas-box"])).state;
        // 1: rsync with a meter, 2: done (stays until dismissed), 4: scp without
        // progress, 5: failed (goes to the history)
        q = Queue.progress(Queue.start(q, 1), 1, 0.42);
        q = Queue.finish(Queue.start(q, 2), 2, Date.now());
        q = Queue.start(q, 4);
        q = Queue.fail(Queue.start(q, 5), 5, "Connection refused", Date.now() - 300000);
        frame.sendView.rates = {
            "1": "3.1 MB/s"
        };
        frame.sendView.q = q;
        frame.sendView.chosen = ["laptop-anna"];
        if (root.scene === "send-refused")
            frame.sendView.say({
                "title": "nas-box refused the file",
                "advice": "Check that SSH is allowed on that device.",
                "guide": "https://example.invalid/guide"
            }, 5);
    }

    Timer {
        interval: 200
        running: root.scene.startsWith("send-")
        onTriggered: root.fillSend()
    }

    Timer {
        interval: 400
        running: true
        onTriggered: frame.grabToImage(r => {
            r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 2]);
            Qt.quit();
        })
    }
}
