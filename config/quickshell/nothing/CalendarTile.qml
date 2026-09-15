import QtQuick
import Quickshell

// Calendar tile: the month in the accent, the day large and bold, the weekday underneath.
// Adwaita Sans is a variable font: Qt ignores font.weight for it, so the weight (and the optical
// size, for tighter large text) go through font.variableAxes.
Rectangle {
    id: root

    // short month names as on the reference ("SEPT", not "SEP")
    readonly property var months: ["JAN", "FEB", "MAR", "APR", "MAY", "JUNE", "JULY", "AUG", "SEPT", "OCT", "NOV", "DEC"]

    implicitWidth: 150
    implicitHeight: 150
    radius: Theme.radiusWidget
    color: Theme.widget

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.centerIn: parent
        spacing: -6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.months[clock.date.getMonth()]
            color: Theme.accent
            font.family: Theme.fontSans
            font.pixelSize: 16
            font.variableAxes: ({ "wght": 500 })
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date.getDate()
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: 70
            font.variableAxes: ({ "wght": 700, "opsz": 32 })
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd").toUpperCase()
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: 14
            font.variableAxes: ({ "wght": 400 })
        }
    }
}
