import QtQuick

// Notification bell for the bar. Click opens the notification panel, right-click toggles do not
// disturb. A red dot means unread notifications; with do not disturb on, the bell is crossed out.
Item {
    id: root

    implicitWidth: bell.implicitWidth
    implicitHeight: bell.implicitHeight

    Text {
        id: bell
        text: NotificationService.dnd ? Icons.bellOff : Icons.bell
        color: area.containsMouse ? Theme.text : Theme.textDim
        font.family: Theme.fontIcon
        font.pixelSize: 14
    }

    Rectangle {
        x: bell.width - width + 1
        y: 1
        visible: NotificationService.count > 0 && !NotificationService.dnd
        width: 5
        height: 5
        radius: 2.5
        color: Theme.accent
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? NotificationService.toggleDnd() : NotificationService.togglePanel()
    }
}
