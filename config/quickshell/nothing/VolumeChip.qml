import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Output volume. Scroll to change, click to mute, right-click for the mixer.
Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    property real _wheel: 0

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    PwObjectTracker {
        objects: [root.sink]
    }

    Row {
        id: row
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.volume(root.volume, root.muted)
            color: root.muted ? Theme.textFaint : Theme.text
            font.family: Theme.fontIcon
            font.pixelSize: 14
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.volume * 100)
            color: Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["sh", "-c", Config.mixer]);
            else if (root.sink?.audio)
                root.sink.audio.muted = !root.muted;
        }

        onWheel: wheel => {
            if (!root.sink?.audio)
                return;
            root._wheel += wheel.angleDelta.y;
            if (Math.abs(root._wheel) < 120)
                return;
            const step = root._wheel > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + step));
            root._wheel = 0;
        }
    }
}
