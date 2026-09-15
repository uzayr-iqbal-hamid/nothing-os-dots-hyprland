import QtQuick

// Square glyph button, with an optional red dot (e.g. unread notifications).
Rectangle {
    id: root

    property string icon
    property bool badge: false

    signal clicked

    implicitWidth: 44
    implicitHeight: 44
    radius: Theme.radiusCard
    color: area.containsMouse ? Theme.surfaceHi : Theme.surface

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: Theme.text
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
        onClicked: root.clicked()
    }
}
