pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Notification count + do-not-disturb, from swaync's status stream.
Singleton {
    id: root

    property int count: 0
    property bool dnd: false

    function togglePanel() {
        Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
    }

    function toggleDnd() {
        Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
    }

    Process {
        id: stream
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const status = JSON.parse(line);
                    root.count = parseInt(status.text) || 0;
                    root.dnd = (status.alt ?? "").includes("dnd");
                } catch (e) {}
            }
        }
        // restarting swaync (Refresh.sh does) ends the stream; reconnect
        onExited: reconnect.start()
    }

    Timer {
        id: reconnect
        interval: 2000
        onTriggered: stream.running = true
    }
}
