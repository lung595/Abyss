import QtQuick
import QtQuick.Window
import "../../app/views"

// The app window content with fictitious state, saved as a PNG:
//   scripts/preview/app.sh <dark|light> <station> <out.png> [compact]
Window {
    visible: true
    // "compact" renders the 900 x 600 minimum
    readonly property bool compact: Qt.application.arguments[Qt.application.arguments.length - 4] === "compact"

    width: compact ? 900 : 1280
    height: compact ? 600 : 800

    AppFrame {
        id: frame

        anchors.fill: parent
        station: Qt.application.arguments[Qt.application.arguments.length - 3]
        netbirdState: "connected"
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
