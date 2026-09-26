import QtQuick
import qs.Common
import qs.Widgets

// A small label pill floating in the water: a name, then one or two lines of
// figures. Sized by its text.
Rectangle {
    id: chip

    property string title: ""
    property string sub: ""
    property string third: ""
    // Tiny caps line above the pill ("TOP CONSUMER")
    property string caption: ""
    property color ink: "white"
    property color subInk: Qt.rgba(ink.r, ink.g, ink.b, 0.7)
    property color captionInk: ink
    property int titleSize: 12

    radius: 8
    color: Qt.rgba(0.02, 0.03, 0.07, 0.66)
    width: Math.max(t1.implicitWidth, t2.visible ? t2.implicitWidth : 0, t3.visible ? t3.implicitWidth : 0) + 16
    height: col.implicitHeight + 8

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            id: t1
            anchors.horizontalCenter: parent.horizontalCenter
            text: chip.title
            wrapMode: Text.NoWrap
            font.pixelSize: chip.titleSize
            font.weight: Font.Bold
            color: chip.ink
        }
        StyledText {
            id: t2
            visible: chip.sub !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: chip.sub
            wrapMode: Text.NoWrap
            font.pixelSize: 10
            font.family: Theme.monoFontFamily
            color: chip.subInk
        }
        StyledText {
            id: t3
            visible: chip.third !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: chip.third
            wrapMode: Text.NoWrap
            font.pixelSize: 10
            font.family: Theme.monoFontFamily
            color: chip.subInk
        }
    }

    StyledText {
        visible: chip.caption !== ""
        anchors.bottom: parent.top
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        text: chip.caption
        wrapMode: Text.NoWrap
        font.pixelSize: 8
        font.weight: Font.Black
        font.letterSpacing: 0.8
        color: chip.captionInk
    }
}
