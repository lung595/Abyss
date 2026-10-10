import QtQuick
import Quickshell
import Quickshell.Io
import "Store.js" as Store

// The Abyss settings shared by the widget and the app: one JSON file under
// $XDG_CONFIG_HOME/abyss. Event driven: the file is watched, nothing polls and
// no timer runs at rest. DMS files are only ever read, once, to carry the
// widget's settings over when this file does not exist yet.
Scope {
    id: root

    // The settings, always valid: defaults until the file is read
    property var values: Store.defaults()
    // True once the file (or the defaults) has been settled
    property bool ready: false

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/abyss"
    readonly property string path: dir + "/settings.json"
    // Where the widget's settings live in DMS (read only)
    readonly property string legacyPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/DankMaterialShell/plugin_settings.json"

    // Changes one value; `deferred` (a slider drag) waits for the gesture to
    // pause so a drag costs one write, not one per pixel.
    function set(key, value, deferred) {
        const next = Store.sanitize(Object.assign({}, values, {
            [key]: value
        }));
        values = next;
        if (deferred)
            writeTimer.restart();
        else
            _write();
    }

    function _write() {
        writeTimer.stop();
        _lastText = Store.serialize(values);
        _prepare.running = true;
    }

    // What this process wrote last: the watcher also fires for our own write
    property string _lastText: ""

    function _adopt(text) {
        if (text === _lastText)
            return;
        values = Store.parse(text);
        _lastText = Store.serialize(values);
    }

    // The folder 0700 and the file 0600 before anything is written; paths are
    // positional parameters, never part of the script.
    Process {
        id: _prepare

        command: ["sh", "-c", "umask 077; mkdir -p -- \"$1\" && chmod 700 -- \"$1\"", "sh", root.dir]
        onExited: code => {
            if (code === 0)
                file.setText(root._lastText);
        }
    }

    Process {
        id: _seal

        command: ["chmod", "600", "--", root.path]
    }

    Timer {
        id: writeTimer

        interval: 400
        onTriggered: root._write()
    }

    FileView {
        id: file

        path: root.path
        watchChanges: true
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: {
            root._adopt(text());
            root.ready = true;
        }
        // No file yet: first run, or the first run of the app after the widget
        onLoadFailed: {
            legacy.active = true;
        }
        onSaved: _seal.running = true
    }

    // The widget's DMS settings, read once and only when our file is missing
    FileView {
        id: legacy

        property bool active: false

        path: active ? root.legacyPath : ""
        onLoaded: {
            let all = {};
            try {
                all = JSON.parse(text());
            } catch (e) {
                all = {};
            }
            root.values = Store.migrate(all.abyss ?? null);
            root.ready = true;
            // Written at once: a second start finds the file and never migrates again
            root._write();
            active = false;
        }
        onLoadFailed: {
            // Without DMS the defaults apply, silently
            active = false;
            root.ready = true;
        }
    }
}
