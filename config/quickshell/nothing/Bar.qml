import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Floating Nothing pill: pager + weather | clock | network, volume, battery.
// The clock stays dead-center: both sides get the width of the wider one.
PanelWindow {
    id: bar

    required property var modelData

    screen: modelData
    anchors.top: true
    margins.top: Config.barMarginTop
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Config.barHeight
    implicitWidth: pill.width
    implicitHeight: Config.barHeight
    color: "transparent"
    WlrLayershell.namespace: "nothing-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Caffeine: the bars are always visible, which idle-inhibit needs
    IdleInhibitor {
        window: bar
        enabled: ShellState.caffeine
    }

    Rectangle {
        id: pill

        readonly property real sideWidth: Math.max(left.implicitWidth, right.implicitWidth)

        width: Math.max(Config.barMinWidth, Math.ceil(clock.implicitWidth + 2 * sideWidth + 2 * Theme.gapL + 2 * Theme.gapXl))
        height: parent.height
        radius: height / 2
        color: Theme.bg
        border.width: Theme.hairline
        border.color: Theme.outline

        Row {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: Theme.gapL
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gapM

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                monitor: Hyprland.monitorFor(bar.screen)
            }
            WeatherChip {
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        BarClock {
            id: clock
            anchors.centerIn: parent
            onClicked: ShellState.toggleControlCenter(bar.screen.name)
        }

        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: Theme.gapL
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gapM

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: ShellState.caffeine
                text: Icons.coffee
                color: Theme.text
                font.family: Theme.fontIcon
                font.pixelSize: 13
            }
            NetworkIcon {
                anchors.verticalCenter: parent.verticalCenter
            }
            VolumeChip {
                anchors.verticalCenter: parent.verticalCenter
            }
            BatteryChip {
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
