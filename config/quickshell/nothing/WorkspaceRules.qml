pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Workspace ids assigned to each monitor by `workspace = N, monitor:X` rules, so a bar can
// show its monitor's workspaces before they exist (eDP-1 gets 1-4, HDMI-A-1 5-7, DP-3 8-10).
Singleton {
    id: root

    property var byMonitor: ({})

    function idsFor(monitorName) {
        return byMonitor[monitorName] ?? [];
    }

    Process {
        id: query
        running: true
        command: ["hyprctl", "workspacerules", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                try {
                    for (const rule of JSON.parse(text)) {
                        const id = parseInt(rule.workspaceString);
                        if (!rule.monitor || String(id) !== rule.workspaceString)
                            continue;
                        if (!map[rule.monitor])
                            map[rule.monitor] = [];
                        map[rule.monitor].push(id);
                    }
                } catch (e) {
                    console.warn("workspace rules: bad hyprctl output", e);
                }
                for (const name in map)
                    map[name].sort((a, b) => a - b);
                root.byMonitor = map;
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                query.running = true;
        }
    }
}
