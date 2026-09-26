pragma Singleton
import QtQuick
// DMS's default purple theme (the registry thumbnail uses it)
QtObject {
    property bool isLightMode: false
    property color primary: "#D0BCFF"
    property color primaryText: "#381E72"
    property color secondary: "#CCC2DC"
    property color tertiary: "#EFB8C8"
    property color success: "#8BD8A6"
    property color warning: "#FFB86B"
    property color error: "#F2B8B5"
    property color errorText: "#601410"
    property color surfaceText: "#E6E0E9"
    property color surfaceVariantText: "#CAC4D0"
    property string fontFamily: "Inter Variable"
    property string monoFontFamily: "monospace"
    property real fontSizeSmall: 12
    property real fontSizeMedium: 14
    property real fontSizeLarge: 16
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    property real spacingL: 16
    property real spacingXL: 24
    property real cornerRadius: 12
    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
