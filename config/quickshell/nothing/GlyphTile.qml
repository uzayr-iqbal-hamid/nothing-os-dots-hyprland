import QtQuick

// Glyph lights switch for the control center, styled like the phone remote tile. Click toggles the lights;
// right-click toggles music mode, shown as "· MUSIC" after the label.
Rectangle {
    id: root

    readonly property bool active: GlyphService.enabled

    implicitHeight: 44
    radius: Theme.radiusCard
    color: Theme.surface

    Text {
        id: bulb
        anchors.left: parent.left
        anchors.leftMargin: Theme.gapM
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.glyphLights
        color: root.active ? Theme.text : Theme.textDim
        font.family: Theme.fontIcon
        font.pixelSize: 15
    }

    Text {
        anchors.left: bulb.right
        anchors.leftMargin: Theme.gapS
        anchors.verticalCenter: parent.verticalCenter
        text: GlyphService.musicMode ? "GLYPH · MUSIC" : "GLYPH"
        color: root.active ? Theme.text : Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 9
        font.letterSpacing: Theme.labelSpacing
    }

    Rectangle {
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                GlyphService.setMusic(!GlyphService.musicMode);
            } else {
                GlyphService.setEnabled(!GlyphService.enabled);
                // Turning on shows what it does.
                if (GlyphService.enabled)
                    GlyphService.play("chase");
            }
        }
    }
}
