import QtQuick

// CPU / RAM / GPU usage bars, with CPU temperature in red.
Rectangle {
    id: root

    implicitHeight: 96
    radius: Theme.radiusCard
    color: Theme.surface

    SystemStats {
        id: stats
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.gapM
        anchors.rightMargin: Theme.gapM
        spacing: 6

        StatRow {
            icon: Icons.cpu
            label: "CPU"
            value: stats.cpu
            extra: isNaN(stats.cpuTemp) ? "" : Math.round(stats.cpuTemp) + "°"
        }
        StatRow {
            icon: Icons.memory
            label: "RAM"
            value: stats.ram
        }
        StatRow {
            icon: Icons.gpu
            label: "GPU"
            value: stats.gpu
        }
    }

    component StatRow: Item {
        id: row

        property string icon
        property string label
        property real value: 0 // 0..1, negative = unknown
        property string extra // shown in red

        width: parent.width
        height: 18

        Text {
            id: glyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            text: row.icon
            color: Theme.textDim
            font.family: Theme.fontIcon
            font.pixelSize: 12
        }
        Text {
            id: name
            anchors.left: glyph.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            text: row.label
            color: Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 8
            font.letterSpacing: Theme.labelSpacing
        }
        Rectangle {
            anchors.left: name.right
            anchors.right: amount.left
            anchors.rightMargin: Theme.gapS
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Theme.track

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, row.value))
                height: parent.height
                radius: 2
                color: Theme.text

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animMed
                        easing.type: Theme.easing
                    }
                }
            }
        }
        Text {
            id: amount
            anchors.right: temperature.left
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: row.value < 0 ? "--" : Math.round(row.value * 100) + "%"
            color: Theme.text
            font.family: Theme.fontLabel
            font.weight: Font.Medium
            font.pixelSize: 11
        }
        Text {
            id: temperature
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            horizontalAlignment: Text.AlignRight
            text: row.extra
            color: Theme.accent
            font.family: Theme.fontLabel
            font.pixelSize: 9
        }
    }
}
