pragma Singleton
import QtQuick
// DMS's default purple theme (the registry thumbnail uses it)
QtObject {
    property bool isLightMode: false
    property color primary: isLightMode ? "#6750A4" : "#D0BCFF"
    property color primaryText: isLightMode ? "#FFFFFF" : "#381E72"
    property color secondary: isLightMode ? "#625B71" : "#CCC2DC"
    property color tertiary: isLightMode ? "#7D5260" : "#EFB8C8"
    property color success: isLightMode ? "#2E7D4F" : "#8BD8A6"
    property color warning: isLightMode ? "#9A5B00" : "#FFB86B"
    property color error: isLightMode ? "#B3261E" : "#F2B8B5"
    property color errorText: isLightMode ? "#FFFFFF" : "#601410"
    property color surfaceText: isLightMode ? "#1D1B20" : "#E6E0E9"
    property color surface: isLightMode ? "#FEF7FF" : "#141218"
    property color surfaceContainer: isLightMode ? "#F3EDF7" : "#211F26"
    property color surfaceContainerHigh: isLightMode ? "#ECE6F0" : "#2B2930"
    property color surfaceContainerHighest: isLightMode ? "#E6E0E9" : "#36343B"
    property color outline: isLightMode ? "#79747E" : "#938F99"
    property color surfaceVariantText: isLightMode ? "#49454F" : "#CAC4D0"
    property string fontFamily: "Inter Variable"
    property string monoFontFamily: "monospace"
    property real fontSizeSmall: 12
    property real fontSizeMedium: 14
    property real fontSizeLarge: 16
    property real fontSizeXLarge: 20
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    property real spacingL: 16
    property real spacingXL: 24
    property real cornerRadius: 12
    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
