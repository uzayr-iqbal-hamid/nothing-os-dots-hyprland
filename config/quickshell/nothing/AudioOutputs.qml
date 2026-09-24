pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Sound outputs (PipeWire sinks) for the control center's output switcher, without the virtual
// loopback sinks WirePlumber adds for its role-based routing.
Singleton {
    id: root

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio && !n.name.startsWith("input.loopback"))
    readonly property var current: Pipewire.defaultAudioSink

    function label(node) {
        if (!node)
            return "No output";
        const text = node.description || node.nickname || node.name;
        return text.replace(/ (Analog|Digital) Stereo$/, "").replace(/^Built-in Audio$/, "Built-in speakers");
    }

    function icon(node) {
        return node?.name.startsWith("bluez") ? Icons.headphones : Icons.speaker;
    }

    function select(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
}
