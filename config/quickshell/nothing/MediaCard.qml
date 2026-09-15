import QtQuick
import Quickshell
import Quickshell.Widgets

// Now playing: art, title, controls and a waveform progress bar (click to seek).
// Tinted from the album art's dominant colour. Collapses to a one-liner when nothing plays.
Rectangle {
    id: root

    readonly property var player: MediaService.player
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.length ?? 0
    readonly property string artUrl: player?.trackArtUrl ?? ""

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    implicitHeight: player ? 112 : 44
    radius: Theme.radiusCard
    color: Theme.surface
    clip: true

    // MPRIS doesn't push position updates; ask for them while playing
    Timer {
        interval: 1000
        running: root.player?.isPlaying ?? false
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // ColorQuantizer can't read data: URIs (mpv sends art that way), so those just get no tint
    LazyLoader {
        id: artColor
        active: root.artUrl !== "" && !root.artUrl.startsWith("data:")

        ColorQuantizer {
            source: root.artUrl
            depth: 0
            rescaleSize: 32
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: root.player !== null && (artColor.item?.colors.length ?? 0) > 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: {
                    const c = artColor.item?.colors[0] ?? Theme.surface;
                    return Qt.rgba(c.r, c.g, c.b, 0.35);
                }
            }
            GradientStop {
                position: 0.75
                color: "transparent"
            }
        }
    }

    Row {
        anchors.centerIn: parent
        visible: root.player === null
        spacing: Theme.gapS

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.music
            color: Theme.textFaint
            font.family: Theme.fontIcon
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "NOTHING PLAYING"
            color: Theme.textFaint
            font.family: Theme.fontLabel
            font.pixelSize: 9
            font.letterSpacing: Theme.labelSpacing
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Theme.gapM
        visible: root.player !== null

        ClippingRectangle {
            id: art
            width: 44
            height: 44
            radius: Theme.radiusSmall
            color: Theme.surfaceHi

            Text {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: Icons.music
                color: Theme.textFaint
                font.family: Theme.fontIcon
                font.pixelSize: 18
            }
            Image {
                id: cover
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(88, 88)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            anchors.left: art.right
            anchors.leftMargin: Theme.gapM
            anchors.right: controls.left
            anchors.rightMargin: Theme.gapS
            anchors.verticalCenter: art.verticalCenter
            spacing: 3

            Text {
                width: parent.width
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
            id: controls
            anchors.right: parent.right
            anchors.verticalCenter: art.verticalCenter
            spacing: Theme.gapS

            GlyphButton {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.skipPrevious
                active: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: 16
                color: Theme.pill

                Text {
                    anchors.centerIn: parent
                    text: root.player?.isPlaying ? Icons.pause : Icons.play
                    color: Theme.pillText
                    font.family: Theme.fontIcon
                    font.pixelSize: 16
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.togglePlaying()
                }
            }

            GlyphButton {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.skipNext
                active: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }

        Waveform {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: times.top
            anchors.bottomMargin: 3
            height: 16
            seed: root.player?.trackTitle ?? ""
            progress: root.length > 0 ? root.position / root.length : 0
            onSeek: fraction => {
                if (root.player?.canSeek && root.length > 0)
                    root.player.position = fraction * root.length;
            }
        }

        Item {
            id: times
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 11

            Text {
                anchors.left: parent.left
                text: root.formatTime(root.position)
                color: Theme.textDim
                font.family: Theme.fontLabel
                font.pixelSize: 9
            }
            Text {
                anchors.right: parent.right
                text: root.formatTime(root.length)
                color: Theme.textDim
                font.family: Theme.fontLabel
                font.pixelSize: 9
            }
        }
    }

    component GlyphButton: Text {
        property bool active: true

        signal clicked

        color: active ? Theme.text : Theme.textFaint
        font.family: Theme.fontIcon
        font.pixelSize: 18

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: parent.active
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
