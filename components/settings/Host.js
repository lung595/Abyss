.pragma library

// The PluginSettings item above a row: it owns loadValue()/saveValue(). DMS's
// own rows find it the same way; ours cannot import DMS's helper from here.
function find(item) {
    while (item) {
        if (item.saveValue !== undefined && item.loadValue !== undefined)
            return item;
        item = item.parent;
    }
    return null;
}
