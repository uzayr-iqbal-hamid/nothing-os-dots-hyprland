import QtQuick
import Quickshell.Services.Pipewire

// Microphone mute. Turns white, with the crossed-out mic, while muted.
IconButton {
    id: root

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: source?.audio?.muted ?? false

    icon: muted ? Icons.micOff : Icons.mic
    active: muted
    opacity: source ? 1 : 0.4
    onClicked: {
        if (source?.audio)
            source.audio.muted = !muted;
    }

    PwObjectTracker {
        objects: [root.source]
    }
}
