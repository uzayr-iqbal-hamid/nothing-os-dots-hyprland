import QtQuick
import Quickshell.Widgets

// Album art with title, play/pause and next. Same player as the control center.
ClippingRectangle {
    id: root

    readonly property var player: MediaService.player

    implicitWidth: 316
    implicitHeight: 150
    radius: Theme.radiusWidget
    color: Theme.widget

    // empty state
    Column {
        anchors.centerIn: parent
        visible: root.player === null
        spacing: Theme.gapS

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Icons.music
            color: Theme.textFaint
            font.family: Theme.fontIcon
            font.pixelSize: 32
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "NOTHING PLAYING"
            color: Theme.textFaint
            font.family: Theme.fontLabel
            font.pixelSize: 9
            font.letterSpacing: Theme.labelSpacing
        }
    }

    Rectangle {
        id: artBox
        visible: root.player !== null
        width: height
        height: parent.height
        color: Theme.surfaceHi

        Text {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: Icons.music
            color: Theme.textFaint
            font.family: Theme.fontIcon
            font.pixelSize: 40
        }
        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize: Qt.size(300, 300)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Column {
        anchors.left: artBox.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        visible: root.player !== null
        spacing: 4

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.player?.trackTitle || "Unknown track"
            color: Theme.text
            font.family: Theme.fontLabel
            font.weight: Font.Medium
            font.pixelSize: 12
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.player?.trackArtist || root.player?.identity || ""
            color: Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 10
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        spacing: 10
        visible: root.player !== null

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: Theme.pill

            Text {
                anchors.centerIn: parent
                text: root.player?.isPlaying ? Icons.pause : Icons.play
                color: Theme.pillText
                font.family: Theme.fontIcon
                font.pixelSize: 18
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.togglePlaying()
            }
        }

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: Theme.surfaceHi

            Text {
                anchors.centerIn: parent
                text: Icons.skipNext
                color: root.player?.canGoNext ? Theme.text : Theme.textFaint
                font.family: Theme.fontIcon
                font.pixelSize: 18
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canGoNext ?? false
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.next()
            }
        }
    }
}
