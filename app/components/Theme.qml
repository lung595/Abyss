pragma Singleton

import QtQuick
import Quickshell
import "Palette.js" as Palette

// The app's own Theme, with the API of the DMS one so the shared components
// render here unchanged. Colours come only from Palette.js. DMS is never read
// (Q110): no event-driven, read-only source exists, so the Abyss palette applies.
QtObject {
    id: root

    // Follows the system preference live (the style hints signal), no polling.
    // ABYSS_SCHEME=light|dark overrides it, for offscreen captures.
    readonly property string _forced: Quickshell.env("ABYSS_SCHEME") ?? ""
    readonly property bool isLightMode: _forced === "light" || (_forced !== "dark" && Application.styleHints.colorScheme === Qt.ColorScheme.Light)
    readonly property bool reduceMotion: (Quickshell.env("ABYSS_REDUCE_MOTION") ?? "") !== ""
    readonly property var _c: Palette.colors(isLightMode)

    readonly property color surface: _c.surface
    readonly property color surfaceContainerLowest: _c.surfaceContainerLowest
    readonly property color surfaceContainerLow: _c.surfaceContainerLow
    readonly property color surfaceContainer: _c.surfaceContainer
    readonly property color surfaceContainerHigh: _c.surfaceContainerHigh
    readonly property color surfaceContainerHighest: _c.surfaceContainerHighest
    // No on* names: QML reads a property called onXxx as a signal handler and it
    // resolves to black, so the DMS *Text names are the only text roles.
    readonly property color secondaryText: _c.onSecondary
    readonly property color surfaceText: _c.onSurface
    readonly property color surfaceVariantText: _c.onSurfaceVariant
    readonly property color outline: _c.outline
    readonly property color outlineStrong: _c.outlineStrong
    readonly property color primary: _c.primary
    readonly property color primaryText: _c.onPrimary
    readonly property color secondary: _c.secondary
    readonly property color tertiary: _c.tertiary
    readonly property color success: _c.success
    readonly property color warning: _c.warning
    readonly property color error: _c.error

    // 4 px grid
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int spacingXL: 24

    // Type scale 11 / 13 / 15 / 22
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeXLarge: 22
    readonly property string fontFamily: "Noto Sans"
    readonly property string monoFontFamily: "Noto Sans Mono"

    // Control, card, panel
    readonly property int cornerRadius: 12
    readonly property int cornerRadiusLarge: 16
    readonly property int cornerRadiusXL: 20

    // Brief transitions only: chips, card, panel in
    readonly property int shortDuration: reduceMotion ? 0 : 100
    readonly property int mediumDuration: reduceMotion ? 0 : 150
    readonly property int longDuration: reduceMotion ? 0 : 200

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }
}
