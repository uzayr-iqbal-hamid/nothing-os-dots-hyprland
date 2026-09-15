import QtQuick
import Quickshell

// Big dot-matrix clock for the top-centre of the desktop.
Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, Config.clockFormat)
    color: Theme.text
    font.family: Theme.fontDot
    font.pixelSize: 110
}
