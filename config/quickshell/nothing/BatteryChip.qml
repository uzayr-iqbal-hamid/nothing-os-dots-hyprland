import QtQuick
import QtQuick.Shapes
import Quickshell.Services.UPower

// Drawn battery (no glyph): the fill tracks charge and turns red when low; a bolt shows while
// charging. Static on purpose: no looping animation keeping the GPU awake while plugged in.
Item {
    id: root

    readonly property var device: UPower.displayDevice
    // normalized to 0..1 whether the service reports 0..1 or 0..100
    readonly property real level: {
        const p = device?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property bool low: level <= 0.2 && !charging
    readonly property color tone: low ? Theme.accent : Theme.text

    visible: (device?.ready ?? false) && (device?.isLaptopBattery ?? false)
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 4

        Shape {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.charging
            width: 6
            height: 10
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.text
                strokeWidth: 0
                strokeColor: "transparent"
                startX: 4
                startY: 0
                PathLine { x: 0; y: 5.8 }
                PathLine { x: 2.8; y: 5.8 }
                PathLine { x: 2; y: 10 }
                PathLine { x: 6; y: 4.2 }
                PathLine { x: 3.2; y: 4.2 }
                PathLine { x: 4; y: 0 }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 21
            height: 11

            Rectangle {
                id: body
                width: 18
                height: parent.height
                radius: 3
                color: "transparent"
                border.width: 1.2
                border.color: root.tone

                Rectangle {
                    x: 2
                    y: 2
                    width: Math.max(1, (parent.width - 4) * root.level)
                    height: parent.height - 4
                    radius: 1.5
                    color: root.tone
                }
            }

            Rectangle {
                x: body.width + 1
                anchors.verticalCenter: body.verticalCenter
                width: 2
                height: 4
                radius: 1
                color: root.tone
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.level * 100)
            color: root.low ? Theme.accent : Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 12
        }
    }
}
