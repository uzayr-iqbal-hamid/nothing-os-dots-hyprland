pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Glyph lights: light strips along the screen edges, after the Glyph Interface on the back of
// Nothing phones. Seven segments, clockwise from the top left:
//   0 top-left  1 top-right  2 right-top  3 right-bottom  4 bottom  5 left-bottom  6 left-top
// Notifications play a pattern chosen per app (Config.glyphPatterns), the bottom strip doubles as a
// progress bar (IPC progress/timer), and music mode drives the segments from cava.
// Glyph.qml draws them; this holds the state. Scripts drive it with `qs ipc -c nothing call glyph ...`.
Singleton {
    id: root

    readonly property int segmentCount: 7

    // Saved in the shell's state dir (glyph.json), so they survive restarts.
    readonly property bool enabled: settings.enabled
    readonly property bool musicMode: settings.music

    // Per-segment brightness, 0..1. Reassigned whole so bindings notice.
    property var levels: [0, 0, 0, 0, 0, 0, 0]
    // White for everything except critical notifications, which use the accent red.
    property color tint: Theme.text

    // Bottom-strip progress, 0..1, or -1 when there is none.
    property real progress: -1
    // A countdown drains the strip instead of filling it.
    property bool countingDown: false

    readonly property bool playing: pattern !== null
    readonly property bool musicActive: enabled && musicMode && (MediaService.player?.isPlaying ?? false)
    // The layer is only mapped while there is something to show.
    readonly property bool active: enabled && (playing || progress >= 0 || musicActive || lingering)

    property var pattern: null // { name, start, duration }
    property var music: [0, 0, 0, 0] // cava bands, bass to treble, 0..1
    property bool lingering: false // keeps the layer up while the last frame fades

    function setEnabled(on: bool) {
        settings.enabled = on;
        if (!on)
            stop();
    }

    function setMusic(on: bool) {
        settings.music = on;
    }

    /* ---------------------------------------------------------------------------------------- */
    /* Patterns                                                                                 */
    /* ---------------------------------------------------------------------------------------- */

    readonly property var patternNames: ["pulse", "double", "chase", "breathe", "rise", "sparkle", "critical", "done"]

    readonly property var durations: ({
            pulse: 900,
            double: 700,
            chase: 1300,
            breathe: 2000,
            rise: 1100,
            sparkle: 1400,
            critical: 2400,
            done: 1000
        })

    // A flash: quick rise, short hold, slower fall. `at` and `length` in ms.
    function flash(t, at, length) {
        const x = t - at;
        if (x < 0 || x > length)
            return 0;
        const rise = 60;
        const fall = length * 0.55;
        if (x < rise)
            return x / rise;
        if (x > length - fall)
            return Math.max(0, (length - x) / fall);
        return 1;
    }

    function all(value) {
        return [value, value, value, value, value, value, value];
    }

    // Brightness of every segment `t` ms into pattern `name`.
    function frame(name, t, duration) {
        switch (name) {
        case "pulse":
            return all(Math.max(flash(t, 0, 380), flash(t, 480, 420)));
        case "double":
            {
                const v = Math.max(flash(t, 0, 260), flash(t, 330, 320));
                return [v, v, 0, 0, 0, 0, 0];
            }
        case "chase":
            {
                // A head runs once round the screen with a fading tail.
                const head = t / duration * (segmentCount + 2) - 1;
                const out = [];
                for (let i = 0; i < segmentCount; i++) {
                    const behind = head - i;
                    out.push(behind < -0.3 ? 0 : behind < 0 ? 1 + behind / 0.3 : Math.max(0, 1 - behind / 2.2));
                }
                return out;
            }
        case "breathe":
            return all(Math.pow(Math.sin(Math.PI * t / duration), 2));
        case "rise":
            {
                // Bottom first, then the sides, then the top: light pouring upwards.
                const b = flash(t, 0, 600);
                const low = flash(t, 160, 600);
                const high = flash(t, 320, 600);
                const top = flash(t, 480, 620);
                return [top, top, high, low, b, low, high];
            }
        case "sparkle":
            {
                // Each segment blinks on its own schedule, seeded so the shape is stable.
                const out = [];
                for (let i = 0; i < segmentCount; i++) {
                    const slot = Math.floor(t / 110) + i * 7;
                    const on = ((slot * 2654435761) >>> 0) % 5 < 2;
                    out.push(on ? 1 - (t % 110) / 160 : 0);
                }
                return out;
            }
        case "critical":
            return all(Math.max(flash(t, 0, 500), flash(t, 700, 500), flash(t, 1400, 900)));
        case "done":
            {
                const v = Math.max(flash(t, 0, 300), flash(t, 380, 600));
                return [v * 0.5, v * 0.5, 0, 0, v, 0, 0];
            }
        }
        return all(0);
    }

    function play(name: string) {
        if (!enabled || !(name in durations))
            return;
        tint = name === "critical" ? Theme.accent : Theme.text;
        pattern = {
            name: name,
            start: Date.now(),
            duration: durations[name]
        };
        engine.restart();
    }

    // Plays every notification pattern once, one after another.
    property int demoStep: -1

    function demo() {
        demoStep = 0;
        demoTimer.restart();
    }

    Timer {
        id: demoTimer
        interval: 50
        repeat: true
        onTriggered: {
            if (root.playing)
                return;
            const names = root.patternNames.filter(n => n !== "done");
            if (root.demoStep >= names.length) {
                root.demoStep = -1;
                demoTimer.stop();
                return;
            }
            root.play(names[root.demoStep++]);
        }
    }

    function stop() {
        demoTimer.stop();
        demoStep = -1;
        pattern = null;
        clearProgress();
        levels = all(0);
    }

    /* ---------------------------------------------------------------------------------------- */
    /* Notifications                                                                            */
    /* ---------------------------------------------------------------------------------------- */

    function patternFor(app) {
        const key = (app || "").toLowerCase();
        const table = Config.glyphPatterns;
        if (key in table)
            return table[key];
        // "org.telegram.desktop" or "Zen Browser" still match "telegram" or "zen".
        for (const name in table)
            if (name !== "default" && key.includes(name))
                return table[name];
        return table["default"] ?? "pulse";
    }

    function notify(app, urgency) {
        if (!enabled || NotificationService.dnd)
            return;
        const name = urgency >= 2 ? "critical" : patternFor(app);
        if (name === "none")
            return;
        // A burst of messages plays once; only a critical one interrupts.
        if (playing && name !== "critical")
            return;
        play(name);
    }

    // swaync owns the notification server, so listen to Notify calls on the session bus instead.
    // Each call prints as: member=Notify, then app name, icon, summary, body as `string "..."`,
    // then actions and hints (urgency is a byte in the hints), then the timeout as `int32`.
    Process {
        id: notifications
        running: root.enabled
        command: ["dbus-monitor", "--session", "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"]
        stdout: SplitParser {
            property var call: null
            property bool urgencyNext: false

            onRead: line => {
                if (line.includes("member=Notify")) {
                    call = {
                        strings: [],
                        urgency: 1
                    };
                    return;
                }
                if (!call)
                    return;
                const text = line.match(/^\s*string "(.*)"$/);
                if (urgencyNext) {
                    const byte = line.match(/byte (\d)/);
                    if (byte)
                        call.urgency = parseInt(byte[1]);
                    urgencyNext = false;
                } else if (text && text[1] === "urgency") {
                    urgencyNext = true;
                } else if (text && call.strings.length < 4) {
                    call.strings.push(text[1]);
                } else if (/^\s*int32 /.test(line)) {
                    root.notify(call.strings[0] ?? "", call.urgency);
                    call = null;
                }
            }
        }
        onExited: if (root.enabled)
            notificationsRetry.start()
    }

    Timer {
        id: notificationsRetry
        interval: 3000
        onTriggered: notifications.running = root.enabled
    }

    /* ---------------------------------------------------------------------------------------- */
    /* Progress and timer                                                                       */
    /* ---------------------------------------------------------------------------------------- */

    property real timerEnd: 0
    property real timerLength: 0
    readonly property bool timerRunning: timerEnd > 0

    function setProgress(percent: int) {
        if (!enabled)
            return;
        countingDown = false;
        timerEnd = 0;
        if (percent >= 100) {
            finishProgress();
            return;
        }
        progress = Math.max(0, percent) / 100;
        staleProgress.restart();
    }

    function finishProgress() {
        progress = -1;
        countingDown = false;
        timerEnd = 0;
        play("done");
    }

    function clearProgress() {
        progress = -1;
        countingDown = false;
        timerEnd = 0;
    }

    function startTimer(seconds: int) {
        if (!enabled || seconds <= 0)
            return;
        timerLength = seconds * 1000;
        timerEnd = Date.now() + timerLength;
        countingDown = true;
        progress = 1;
        staleProgress.stop();
    }

    // +1 minute while running; the strip keeps its place by stretching the total too.
    function addTime(seconds: int) {
        if (!timerRunning)
            return;
        timerEnd += seconds * 1000;
        timerLength += seconds * 1000;
    }

    function doneMessage(ms) {
        const minutes = Math.max(1, Math.round(ms / 60000));
        return minutes === 1 ? "1 minute is up" : minutes + " minutes are up";
    }

    // A script that dies mid-download never sends 100; don't leave the strip up forever.
    Timer {
        id: staleProgress
        interval: 60000
        onTriggered: root.clearProgress()
    }

    Timer {
        interval: 200
        repeat: true
        running: root.timerEnd > 0
        onTriggered: {
            const left = root.timerEnd - Date.now();
            if (left <= 0) {
                const length = root.timerLength;
                root.clearProgress();
                root.play("chase");
                // The lights are easy to miss from across the room; the notification waits in swaync.
                // (It lands mid-chase, so it doesn't start a second pattern.)
                Quickshell.execDetached(["notify-send", "-a", "Glyph timer", "Timer done", root.doneMessage(length)]);
            } else {
                root.progress = left / root.timerLength;
            }
        }
    }

    /* ---------------------------------------------------------------------------------------- */
    /* Music                                                                                    */
    /* ---------------------------------------------------------------------------------------- */

    // cava only runs while something is playing and music mode is on.
    Process {
        id: cava
        running: root.musicActive
        command: ["cava", "-p", Qt.resolvedUrl("glyph-cava.conf").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: line => {
                // cava prints a terminal-title escape before the first frame; keep the last four
                // fields, and anything unparsable reads as silence.
                const bands = line.split(";").filter(s => s.length).map(s => (parseInt(s) || 0) / 100);
                if (bands.length >= 4)
                    root.music = bands.slice(-4);
            }
        }
        onRunningChanged: if (!running)
            root.music = [0, 0, 0, 0]
    }

    /* ---------------------------------------------------------------------------------------- */
    /* Engine                                                                                   */
    /* ---------------------------------------------------------------------------------------- */

    // One timer composes the pattern and the music into `levels`, ~60 times a second, and only
    // runs while either is live.
    Timer {
        id: engine
        interval: 16
        repeat: true
        running: root.playing || root.musicActive
        onTriggered: {
            let out = root.all(0);
            if (root.pattern) {
                const t = Date.now() - root.pattern.start;
                if (t >= root.pattern.duration) {
                    root.pattern = null;
                    root.tint = Theme.text;
                } else {
                    out = root.frame(root.pattern.name, t, root.pattern.duration);
                }
            }
            if (root.musicActive) {
                // Bass on the bottom strip, rising to treble on the top.
                const m = root.music;
                const mix = [m[3], m[3], m[2], m[1], m[0], m[1], m[2]];
                out = out.map((v, i) => Math.max(v, mix[i] ?? 0));
            }
            root.levels = out;
        }
        onRunningChanged: {
            if (running)
                return;
            root.levels = root.all(0);
            // Let the strips fade out before the layer unmaps.
            root.lingering = true;
            linger.restart();
        }
    }

    Timer {
        id: linger
        interval: 400
        onTriggered: root.lingering = false
    }

    FileView {
        path: Quickshell.statePath("glyph.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: settings

            property bool enabled: true
            property bool music: false
        }
    }
}
