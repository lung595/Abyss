import QtQuick
import QtQuick.Window
import "../../app/views"

// The app window with fictitious state, left open (no capture, no arguments
// needed): the scene `outils/essai.sh` opens for a safe try of a commit.
Window {
    visible: true
    width: 1280
    height: 800
    title: "Abyss (preview, fictitious data)"

    AppFrame {
        anchors.fill: parent
        netbirdState: "connected"
    }
}
