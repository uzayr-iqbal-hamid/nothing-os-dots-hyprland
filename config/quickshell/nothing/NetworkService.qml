pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Current connection, shared by the bar icon and the control center tile.
Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool connected: wired !== null || wifi !== null
    // normalized to 0..1 whether the backend reports 0..1 or 0..100
    readonly property real strength: {
        const s = wifiNetwork?.signalStrength ?? 0;
        return s > 1 ? s / 100 : s;
    }

    readonly property string icon: wired ? Icons.ethernet : wifi ? Icons.wifi(strength) : Icons.offline
    readonly property string title: wired ? "Ethernet" : "Wi-Fi"
    readonly property string subtitle: wired ? "Connected" : wifi ? (wifiNetwork?.name || "Connected") : Networking.wifiEnabled ? "Not connected" : "Off"

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function openMenu() {
        Quickshell.execDetached(["sh", "-c", Config.wifiMenu]);
    }
}
