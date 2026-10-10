import QtQuick
import qs.Common
import qs.Widgets
import "Host.js" as Host

// A switch row for one saved setting. Unlike DMS's ToggleSetting the words get
// the width the switch leaves and wrap, so a narrow page never draws a title
// under the switch. The saved key and value are the same as before.
Item {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    property bool defaultValue: false
    property bool value: defaultValue

    readonly property int gap: Theme.spacingM

    width: parent ? parent.width : 0
    implicitHeight: Math.max(words.implicitHeight, track.height)
    height: implicitHeight
    activeFocusOnTab: true

    function load() {
        const s = Host.find(root.parent);
        if (s && s.pluginService)
            value = s.loadValue(settingKey, defaultValue);
    }
    // Only a gesture saves, so opening the page writes nothing
    function toggle() {
        value = !value;
        const s = Host.find(root.parent);
        if (s)
            s.saveValue(settingKey, value);
    }

    Component.onCompleted: Qt.callLater(load)
    Keys.onSpacePressed: toggle()
    Keys.onReturnPressed: toggle()

    Column {
        id: words
        objectName: "words"
        anchors.left: parent.left
        anchors.right: track.left
        anchors.rightMargin: root.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXS

        StyledText {
            objectName: "title"
            width: parent.width
            text: root.label
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.surfaceText
        }
        StyledText {
            objectName: "description"
            width: parent.width
            visible: root.description !== ""
            text: root.description
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }

    Rectangle {
        id: track
        objectName: "control"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 30
        radius: 15
        color: root.value ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.primary
        Rectangle {
            width: 22
            height: 22
            radius: 11
            y: 4
            x: root.value ? 26 : 4
            color: root.value ? Theme.primaryText : Theme.outline
        }
    }
    TapHandler {
        onTapped: {
            root.forceActiveFocus();
            root.toggle();
        }
    }
}
