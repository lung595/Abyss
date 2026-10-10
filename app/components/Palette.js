.pragma library

// The Abyss colours, the one place a hex value may appear in the app. Pure:
// no global, no side effect. Theme.qml maps these roles onto the DMS Theme API.
// Primitives and roles come from the approved deep-sea design (D396).

const DARK = {
    surface: "#02040b",
    surfaceContainerLowest: "#000208",
    surfaceContainerLow: "#070a14",
    surfaceContainer: "#0c1020",
    surfaceContainerHigh: "#131a2e",
    surfaceContainerHighest: "#1b2440",
    onSurface: "#e8ecf6",
    onSurfaceVariant: "#a3acc0",
    outline: "#58648a",
    primary: "#6fe3ff",
    onPrimary: "#04202c",
    secondary: "#ffc46b",
    onSecondary: "#2d1b00",
    tertiary: "#ff9ad5",
    success: "#7ee2a8",
    warning: "#ffb35c",
    error: "#ff7b86",
    data4: "#b7a6ff"
};

const LIGHT = {
    surface: "#f3f7fb",
    surfaceContainerLowest: "#ffffff",
    surfaceContainerLow: "#e9f0f6",
    surfaceContainer: "#dfe8f0",
    surfaceContainerHigh: "#d2dde8",
    surfaceContainerHighest: "#c4d2df",
    onSurface: "#0e1a2b",
    onSurfaceVariant: "#475870",
    outline: "#6f8097",
    primary: "#0b6f8f",
    onPrimary: "#ffffff",
    secondary: "#7a4f00",
    onSecondary: "#ffffff",
    tertiary: "#a8336f",
    success: "#1e7a4a",
    warning: "#8a5600",
    error: "#b3263a",
    data4: "#5b4bb8"
};

// The role set of one scheme. outlineStrong is the border of interactive
// parts and always equals onSurfaceVariant (D396), so it cannot drift.
function colors(light) {
    const base = light ? LIGHT : DARK;
    return Object.assign({}, base, { outlineStrong: base.onSurfaceVariant });
}
