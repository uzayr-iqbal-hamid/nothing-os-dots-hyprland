import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Output volume card: label and level on top, speaker (click to mute) and slider below.
Rectangle {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    implicitHeight: 48
    radius: Theme.radiusCard
    color: Theme.surface

    PwObjectTracker {
        objects: [root.sink]
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapM
        anchors.top: parent.top
        anchors.topMargin: 9
        text: "SOUND"
        color: Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 8
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapM
        anchors.top: parent.top
        anchors.topMargin: 8
        text: root.muted ? "MUTED" : Math.round(root.volume * 100)
        color: root.muted ? Theme.accent : Theme.text
        font.family: Theme.fontLabel
        font.pixelSize: 9
    }

    Text {
        id: speaker
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapM - 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        text: Icons.volume(root.volume, root.muted)
        color: root.muted ? Theme.textFaint : Theme.text
        font.family: Theme.fontIcon
        font.pixelSize: 13

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.sink?.audio)
                    root.sink.audio.muted = !root.muted;
            }
        }
    }

    NSlider {
        anchors.left: speaker.right
        anchors.leftMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapM
        anchors.verticalCenter: speaker.verticalCenter
        value: root.volume
        onMoved: value => {
            if (root.sink?.audio)
                root.sink.audio.volume = value;
        }
    }
}
