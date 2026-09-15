import QtQuick
import Quickshell
import Quickshell.Wayland

// Desktop widgets for one screen, on the Bottom layer: above the wallpaper, below windows.
// Two content-sized windows (left stack, top-centre clock) rather than one full-screen surface,
// so empty desktop space doesn't swallow clicks.
Scope {
    id: root

    required property var targetScreen

    PanelWindow {
        screen: root.targetScreen
        anchors.top: true
        anchors.left: true
        margins.top: Config.widgetMargin
        margins.left: Config.widgetMargin
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight
        color: "transparent"
        WlrLayershell.namespace: "nothing-widgets"
        WlrLayershell.layer: WlrLayer.Bottom

        WidgetColumn {
            id: column
        }
    }

    PanelWindow {
        screen: root.targetScreen
        anchors.top: true
        margins.top: Config.widgetMargin
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        implicitWidth: bigClock.implicitWidth
        implicitHeight: bigClock.implicitHeight
        color: "transparent"
        WlrLayershell.namespace: "nothing-widgets"
        WlrLayershell.layer: WlrLayer.Bottom

        BigClock {
            id: bigClock
        }
    }
}
