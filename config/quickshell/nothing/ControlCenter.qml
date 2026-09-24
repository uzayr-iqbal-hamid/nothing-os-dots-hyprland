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

            anchors.fill: parent
            anchors.margins: Theme.gapM
            spacing: Theme.gapS

            CcHeader {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.gapXs
            }

            // Tiles and toggles on the left, the volume and brightness sliders standing beside them.
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapS

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gapS

                    QuickTile {
                        Layout.fillWidth: true
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

                        Layout.fillWidth: true
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.gapS

                        NightLightButton {
                            Layout.fillWidth: true
                        }
                        IconButton {
                            Layout.fillWidth: true
                            icon: Icons.coffee
                            active: ShellState.caffeine
                            onClicked: ShellState.caffeine = !ShellState.caffeine
                        }
                        IconButton {
                            Layout.fillWidth: true
                            icon: Icons.lock
                            onClicked: panel.run(Config.lockCommand)
                        }
                        IconButton {
                            Layout.fillWidth: true
                            icon: Icons.power
                            onClicked: {
                                ShellState.closeControlCenter();
                                ShellState.openPowerMenu(panel.screen.name);
                            }
                        }
                    }
                }

                VolumePill {
                    Layout.fillHeight: true
                }
                BrightnessPill {
                    Layout.fillHeight: true
                }
            }

            MediaCard {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gapS

                // Half width each. The remote grows to show its QR code; the right column is the
                // glyph switch over the glyph timer, stretched to match it.
                RemoteTile {
                    Layout.preferredWidth: (layout.width - Theme.gapS) / 2
                    Layout.fillHeight: true
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.gapS

                    GlyphTile {
                        Layout.fillWidth: true
                    }
                    TimerCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
