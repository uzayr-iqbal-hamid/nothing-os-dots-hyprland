import QtQuick

// Bar chip while the screen recorder runs: a blinking red dot and the elapsed time. Click to stop.
Item {
    id: root

    property real elapsed: 0

    visible: RecorderService.recording
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.visible
        onTriggered: root.elapsed = Date.now() - RecorderService.startedAt
    }

    Row {
        id: row
        spacing: 6

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accent

            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.25
                    duration: 700
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1
                    duration: 700
                    easing.type: Easing.InOutSine
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const total = Math.floor(root.elapsed / 1000);
                const pad = n => String(n).padStart(2, "0");
                return pad(Math.floor(total / 60)) + ":" + pad(total % 60);
            }
            color: area.containsMouse ? Theme.text : Theme.accent
            font.family: Theme.fontLabel
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: RecorderService.stop()
    }
}
