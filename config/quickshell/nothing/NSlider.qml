import QtQuick

// Thin Nothing slider: grey track, white fill. Click, drag or scroll.
Item {
    id: root

    property real value: 0 // 0..1

    signal moved(real value)

    implicitHeight: 14

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.track

        Rectangle {
            width: Math.max(parent.height, parent.width * Math.min(1, root.value))
            height: parent.height
            radius: 2
            color: Theme.text
        }
    }

    MouseArea {
        function setFrom(x) {
            root.moved(Math.max(0, Math.min(1, x / width)));
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => setFrom(mouse.x)
        onPositionChanged: mouse => setFrom(mouse.x)
        // proportional, so touchpads scroll smoothly and mouse notches step 5%
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + wheel.angleDelta.y / 120 * 0.05)))
    }
}
