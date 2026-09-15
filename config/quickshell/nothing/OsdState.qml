pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

// On-screen display state: what to show (volume, mic or brightness), its level, and on which screen.
// Volume and mic follow PipeWire, so every change shows it (keys, headset buttons, bar scroll);
// brightness is pushed over IPC by UserScripts/Brightness.sh, because sysfs doesn't notify.
Singleton {
    id: root

    property string kind: "volume" // volume | mic | brightness
    property real level: 0 // 0..1
    property bool muted: false
    property string screenName: ""
    property bool shown: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    // PipeWire reports the initial values shortly after start; those must not pop the OSD
    property bool armed: false

    readonly property var screen: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === screenName)
                return screens[i];
        return null;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hide
        interval: Config.osdTimeout
        onTriggered: root.shown = false
    }

    FileView {
        id: brightness
        path: `/sys/class/backlight/${Config.backlightDevice}/brightness`
        blockLoading: true
    }

    FileView {
        id: maxBrightness
        path: `/sys/class/backlight/${Config.backlightDevice}/max_brightness`
        blockLoading: true
    }

    function present(kind, level, muted, screenName) {
        if (!root.armed)
            return;
        root.kind = kind;
        root.level = level;
        root.muted = muted;
        root.screenName = screenName || (Hyprland.focusedMonitor?.name ?? "");
        root.shown = true;
        hide.restart();
    }

    function showVolume(screenName) {
        const audio = root.sink?.audio;
        if (audio)
            present("volume", audio.volume, audio.muted, screenName);
    }

    function showMic(screenName) {
        const audio = root.source?.audio;
        if (audio)
            present("mic", audio.volume, audio.muted, screenName);
    }

    function showBrightness(screenName) {
        brightness.reload();
        maxBrightness.reload();
        const max = Number(maxBrightness.text());
        if (max > 0)
            present("brightness", Number(brightness.text()) / max, false, screenName);
    }

    // the control center has its own slider, so changes made there don't need the OSD
    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged() {
            if (!ShellState.controlCenterOpen)
                root.showVolume("");
        }
        function onMutedChanged() {
            if (!ShellState.controlCenterOpen)
                root.showVolume("");
        }
    }

    Connections {
        target: root.source?.audio ?? null

        function onMutedChanged() {
            root.showMic("");
        }
    }
}
