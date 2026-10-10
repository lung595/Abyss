import QtQuick
import QtQuick.Window
import "../../app/views"

// The app window content with fictitious state, saved as a PNG:
//   scripts/preview/app.sh <dark|light> <station> <out.png> [state]
Window {
    visible: true
    width: 1280
    height: 800

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
