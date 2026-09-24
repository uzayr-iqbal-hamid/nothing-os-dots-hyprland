import QtQuick
import Quickshell.Services.Pipewire

// Output volume on a PillSlider. Clicking the speaker mutes.
PillSlider {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false

    value: sink?.audio?.volume ?? 0
    dim: muted
    icon: Icons.volume(value, muted)
    onMoved: v => {
        if (!sink?.audio)
            return;
        sink.audio.volume = v;
        if (muted && v > 0)
            sink.audio.muted = false;
    }
    onIconClicked: {
        if (sink?.audio)
            sink.audio.muted = !muted;
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
