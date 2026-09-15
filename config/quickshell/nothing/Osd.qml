import QtQuick
import Quickshell
import Quickshell.Wayland

// Nothing OSD: a pill at the bottom of the screen with a glyph, a dot-matrix level meter and the
// value. Mapped only while shown, so Hyprland's layer fade animates it in and out; clicks pass through.
PanelWindow {
    id: osd

    readonly property int dots: 24
    readonly property int lit: OsdState.muted ? 0 : Math.round(OsdState.level * dots)
    readonly property string glyph: OsdState.kind === "brightness" ? Icons.brightness
                                  : OsdState.kind === "mic" ? (OsdState.muted ? Icons.micOff : Icons.mic)
                                  : Icons.volume(OsdState.level, OsdState.muted)

    screen: OsdState.screen
    visible: OsdState.shown && OsdState.screen !== null
    anchors.bottom: true
    margins.bottom: Config.osdMarginBottom
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: row.implicitWidth + 2 * Theme.gapL
    implicitHeight: 46
    color: "transparent"
    WlrLayershell.namespace: "nothing-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.glass
        border.width: Theme.hairline
        border.color: Theme.outline

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.gapM

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                horizontalAlignment: Text.AlignHCenter
                text: osd.glyph
                color: OsdState.muted ? Theme.textFaint : Theme.text
                font.family: Theme.fontIcon
                font.pixelSize: 15
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: osd.dots

                    delegate: Rectangle {
                        required property int index
                        width: 5
                        height: 5
                        radius: 1
                        color: index < osd.lit ? Theme.text : Theme.track

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                            }
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                horizontalAlignment: Text.AlignRight
                text: OsdState.muted ? "MUTE" : Math.round(OsdState.level * 100)
                color: OsdState.muted ? Theme.textDim : Theme.text
                font.family: Theme.fontLabel
                font.pixelSize: 11
            }
        }
    }
}
