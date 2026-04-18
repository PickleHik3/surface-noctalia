import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null
    property string lastAction: ""
    property string lastError: ""

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    function getSetting(key) {
        return cfg[key] ?? defaults[key] ?? "";
    }

    function shellDoubleQuote(value) {
        return "\"" + String(value)
            .replace(/\\/g, "\\\\")
            .replace(/"/g, "\\\"") + "\"";
    }

    function runShell(script, actionLabel) {
        root.lastAction = actionLabel || "";
        root.lastError = "";
        executor.exec({
            command: ["bash", "-lc", script]
        });
    }

    function openRecentApps() {
        const path = getSetting("recentAppsPath");
        runShell("quickshell ipc -p " + shellDoubleQuote(path) + " call expose open smartgrid", "Recent apps");
    }

    function keyboardAuto() {
        runShell(shellDoubleQuote(getSetting("keyboardAutoScript")), "Keyboard auto");
    }

    function keyboardShow() {
        runShell(shellDoubleQuote(getSetting("keyboardShowScript")), "Keyboard show");
    }

    function keyboardHide() {
        runShell(shellDoubleQuote(getSetting("keyboardHideScript")), "Keyboard hide");
    }

    function keyboardDisable() {
        runShell(shellDoubleQuote(getSetting("keyboardDisableScript")), "Keyboard disable");
    }

    IpcHandler {
        target: "plugin:surface-tablet-controls"

        function recentApps() { root.openRecentApps(); }
        function keyboardAuto() { root.keyboardAuto(); }
        function keyboardShow() { root.keyboardShow(); }
        function keyboardHide() { root.keyboardHide(); }
        function keyboardDisable() { root.keyboardDisable(); }
        function togglePanel() {
            if (!root.pluginApi)
                return;
            root.pluginApi.withCurrentScreen(screen => {
                root.pluginApi.togglePanel(screen);
            });
        }
    }

    Process {
        id: executor

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0)
                    Logger.d("SurfaceTabletControls", text.trim());
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    root.lastError = text.trim();
                    Logger.e("SurfaceTabletControls", root.lastError);
                }
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0 && !root.lastError)
                root.lastError = "Command failed with exit code " + exitCode;
        }
    }
}
