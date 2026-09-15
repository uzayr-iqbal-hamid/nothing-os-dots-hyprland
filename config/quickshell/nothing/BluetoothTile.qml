import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth tile, after the reference: the device glyph in the accent, the device (or "Connect") in
// bold, a status line and a thin battery bar. Tapping turns the adapter on when it's off, connects the
// preferred paired device (audio first) when nothing is connected, and otherwise opens the Bluetooth
// manager. Right click always opens the manager.
// Adwaita Sans is a variable font, so weights go through font.variableAxes (see CalendarTile).
Rectangle {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var connected: devices.filter(d => d.connected)
    readonly property var connecting: devices.find(d => d.state === BluetoothDeviceState.Connecting) ?? null
    // the device the tile is about: one being connected, else a connected one (audio first)
    readonly property var device: connecting ?? connected.find(d => isAudio(d)) ?? connected[0] ?? null
    // what a tap would connect when nothing is
    readonly property var candidate: devices.filter(d => d.paired && !d.connected)
                                            .sort((a, b) => isAudio(b) - isAudio(a))[0] ?? null
    readonly property real battery: device?.batteryAvailable ? device.battery : 0

    readonly property string title: {
        if (!powered)
            return "Bluetooth";
        if (device)
            return device.name || device.deviceName;
        return "Connect";
    }
    readonly property string subtitle: {
        if (!adapter)
            return "unavailable";
        if (!powered)
            return "turned off";
        if (connecting)
            return "connecting…";
        if (device) {
            const more = connected.length > 1 ? ` · +${connected.length - 1}` : "";
            return (device.batteryAvailable ? `${Math.round(device.battery * 100)}% battery` : "connected") + more;
        }
        return candidate ? (candidate.name || candidate.deviceName) : "no device found";
    }
    readonly property string glyph: {
        const d = device ?? candidate;
        if (!powered)
            return Icons.bluetoothOff;
        return d ? Icons.btDevice(d.icon) : Icons.bluetooth;
    }

    function isAudio(d) {
        return d.icon.startsWith("audio");
    }

    function openManager() {
        Quickshell.execDetached(["sh", "-c", Config.bluetoothManager]);
    }

    implicitWidth: 234
    implicitHeight: 150
    radius: Theme.radiusWidget
    color: Theme.widget

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 18
        text: root.glyph
        color: root.powered ? Theme.accent : Theme.textFaint
        font.family: Theme.fontIcon
        font.pixelSize: 28
    }

    Rectangle {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 18
        height: 3
        radius: 1.5
        color: Theme.track

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * root.battery
            color: Theme.text

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animMed
                    easing.type: Theme.easing
                }
            }
        }
    }

    Text {
        id: subtitleText
        anchors.left: bar.left
        anchors.right: bar.right
        anchors.bottom: bar.top
        anchors.bottomMargin: 10
        elide: Text.ElideRight
        text: root.subtitle
        color: Theme.textDim
        font.family: Theme.fontSans
        font.pixelSize: 13
        font.variableAxes: ({ "wght": 600 })
    }

    Text {
        anchors.left: bar.left
        anchors.right: bar.right
        anchors.bottom: subtitleText.top
        anchors.bottomMargin: -2
        elide: Text.ElideRight
        text: root.title
        color: Theme.text
        font.family: Theme.fontSans
        font.pixelSize: 28
        font.variableAxes: ({ "wght": 700, "opsz": 32 })
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton || !root.adapter)
                root.openManager();
            else if (!root.powered)
                root.adapter.enabled = true;
            else if (!root.device && root.candidate)
                root.candidate.connect();
            else
                root.openManager();
        }
    }
}
