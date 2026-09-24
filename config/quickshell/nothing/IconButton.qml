import QtQuick

// Square glyph button, with an optional red dot (e.g. unread notifications). Toggles set `active`,
// which turns it white with a black glyph.
Rectangle {
    id: root

    property string icon
    property bool badge: false
    property bool active: false

    signal clicked
    signal rightClicked

    implicitWidth: 44
    implicitHeight: 44
    radius: Theme.radiusCard
    color: active ? Theme.pill : area.containsMouse ? Theme.surfaceHi : Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? Theme.pillText : Theme.text
        font.family: Theme.fontIcon
        font.pixelSize: 16
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        visible: root.badge
        width: 6
        height: 6
        radius: 3
        color: Theme.accent
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
