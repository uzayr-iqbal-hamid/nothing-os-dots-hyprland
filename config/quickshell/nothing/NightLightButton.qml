import QtQuick
import Quickshell.Io

// Night light toggle, through KooL's Hyprsunset.sh (the same script as Super+N).
IconButton {
    id: root

    icon: Icons.nightLight
    onClicked: {
        if (!toggle.running)
            toggle.running = true;
    }

    Process {
        id: status
        running: true
        command: ["sh", "-c", Config.nightLight + " status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.active = JSON.parse(text).class === "on";
                } catch (e) {}
            }
        }
    }

    Process {
        id: toggle
        command: ["sh", "-c", Config.nightLight + " toggle"]
        onExited: status.running = true
    }
}
