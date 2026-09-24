import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Wayland

// Nothing control center: drops below the bar on the screen whose clock was clicked.
// Click outside it or press Escape to close.
PanelWindow {
    id: panel

    required property var bar
    readonly property bool shown: ShellState.controlCenterOpen && ShellState.controlCenterScreen === screen.name
    property bool entered: false

    anchors.top: true
    margins.top: Config.barMarginTop + Config.barHeight + Theme.gapS
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Config.controlCenterWidth
    implicitHeight: card.implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "nothing-controlcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: entered = true

    // the bar is part of the grab, so clicking its clock toggles instead of close-then-reopen
    HyprlandFocusGrab {
        active: panel.shown
        windows: [panel, panel.bar]
        onCleared: ShellState.closeControlCenter()
    }

    function run(command) {
        ShellState.closeControlCenter();
        Quickshell.execDetached(["sh", "-c", command]);
    }

    Rectangle {
        id: card

        property real slide: panel.entered && panel.shown ? 0 : -10

        width: parent.width
        implicitHeight: layout.implicitHeight + 2 * Theme.gapM
        radius: Theme.radiusPanel
        color: Theme.glass
        border.width: Theme.hairline
        border.color: Theme.outline
        opacity: panel.entered && panel.shown ? 1 : 0
        transform: Translate {
            y: card.slide
        }
        focus: true
        Keys.onEscapePressed: ShellState.closeControlCenter()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }
        Behavior on slide {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }

        // once faded out, unload the window (deferred: this handler belongs to the window being unloaded)
        onOpacityChanged: {
            if (panel.entered && opacity === 0 && !panel.shown)
                Qt.callLater(ShellState.unloadControlCenter, panel.screen?.name ?? "");
        }

        ColumnLayout {
            id: layout

            readonly property real third: (width - 2 * spacing) / 3

            anchors.fill: parent
            anchors.margins: Theme.gapM
            spacing: Theme.gapS

            CcHeader {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.gapXs
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapS

                QuickTile {
                    Layout.preferredWidth: layout.third
                    icon: NetworkService.icon
                    title: NetworkService.title
                    subtitle: NetworkService.subtitle
                    active: NetworkService.connected
                    // wired: nothing to toggle, open the menu; wifi: toggle the radio
                    onClicked: NetworkService.wired ? NetworkService.openMenu() : NetworkService.toggleWifi()
                    onRightClicked: NetworkService.openMenu()
                }

                QuickTile {
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property var device: adapter?.devices.values.find(d => d.connected) ?? null

                    Layout.preferredWidth: layout.third
                    icon: adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
                    title: "Bluetooth"
                    subtitle: !adapter ? "Unavailable" : !adapter.enabled ? "Off" : device ? device.name : "On"
                    active: adapter?.enabled ?? false
                    onClicked: {
                        if (adapter)
                            adapter.enabled = !adapter.enabled;
                    }
                    onRightClicked: panel.run(Config.bluetoothManager)
                }

                VolumeTile {
                    Layout.preferredWidth: layout.third
                }
            }

            MediaCard {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapS

                NightLightCard {
                    Layout.preferredWidth: (layout.width - Theme.gapS) * 0.4
                }
                StatsCard {
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapS

                // Half width each; the remote grows downward when it shows its QR code.
                RemoteTile {
                    Layout.preferredWidth: (layout.width - Theme.gapS) / 2
                    Layout.alignment: Qt.AlignTop
                }
                GlyphTile {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapS

                CaffeineTile {
                    Layout.fillWidth: true
                }
                IconButton {
                    icon: Icons.lock
                    onClicked: panel.run(Config.lockCommand)
                }
                IconButton {
                    icon: Icons.power
                    onClicked: {
                        ShellState.closeControlCenter();
                        ShellState.openPowerMenu(panel.screen.name);
                    }
                }
                IconButton {
                    icon: Icons.bell
                    badge: NotificationService.count > 0
                    onClicked: {
                        ShellState.closeControlCenter();
                        NotificationService.togglePanel();
                    }
                }
            }
        }
    }
}
