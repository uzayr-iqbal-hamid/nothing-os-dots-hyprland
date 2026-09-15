pragma Singleton
import QtQuick
import Quickshell

// User settings for the Nothing shell. Design tokens live in Theme.qml.
Singleton {
    // "HH:mm" is Nothing's 24h look; "h:mm AP" for 12h
    readonly property string clockFormat: "HH:mm"

    // Weather location. NaN = locate by IP via ipinfo.io, like KooL's Weather.sh does.
    readonly property real weatherLatitude: NaN
    readonly property real weatherLongitude: NaN
    readonly property int weatherRefreshMinutes: 15

    // Bar geometry, logical px
    readonly property int barHeight: 34
    readonly property int barMarginTop: 8
    readonly property int barMinWidth: 380

    // Control center width, logical px
    readonly property int controlCenterWidth: 440

    // Desktop widgets: the output they live on, and their distance from the usable area's edges
    readonly property string widgetScreen: "eDP-1"
    readonly property int widgetMargin: 36

    // Dock: the output it lives on, icon size, gap to the screen edge, auto-hide timings (ms).
    // Pinned apps are kept in the shell's state dir (dock.json), edited from the dock's right-click menu.
    readonly property string dockScreen: "eDP-1"
    readonly property int dockIconSize: 40
    readonly property int dockMarginBottom: 10
    readonly property int dockRevealDelay: 120
    readonly property int dockHideDelay: 400

    // OSD (volume / mic / brightness pill): how long it stays, its distance from the bottom edge,
    // and the sysfs backlight the brightness reading comes from (ls /sys/class/backlight)
    readonly property int osdTimeout: 1600
    readonly property int osdMarginBottom: 90
    readonly property string backlightDevice: "intel_backlight"

    // Click actions (run through sh, so $HOME works)
    readonly property string wifiMenu: "$HOME/.config/waybar/scripts/rofi-wifi.sh"
    readonly property string mixer: "pavucontrol"
    readonly property string bluetoothManager: "blueman-manager"
    readonly property string nightLight: "$HOME/.config/hypr/scripts/Hyprsunset.sh"
    readonly property string lockCommand: "$HOME/.config/hypr/scripts/LockScreen.sh"
    readonly property string powerMenu: "$HOME/.config/hypr/scripts/Wlogout.sh"
}
