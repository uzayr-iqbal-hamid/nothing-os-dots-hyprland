import QtQuick
import Quickshell

// Big dot-matrix clock with seconds; date and week beside it.
Item {
    id: root

    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        return Math.ceil(((d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    }

    implicitHeight: time.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        id: clockRow
        spacing: 4

        Text {
            id: time
            text: Qt.formatDateTime(clock.date, Config.clockFormat)
            color: Theme.text
            font.family: Theme.fontDot
            font.pixelSize: 44
        }
        Text {
            anchors.baseline: time.baseline
            text: Qt.formatDateTime(clock.date, "ss")
            color: Theme.textFaint
            font.family: Theme.fontDot
            font.pixelSize: 20
        }
    }

    Column {
        anchors.left: clockRow.right
        anchors.leftMargin: Theme.gapL
        anchors.top: parent.top
        anchors.topMargin: 7
        spacing: 4

        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase()
            color: Theme.text
            font.family: Theme.fontLabel
            font.pixelSize: 10
            font.letterSpacing: Theme.labelSpacing
        }
        Text {
            text: "WEEK " + root.isoWeek(clock.date)
            color: Theme.textFaint
            font.family: Theme.fontLabel
            font.pixelSize: 9
            font.letterSpacing: Theme.labelSpacing
        }
    }
}
