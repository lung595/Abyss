import QtQuick
import QtQuick.Window
import qs.Common
import qs.Services
import "../../components"

// The small deep with 15 caves (some names long), left open and resizable:
// the scene `outils/essai.sh Abyss <commit> caves-hold.qml` opens to try the
// squeezed cave row. Fictitious data only; nothing is saved.
Window {
    visible: true
    width: 580
    height: 480
    title: "Abyss caves (preview, fictitious data)"
    color: "#141218"

    DemoSource {
        id: demo
        Component.onCompleted: networks = [...Array(15).keys()].map(i => ({ "id": ["lab", "office-lan", "backup-vault", "media", "printers", "cameras"][i % 6] + (i < 6 ? "" : "-" + i), "cidr": "10.20." + i + ".0/24", "via": "", "on": i % 3 === 0 }))
    }

    AbyssScene {
        markLab: false
        anchors.fill: parent
        interacting: true
        source: demo
    }
}
