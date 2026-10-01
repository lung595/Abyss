import QtQuick
import qs.Common
import qs.Widgets

// "Add a device": a sheet over the deep, opened by the + in the top bar,
// the search ("add") or the jellyfish's menu. Two doors: this computer
// (a setup key) or a phone (scan, install, sign in). It watches the mesh
// meanwhile and celebrates the new device the moment it shows up.
Rectangle {
    id: sheet
    objectName: "addSheet"

    property var scene
    property bool open: false
    signal closed

    // "choose", "phone" or "computer"
    property string step: "choose"
    // A QR code shown big (its text), "" otherwise
    property string zoomed: ""
    property string zoomedLabel: ""
    // Peer ids when the sheet opened: a new one is the device just added
    property var known: ({})
    readonly property var newPeer: open ? scene.view.peers.find(p => !known[p.id]) || null : null
    // This computer: a join was sent; done once connected after it
    property bool joining: false
    readonly property bool joined: joining && scene.connected
    property string joinError: ""
    // Android: the Termux steps unfolded
    property bool termux: false

    readonly property string playUrl: "https://play.google.com/store/apps/details?id=io.netbird.client"
    readonly property string appleUrl: "https://apps.apple.com/app/netbird-p2p-vpn/id6469329339"
    readonly property string termuxUrl: "https://f-droid.org/packages/com.termux/"
    readonly property string termuxCmd: "pkg install openssh && passwd && sshd"
    readonly property string server: scene.view.me.server || ""
    readonly property string keysUrl: (scene.view.me.console || "https://app.netbird.io") + "/setup-keys"
    readonly property bool wide: width >= 520
    readonly property color ink: scene.ink
    readonly property color dim: scene.inkDim
    readonly property color accent: scene.sunColor

    onOpenChanged: {
        if (!open)
            return;
        const k = {};
        scene.view.peers.forEach(p => k[p.id] = true);
        known = k;
        step = "choose";
        zoomed = "";
        joining = false;
        joinError = "";
        termux = false;
    }

    visible: opacity > 0.01
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.96
    Behavior on opacity {
        NumberAnimation {
            duration: sheet.scene.reduceMotion ? 0 : 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: sheet.scene.reduceMotion ? 0 : 260
            easing.type: Easing.OutBack
        }
    }
    radius: 18
    color: Qt.rgba(scene.abyss.r, scene.abyss.g, scene.abyss.b, 0.97)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.35)

    // Keep clicks and wheels here
    MouseArea {
        anchors.fill: parent
        onWheel: wheel => wheel.accepted = true
    }

    // --- Header: back, title, close ------------------------------------------
    Item {
        id: head
        width: parent.width
        height: 48
        ActionChip {
            visible: sheet.step !== "choose"
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 30
            icon: "arrow_back"
            ink: sheet.ink
            tip: "Back"
            onClicked: sheet.step = "choose"
        }
        Row {
            anchors.centerIn: parent
            spacing: 8
            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: sheet.step === "phone" ? "smartphone" : sheet.step === "computer" ? "laptop" : "add_circle"
                size: 20
                color: sheet.accent
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: sheet.step === "phone" ? "Add your phone" : sheet.step === "computer" ? "Add this computer" : "Add a device"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: sheet.ink
            }
        }
        ActionChip {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 30
            icon: "close"
            ink: sheet.ink
            tip: "Close (Esc)"
            onClicked: sheet.closed()
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: head.height
        anchors.margins: 14
        contentHeight: body.implicitHeight + 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: flick.width
            spacing: 12

            // ===== Choose ==================================================
            Column {
                visible: sheet.step === "choose"
                width: parent.width
                spacing: 12
                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "What do you want to add?"
                    font.pixelSize: 13
                    color: sheet.dim
                }
                Grid {
                    width: parent.width
                    columns: sheet.wide ? 2 : 1
                    spacing: 10
                    Door {
                        icon: "smartphone"
                        title: "My phone or tablet"
                        sub: "Scan a code, install NetBird, sign in. About a minute"
                        onClicked: sheet.step = "phone"
                    }
                    Door {
                        icon: "laptop"
                        title: "This computer"
                        sub: sheet.scene.connected ? "Already in the mesh: join another one with a setup key" : "Paste a setup key and you are in"
                        onClicked: sheet.step = "computer"
                    }
                }
                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Another computer? Install NetBird on it and sign in with the same account: it swims in here by itself."
                    font.pixelSize: 11
                    color: sheet.dim
                    wrapMode: Text.WordWrap
                }
            }

            // ===== Phone ===================================================
            Column {
                visible: sheet.step === "phone"
                width: parent.width
                spacing: 10

                // Where you are: 1 → 2 → 3, the last one lit when it arrives
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Repeater {
                        model: ["Install", "Sign in", "Here!"]
                        Row {
                            required property string modelData
                            required property int index
                            spacing: 6
                            Rectangle {
                                readonly property bool lit: index < 2 || !!sheet.newPeer
                                width: pillText.implicitWidth + 30
                                height: 24
                                radius: 12
                                color: lit && index === 2 ? sheet.accent : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, lit ? 0.12 : 0.05)
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    StyledText {
                                        text: index + 1
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: index === 2 && sheet.newPeer ? sheet.scene.abyss : sheet.accent
                                    }
                                    StyledText {
                                        id: pillText
                                        text: modelData
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: index === 2 && sheet.newPeer ? sheet.scene.abyss : sheet.ink
                                    }
                                }
                            }
                            StyledText {
                                visible: index < 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: "→"
                                font.pixelSize: 12
                                color: sheet.dim
                            }
                        }
                    }
                }

                Grid {
                    id: steps
                    width: parent.width
                    columns: sheet.wide ? 3 : 1
                    spacing: 8
                    readonly property real cellW: sheet.wide ? (width - spacing * 2) / 3 : width
                    readonly property real cellH: sheet.wide ? 200 : -1

                    // 1. Install
                    Step {
                        n: 1
                        title: "Install NetBird"
                        sub: "Scan with your phone's camera"
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10
                            Repeater {
                                model: [["Android", "android", sheet.playUrl], ["iPhone", "phone_iphone", sheet.appleUrl]]
                                Column {
                                    required property var modelData
                                    spacing: 4
                                    QrView {
                                        width: 74
                                        height: 74
                                        text: modelData[2]
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: sheet.zoom(modelData[2], "NetBird for " + modelData[0])
                                        }
                                    }
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 3
                                        DankIcon {
                                            name: modelData[1]
                                            size: 13
                                            color: sheet.ink
                                        }
                                        StyledText {
                                            text: modelData[0]
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: sheet.ink
                                        }
                                    }
                                }
                            }
                        }
                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Tap a code to enlarge it"
                            font.pixelSize: 10
                            color: sheet.dim
                        }
                    }

                    // 2. Sign in
                    Step {
                        n: 2
                        title: "Sign in"
                        sub: sheet.server ? "Your mesh runs on your own server: in the app, change the server first" : "Open the app, tap Connect, sign in with the same account as this computer"
                        Row {
                            visible: !!sheet.server
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            QrView {
                                width: 64
                                height: 64
                                text: sheet.server
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sheet.zoom(sheet.server, "Your server's address")
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: steps.cellW - 100
                                spacing: 4
                                StyledText {
                                    width: parent.width
                                    text: sheet.server
                                    wrapMode: Text.NoWrap
                                    font.pixelSize: 10
                                    font.family: Theme.monoFontFamily
                                    color: sheet.ink
                                    elide: Text.ElideMiddle
                                }
                                ActionChip {
                                    height: 22
                                    icon: "content_copy"
                                    text: "Copy"
                                    ink: sheet.ink
                                    onClicked: sheet.scene.copy(sheet.server, "Server address")
                                }
                            }
                        }
                        Column {
                            visible: !sheet.server
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            Repeater {
                                model: [["power_settings_new", "Tap Connect"], ["account_circle", "Same account as here"], ["check_circle", "Allow the VPN"]]
                                Row {
                                    required property var modelData
                                    spacing: 6
                                    DankIcon {
                                        name: modelData[0]
                                        size: 15
                                        color: sheet.accent
                                    }
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData[1]
                                        font.pixelSize: 11
                                        color: sheet.ink
                                    }
                                }
                            }
                        }
                    }

                    // 3. It appears here: waiting, then celebrated
                    Step {
                        n: 3
                        title: sheet.newPeer ? sheet.newPeer.name + " is in!" : "It shows up here"
                        sub: sheet.newPeer ? "It swims in the deep from now on" : "Waiting for a new device…"
                        lit: !!sheet.newPeer
                        Item {
                            width: parent.width
                            height: 70
                            // Sonar: rings going out while it waits
                            Repeater {
                                model: sheet.newPeer ? 0 : 3
                                Rectangle {
                                    id: ring
                                    required property int index
                                    anchors.centerIn: parent
                                    width: 20
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: sheet.accent
                                    SequentialAnimation on width {
                                        running: sheet.open && sheet.step === "phone" && !sheet.scene.reduceMotion
                                        loops: Animation.Infinite
                                        PauseAnimation {
                                            duration: ring.index * 600
                                        }
                                        NumberAnimation {
                                            from: 14
                                            to: 70
                                            duration: 1800
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    opacity: 1 - (width - 14) / 60
                                }
                            }
                            DankIcon {
                                anchors.centerIn: parent
                                name: sheet.newPeer ? "celebration" : "smartphone"
                                size: sheet.newPeer ? 34 : 22
                                color: sheet.accent
                            }
                            Bubbles {
                                anchors.fill: parent
                                tint: sheet.accent
                                running: !!sheet.newPeer && sheet.scene.prefs.celebrate && !sheet.scene.reduceMotion
                            }
                        }
                        ActionChip {
                            visible: !!sheet.newPeer
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 28
                            primary: true
                            accent: sheet.accent
                            icon: "open_in_full"
                            text: "Open its card"
                            ink: sheet.ink
                            onClicked: {
                                const id = sheet.newPeer.id;
                                sheet.closed();
                                sheet.scene.openCard(id);
                            }
                        }
                    }
                }

                // Android: its terminal and files from here, with Termux
                Rectangle {
                    width: parent.width
                    height: termuxCol.implicitHeight + 20
                    radius: 12
                    color: Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.1)
                    Column {
                        id: termuxCol
                        x: 12
                        y: 10
                        width: parent.width - 24
                        spacing: 8
                        Item {
                            width: parent.width
                            height: 22
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                DankIcon {
                                    name: "terminal"
                                    size: 16
                                    color: sheet.accent
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Bonus: open its terminal and files from here (Android)"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: sheet.ink
                                }
                            }
                            DankIcon {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                name: sheet.termux ? "expand_less" : "expand_more"
                                size: 18
                                color: sheet.dim
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sheet.termux = !sheet.termux
                            }
                        }
                        Row {
                            visible: sheet.termux
                            width: parent.width
                            spacing: 12
                            QrView {
                                width: 70
                                height: 70
                                text: sheet.termuxUrl
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sheet.zoom(sheet.termuxUrl, "Termux on F-Droid")
                                }
                            }
                            Column {
                                width: parent.width - 82
                                spacing: 6
                                StyledText {
                                    width: parent.width
                                    text: "1. Install Termux (scan the code: F-Droid)\n2. In Termux, run this once, and choose a password:"
                                    font.pixelSize: 11
                                    color: sheet.ink
                                    wrapMode: Text.WordWrap
                                }
                                Rectangle {
                                    width: parent.width
                                    height: 30
                                    radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.3)
                                    StyledText {
                                        x: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 50
                                        text: sheet.termuxCmd
                                        font.pixelSize: 11
                                        font.family: Theme.monoFontFamily
                                        color: sheet.accent
                                        elide: Text.ElideRight
                                    }
                                    ActionChip {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 24
                                        icon: "content_copy"
                                        tip: "Copy"
                                        ink: sheet.ink
                                        onClicked: sheet.scene.copy(sheet.termuxCmd, "Termux command")
                                    }
                                }
                                StyledText {
                                    width: parent.width
                                    text: "3. On its card here, tap \"Use 8022\": Terminal and Files then just work."
                                    font.pixelSize: 11
                                    color: sheet.ink
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            // ===== This computer ==========================================
            Column {
                visible: sheet.step === "computer"
                width: parent.width
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: compCol.implicitHeight + 28
                    radius: 14
                    color: Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.1)
                    Column {
                        id: compCol
                        x: 14
                        y: 14
                        width: parent.width - 28
                        spacing: 10
                        StyledText {
                            width: parent.width
                            text: "1. Get a setup key from your NetBird dashboard"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: sheet.ink
                        }
                        ActionChip {
                            height: 28
                            icon: "open_in_new"
                            text: "Open Setup Keys"
                            ink: sheet.ink
                            onClicked: sheet.scene.actions && sheet.scene.actions.openUrl(sheet.keysUrl)
                        }
                        StyledText {
                            width: parent.width
                            text: "2. Paste it here"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: sheet.ink
                        }
                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: 10
                            color: Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.08)
                            border.width: key.activeFocus ? 1.5 : 1
                            border.color: key.activeFocus ? sheet.accent : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.2)
                            TextInput {
                                id: key
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 13
                                font.family: Theme.monoFontFamily
                                color: sheet.ink
                                selectByMouse: true
                                clip: true
                                onAccepted: sheet.join()
                                Keys.onEscapePressed: sheet.closed()
                            }
                            StyledText {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: key.text === ""
                                text: "A1B2C3D4-E5F6-…"
                                font.pixelSize: 13
                                font.family: Theme.monoFontFamily
                                color: sheet.dim
                            }
                        }
                        // Self-hosted: the server's address, folded away by default
                        Row {
                            spacing: 8
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 5
                                anchors.verticalCenter: parent.verticalCenter
                                color: own.on ? sheet.accent : "transparent"
                                border.width: 1.5
                                border.color: own.on ? sheet.accent : sheet.dim
                                DankIcon {
                                    anchors.centerIn: parent
                                    visible: own.on
                                    name: "check"
                                    size: 14
                                    color: sheet.scene.abyss
                                }
                            }
                            StyledText {
                                id: own
                                property bool on: false
                                anchors.verticalCenter: parent.verticalCenter
                                text: "I host my own NetBird server"
                                font.pixelSize: 11
                                color: sheet.ink
                                TapHandler {
                                    onTapped: own.on = !own.on
                                }
                            }
                        }
                        Rectangle {
                            visible: own.on
                            width: parent.width
                            height: 34
                            radius: 10
                            color: Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.08)
                            border.width: 1
                            border.color: url.activeFocus ? sheet.accent : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.2)
                            TextInput {
                                id: url
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 12
                                font.family: Theme.monoFontFamily
                                color: sheet.ink
                                selectByMouse: true
                                clip: true
                                onAccepted: sheet.join()
                            }
                            StyledText {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: url.text === ""
                                text: "https://netbird.example.org"
                                font.pixelSize: 12
                                font.family: Theme.monoFontFamily
                                color: sheet.dim
                            }
                        }
                        Row {
                            spacing: 10
                            ActionChip {
                                height: 34
                                primary: true
                                accent: sheet.accent
                                icon: sheet.joined ? "check" : "login"
                                text: sheet.joined ? "You're in" : sheet.joining ? "Joining…" : "Join the mesh"
                                ink: sheet.ink
                                opacity: key.text.trim().length >= 8 || sheet.joining ? 1 : 0.5
                                onClicked: sheet.join()
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: text !== ""
                                text: sheet.joinError || (sheet.joined ? "The jellyfish is lit: welcome aboard" : sheet.joining ? "NetBird is setting things up…" : "")
                                font.pixelSize: 11
                                color: sheet.joinError ? Theme.error : sheet.accent
                            }
                        }
                    }
                }
                StyledText {
                    width: parent.width
                    text: "No key? Click the jellyfish instead: NetBird opens its sign-in page in your browser."
                    font.pixelSize: 11
                    color: sheet.dim
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // --- A QR code, big: the whole sheet, a click anywhere closes it ----------
    Rectangle {
        anchors.fill: parent
        radius: sheet.radius
        color: Qt.rgba(sheet.scene.abyss.r, sheet.scene.abyss.g, sheet.scene.abyss.b, 0.98)
        visible: opacity > 0.01
        opacity: sheet.zoomed !== "" ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: sheet.scene.reduceMotion ? 0 : 180
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sheet.zoomed = ""
        }
        Column {
            anchors.centerIn: parent
            spacing: 10
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: sheet.zoomedLabel
                font.pixelSize: 15
                font.weight: Font.Bold
                color: sheet.ink
            }
            QrView {
                id: big
                readonly property real side: Math.min(sheet.width - 60, sheet.height - 110)
                anchors.horizontalCenter: parent.horizontalCenter
                width: side
                height: side
                text: sheet.zoomed
                scale: sheet.zoomed !== "" ? 1 : 0.6
                Behavior on scale {
                    NumberAnimation {
                        duration: sheet.scene.reduceMotion ? 0 : 260
                        easing.type: Easing.OutBack
                    }
                }
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Point your phone's camera at it · click to close"
                font.pixelSize: 11
                color: sheet.dim
            }
        }
    }

    function zoom(text, label) {
        zoomedLabel = label;
        zoomed = text;
    }

    function join() {
        if (joining && !joinError)
            return;
        const src = scene.source;
        if (!src)
            return;
        joinError = "";
        if (key.text.trim().length < 8) {
            joinError = "Paste the whole key first";
            return;
        }
        const ok = src.join(key.text, own.on ? url.text : "", "");
        if (!ok) {
            joinError = own.on && url.text ? "That address must start with https://" : "That does not look like a setup key";
            return;
        }
        key.text = "";
        joining = true;
    }

    // --- Pieces ---------------------------------------------------------------

    // A big choice on the first screen
    component Door: Rectangle {
        id: door
        property string icon
        property string title
        property string sub
        signal clicked
        width: sheet.wide ? (body.width - 10) / 2 : body.width
        height: 132
        radius: 16
        color: doorArea.containsMouse ? Qt.rgba(sheet.accent.r, sheet.accent.g, sheet.accent.b, 0.14) : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.05)
        border.width: 1
        border.color: doorArea.containsMouse ? sheet.accent : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.12)
        scale: doorArea.pressed ? 0.98 : 1
        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 90
            }
        }
        Column {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 6
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 46
                height: 46
                radius: 23
                color: Qt.rgba(sheet.accent.r, sheet.accent.g, sheet.accent.b, 0.18)
                DankIcon {
                    anchors.centerIn: parent
                    name: door.icon
                    size: 24
                    color: sheet.accent
                }
            }
            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: door.title
                font.pixelSize: 14
                font.weight: Font.Bold
                color: sheet.ink
            }
            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: door.sub
                font.pixelSize: 11
                color: sheet.dim
                wrapMode: Text.WordWrap
            }
        }
        MouseArea {
            id: doorArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: door.clicked()
        }
    }

    // One numbered step of the phone's three
    component Step: Rectangle {
        id: st
        property int n
        property string title
        property string sub
        property bool lit: false
        default property alias content: stCol.data
        width: steps.cellW
        height: steps.cellH > 0 ? steps.cellH : stCol.implicitHeight + 24
        radius: 14
        color: lit ? Qt.rgba(sheet.accent.r, sheet.accent.g, sheet.accent.b, 0.14) : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.05)
        border.width: 1
        border.color: lit ? sheet.accent : Qt.rgba(sheet.ink.r, sheet.ink.g, sheet.ink.b, 0.1)
        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }
        Column {
            id: stCol
            x: 10
            y: 12
            width: parent.width - 20
            spacing: 8
            Row {
                spacing: 7
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: sheet.accent
                    StyledText {
                        anchors.centerIn: parent
                        text: st.n
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: sheet.scene.abyss
                    }
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: stCol.width - 27
                    text: st.title
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: sheet.ink
                    elide: Text.ElideRight
                }
            }
            StyledText {
                width: parent.width
                text: st.sub
                font.pixelSize: 11
                color: sheet.dim
                wrapMode: Text.WordWrap
            }
        }
    }
}
