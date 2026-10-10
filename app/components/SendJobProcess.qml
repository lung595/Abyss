import QtQuick
import Quickshell.Io
import "SendTransfer.js" as Transfer

// One running transfer of the queue: the program of a plan, started when
// `argv` is set to run and killed with it. rsync's meter comes one \r-ended
// piece at a time (progressed); scp has none and says nothing. When it ends,
// ended(code, stderr) carries the exit code and what the program wrote on
// stderr (matched by Send.explain, never shown or logged: it holds names).
Item {
    id: job

    property var argv: []
    property bool running: false

    signal progressed(real fraction, string rate)
    signal ended(int code, string stderr)

    Process {
        command: job.argv
        running: job.running && job.argv.length > 0
        stdout: SplitParser {
            splitMarker: "\r"
            onRead: data => {
                const m = Transfer.parseProgress(data);
                if (m)
                    job.progressed(m.fraction, m.rate);
            }
        }
        stderr: StdioCollector {
            id: err
        }
        onExited: (code, _status) => job.ended(code, err.text)
    }
}
