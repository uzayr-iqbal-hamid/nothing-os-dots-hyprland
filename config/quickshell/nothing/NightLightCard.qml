import QtQuick
import Quickshell.Io

// Night light, through KooL's Hyprsunset.sh (the same script as Super+N). Click anywhere to toggle.
Rectangle {
    id: root

    property bool active: false

    implicitHeight: 96
    radius: Theme.radiusCard
    color: Theme.surface

    Process {
        id: status
        running: true
        command: ["sh", "-c", Config.nightLight + " status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.active = JSON.parse(text).class === "on";
                } catch (e) {}
            }
        }
    }

    Process {
        id: toggle
        command: ["sh", "-c", Config.nightLight + " toggle"]
        onExited: status.running = true
    }

    Rectangle {
        id: button
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Theme.gapM
        width: 32
        height: 32
        radius: 16
        color: root.active ? Theme.pill : Theme.surfaceHi

        Text {
            anchors.centerIn: parent
            text: Icons.nightLight
            color: root.active ? Theme.pillText : Theme.text
            font.family: Theme.fontIcon
            font.pixelSize: 15
        }
    }

    Text {
        anchors.left: button.right
        anchors.leftMargin: Theme.gapS
        anchors.verticalCenter: button.verticalCenter
        text: "NIGHT LIGHT"
        color: Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 8
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapM
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.gapS
        text: root.active ? "ON" : "OFF"
        color: root.active ? Theme.text : Theme.textFaint
        font.family: Theme.fontDot
        font.pixelSize: 26
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!toggle.running)
                toggle.running = true;
        }
    }
}
