pragma Singleton
import QtQuick

// Test stand-in for DMS's socket: a made-up clipboard history, and a record
// of every request so tests can see what was deleted
QtObject {
    property bool isConnected: true
    property var requests: []
    property var entries: []
    function sendRequest(method, params, cb) {
        requests = requests.concat([method + " " + JSON.stringify(params)]);
        if (method === "clipboard.search")
            cb({
                "result": {
                    "entries": entries
                }
            });
        else
            cb({});
    }
}
