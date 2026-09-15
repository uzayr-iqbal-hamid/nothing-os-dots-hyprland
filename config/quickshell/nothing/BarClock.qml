import QtQuick
import Quickshell

// Bar clock. Click to toggle the control center.
Text {
    id: root

    signal clicked

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    text: Qt.formatDateTime(clock.date, Config.clockFormat)
    color: Theme.text
    font.family: Theme.fontLabel
    font.weight: Font.Medium
    font.pixelSize: 15
}
