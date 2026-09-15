import QtQuick

// Ethernet / wifi strength / offline glyph. Click opens the rofi wifi menu.
Text {
    text: NetworkService.icon
    color: NetworkService.connected ? Theme.text : Theme.textFaint
    font.family: Theme.fontIcon
    font.pixelSize: 14

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: NetworkService.openMenu()
    }
}
