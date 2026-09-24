import QtQuick

// Tall capsule slider: a white fill rises from the bottom over a dark track, with the icon sitting
// on the fill and the level printed at the top. Drag, click or scroll to set it; clicking the icon
// emits iconClicked (volume uses it to mute). The fill never shrinks below the icon's circle.
Rectangle {
    id: root

    property real value: 0 // 0..1
    property string icon
    property bool dim: false // muted: grey fill, level reads OFF

    signal moved(real value)
    signal iconClicked

    readonly property real fillHeight: width + Math.max(0, Math.min(1, value)) * (height - width)

    function valueAt(y) {
        return Math.max(0, Math.min(1, (height - y - width / 2) / (height - width)));
    }

    implicitWidth: 64
    implicitHeight: 156
    radius: width / 2
    color: Theme.surface

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: root.fillHeight
        radius: root.radius
        color: root.dim ? Theme.track : Theme.pill

        Behavior on height {
            enabled: !area.dragging
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Theme.easing
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }
    }

    Text {
        id: level
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gapM + 2
        text: root.dim ? "OFF" : Math.round(root.value * 100)
        // black once the fill reaches it
        color: root.height - root.fillHeight < y + height / 2 ? (root.dim ? Theme.text : Theme.pillText) : root.dim ? Theme.accent : Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 10
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (root.width - height) / 2
        text: root.icon
        color: root.dim ? Theme.textDim : Theme.pillText
        font.family: Theme.fontIcon
        font.pixelSize: 20
    }

    MouseArea {
        id: area

        property bool onIcon: false
        property bool dragging: false
        property real startY: 0

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onPressed: mouse => {
            startY = mouse.y;
            onIcon = mouse.y > root.height - root.width;
            if (!onIcon)
                root.moved(root.valueAt(mouse.y));
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            if (Math.abs(mouse.y - startY) > 4) {
                onIcon = false;
                dragging = true;
            }
            if (!onIcon)
                root.moved(root.valueAt(mouse.y));
        }
        onReleased: {
            if (onIcon)
                root.iconClicked();
            onIcon = false;
            dragging = false;
        }
        onCanceled: {
            onIcon = false;
            dragging = false;
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + wheel.angleDelta.y / 120 * 0.05)))
    }
}
