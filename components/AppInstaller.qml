import QtQuick
import Quickshell
import Quickshell.Io
import "AppInstall.js" as AppInstall

// Installs or removes the Abyss app by running the plugin's own install-app.sh.
// Started on demand, every process ends by itself: nothing runs at rest.
// phase: idle -> checking -> installing -> installed | failed | missing
Item {
    id: root

    // Folder of the plugin (absolute), and its version for the "same as widget" row
    required property string pluginDir
    required property string widgetVersion

    readonly property alias installedVersion: versionProbe.version
    property string phase: "idle"
    // Progress step shown by the invite: 0 asked, 1 checking, 2 copying, 3 linking
    property int step: 0
    property string reason: ""
    property var help: ({
            "family": "unknown",
            "name": "",
            "command": null
        })

    signal finished(bool installed)
    // The answer of a refresh(): install | update | ok
    signal checked(string state)

    // Reads the installed version (appState compares it with the widget) on demand
    function refresh() {
        versionProbe.running = true;
    }

    function install() {
        if (phase === "checking" || phase === "installing")
            return;
        reason = "";
        phase = "checking";
        step = 1;
        qsProbe.running = true;
    }

    function uninstall() {
        const argv = AppInstall.installCommand(pluginDir, true);
        if (!argv || remover.running)
            return;
        remover.command = argv;
        remover.running = true;
    }

    function _fail(text) {
        reason = text;
        phase = "failed";
        root.finished(false);
    }

    // Is a Quickshell binary on PATH? Names are positional parameters, not part of the string
    Process {
        id: qsProbe
        command: ["sh", "-c", "command -v -- \"$1\" >/dev/null 2>&1 || command -v -- \"$2\" >/dev/null 2>&1", "sh", "qs", "quickshell"]
        onExited: code => {
            if (code !== 0) {
                osRelease.reload();
                root.help = AppInstall.quickshellHelp(osRelease.text());
                root.phase = "missing";
                root.step = 1;
                return;
            }
            const argv = AppInstall.installCommand(root.pluginDir, false);
            if (!argv) {
                root._fail("The plugin folder could not be found.");
                return;
            }
            root.phase = "installing";
            root.step = 2;
            installer.command = argv;
            installer.running = true;
        }
    }

    FileView {
        id: osRelease
        path: "/etc/os-release"
        blockLoading: true
    }

    Process {
        id: installer
        property string err: ""
        stderr: StdioCollector {
            onStreamFinished: installer.err = text
        }
        onExited: code => {
            if (code === 0) {
                root.step = 3;
                root.phase = "installed";
                versionProbe.running = true;
                root.finished(true);
            } else {
                root._fail(AppInstall.failureReason(installer.err, Quickshell.env("HOME")));
            }
        }
    }

    Process {
        id: remover
        onExited: versionProbe.running = true
    }

    // `abyss --version` through the launcher on PATH; empty when absent
    Process {
        id: versionProbe
        property string version: ""
        command: ["abyss", "--version"]
        stdout: StdioCollector {
            onStreamFinished: versionProbe.version = text.trim()
        }
        onExited: code => {
            if (code !== 0)
                versionProbe.version = "";
            root.checked(root.appState);
        }
    }

    readonly property string appState: AppInstall.appState(versionProbe.version, widgetVersion)
}
