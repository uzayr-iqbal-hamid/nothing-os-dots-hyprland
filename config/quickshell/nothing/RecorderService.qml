pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Screen recording through wf-recorder: the focused monitor, or a region picked with slurp, with
// desktop audio. Recordings land in Config.recordingsDir; stopping sends SIGINT so wf-recorder
// finishes the file, then a notification offers to open it. The bar shows a REC chip meanwhile.
Singleton {
    id: root

    property bool available: false
    readonly property bool recording: recorder.running
    property bool starting: false // between the click and wf-recorder running (fade-out, slurp)
    property real startedAt: 0
    property string file: ""

    property bool pendingRegion: false
    property var startAfterCheck: null // a start() that waited for the wf-recorder check

    function start(region: bool) {
        if (recording || starting)
            return;
        if (!available) {
            startAfterCheck = region;
            check.running = true;
            return;
        }
        starting = true;
        pendingRegion = region;
        // let the control center fade out so it isn't in the first frames
        delay.restart();
    }

    function stop() {
        if (recording)
            recorder.signal(2); // SIGINT: wf-recorder writes the trailer and exits
    }

    function toggle() {
        if (recording)
            stop();
        else
            start(false);
    }

    function begin(geometry) {
        const home = Quickshell.env("HOME");
        const dir = Config.recordingsDir.replace("$HOME", home);
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        const sink = Pipewire.defaultAudioSink;
        file = `${dir}/recording-${stamp}.mp4`;

        let args = ["-f", file];
        if (geometry)
            args.push("-g", geometry);
        else
            args.push("-o", Hyprland.focusedMonitor?.name ?? "");
        if (Config.recordAudio && sink)
            args.push(`--audio=${sink.name}.monitor`);

        recorder.command = ["sh", "-c", 'mkdir -p "$1" && shift && exec wf-recorder "$@"', "sh", dir].concat(args);
        recorder.running = true;
        starting = false;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Process {
        id: check
        running: true
        command: ["sh", "-c", "command -v wf-recorder"]
        onExited: code => {
            root.available = code === 0;
            const pending = root.startAfterCheck;
            root.startAfterCheck = null;
            if (pending === null)
                return;
            if (root.available)
                root.start(pending);
            else
                Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "-i", "media-record", "wf-recorder is not installed", "Install it with: sudo dnf install wf-recorder"]);
        }
    }

    Timer {
        id: delay
        interval: 400
        onTriggered: {
            if (root.pendingRegion)
                slurp.running = true;
            else
                root.begin("");
        }
    }

    Process {
        id: slurp
        command: ["slurp"]
        stdout: StdioCollector {
            onStreamFinished: {
                const geometry = text.trim();
                if (geometry)
                    root.begin(geometry);
                else
                    root.starting = false; // selection cancelled
            }
        }
    }

    Process {
        id: recorder

        stderr: StdioCollector {
            id: errors
        }
        onRunningChanged: {
            if (running)
                root.startedAt = Date.now();
        }
        onExited: {
            const lines = errors.text.trim().split("\n");
            Quickshell.execDetached(["sh", "-c", `
                if [ -s "$1" ]; then
                    action=$(notify-send -a "Screen recorder" -i video-x-generic -A default=Open -A folder="Show in folder" "Recording saved" "$(basename "$1")")
                    case "$action" in
                        default) xdg-open "$1" ;;
                        folder) xdg-open "$(dirname "$1")" ;;
                    esac
                else
                    notify-send -a "Screen recorder" -u critical "Recording failed" "$2"
                fi`, "sh", root.file, lines[lines.length - 1] || "wf-recorder stopped without writing a file"]);
        }
    }
}
