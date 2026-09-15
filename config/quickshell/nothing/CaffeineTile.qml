import QtQuick

// Caffeine: keep the screen awake. Sets ShellState.caffeine, which enables the idle inhibitor in Bar.qml.
Rectangle {
    id: root

    readonly property bool active: ShellState.caffeine

    implicitHeight: 44
    radius: Theme.radiusCard
    color: Theme.surface

    Text {
        id: cup
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapM
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.coffee
        color: root.active ? Theme.text : Theme.textDim
        font.family: Theme.fontIcon
        font.pixelSize: 15
    }

    Text {
        anchors.left: cup.right
        anchors.leftMargin: Theme.gapS
        anchors.verticalCenter: parent.verticalCenter
        text: "CAFFEINE"
        color: root.active ? Theme.text : Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 9
        font.letterSpacing: Theme.labelSpacing
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapM
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 18
        radius: 9
        color: root.active ? Theme.pill : Theme.track

        Rectangle {
            x: root.active ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: root.active ? Theme.pillText : Theme.textDim

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Theme.easing
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.caffeine = !ShellState.caffeine
    }
}
