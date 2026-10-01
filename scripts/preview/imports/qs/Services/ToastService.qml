pragma Singleton
import QtQuick
QtObject {
    function showInfo(m) { console.warn("toast", m); }
    function showWarning(m, d, c) { console.warn("toast!", m, d || "", c || ""); }
}
