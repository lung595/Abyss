.pragma library
.import "Alerts.js" as Alerts

// How the events of one Alerts.step call become toasts: at most one for the
// "down" events and one for the "back" events, so a whole mesh dropping at
// once raises two toasts, never a burst. Pure, tested with gjs in tests/.
// Kept apart from Alerts.js, which is approved and only changes by its own story.

// Names listed in the details before "+k more"
const MAX_LISTED = 3;

function _clean(name) {
    // Names come from outside: no dash character may reach the screen
    return String(name === undefined || name === null ? "" : name).replace(/[–—]/g, "-");
}

function _sentence(kind, names, event) {
    if (names.length === 1)
        return Alerts.message({ "kind": kind, "duration": event.duration }, names[0]);
    if (names.length === 2)
        return names[0] + " and " + names[1] + (kind === "down" ? " are offline." : " are back.");
    return names.length + " favourites " + (kind === "down" ? "are offline." : "are back.");
}

function _details(kind, items) {
    if (items.length === 1)
        return "";
    const part = i => kind === "back" ? i.name + " " + Alerts.formatDuration(i.event.duration) : i.name;
    const shown = items.slice(0, items.length === 2 ? 2 : MAX_LISTED).map(part);
    if (items.length > MAX_LISTED)
        shown.push("+" + (items.length - MAX_LISTED) + " more");
    return shown.join(" · ");
}

// events: the list Alerts.step returned; nameOf(id) gives a device's name.
// Returns [{ title, details }], "down" first; details is "" for a single device.
function toasts(events, nameOf) {
    const out = [];
    ["down", "back"].forEach(kind => {
        const items = (events || []).filter(e => e && e.kind === kind).map(e => ({
                    "name": _clean(nameOf(e.id)),
                    "event": e
                }));
        if (!items.length)
            return;
        const names = items.map(i => i.name);
        out.push({
            "title": _sentence(kind, items.length === 1 ? [names[0]] : names, items[0].event),
            "details": _details(kind, items)
        });
    });
    return out;
}
