import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness on a PillSlider. Read from sysfs (polled, since sysfs doesn't notify) and set
// through brightnessctl, never below 5% so the screen can't go black.
PillSlider {
    id: root

    property real pending: -1

    visible: max.text().trim() !== ""
    value: pending >= 0 ? pending : Number(current.text()) / Math.max(1, Number(max.text()))
    icon: Icons.brightness
    onMoved: v => {
        pending = Math.max(0.05, v);
        apply.restart();
    }

    FileView {
        id: current
        path: `/sys/class/backlight/${Config.backlightDevice}/brightness`
        blockLoading: true
    }

    FileView {
        id: max
        path: `/sys/class/backlight/${Config.backlightDevice}/max_brightness`
        blockLoading: true
    }

    // Drags fire on every mouse move; send brightnessctl the latest value at most every 40 ms.
    Timer {
        id: apply
        interval: 40
        onTriggered: {
            Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(root.pending * 100) + "%"]);
            settle.restart();
        }
    }

    // Once brightnessctl has written it, go back to reading sysfs.
    Timer {
        id: settle
        interval: 300
        onTriggered: {
            current.reload();
            root.pending = -1;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.pending < 0
        onTriggered: current.reload()
    }
}
