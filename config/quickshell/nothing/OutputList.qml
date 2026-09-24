import QtQuick
import QtQuick.Layouts

// The output switcher's dropdown: one row per sound output, the current one in white.
ColumnLayout {
    id: root

    signal chosen

    spacing: Theme.gapXs

    Repeater {
        model: AudioOutputs.sinks

        Rectangle {
            id: row

            required property var modelData
            readonly property bool current: modelData === AudioOutputs.current

            Layout.fillWidth: true
            implicitHeight: 36
            radius: height / 2
            color: current ? Theme.pill : hover.hovered ? Theme.surfaceHi : Theme.surface

            Text {
                id: glyph
                anchors.left: parent.left
                anchors.leftMargin: Theme.gapM
                anchors.verticalCenter: parent.verticalCenter
                text: AudioOutputs.icon(row.modelData)
                color: row.current ? Theme.pillText : Theme.text
                font.family: Theme.fontIcon
                font.pixelSize: 14
            }

            Text {
                anchors.left: glyph.right
                anchors.leftMargin: Theme.gapS
                anchors.right: parent.right
                anchors.rightMargin: Theme.gapM
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: AudioOutputs.label(row.modelData)
                color: row.current ? Theme.pillText : Theme.text
                font.family: Theme.fontLabel
                font.pixelSize: 11
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    AudioOutputs.select(row.modelData);
                    root.chosen();
                }
            }
        }
    }
}
