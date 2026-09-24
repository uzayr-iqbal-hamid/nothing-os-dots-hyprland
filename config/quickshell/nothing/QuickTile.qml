import QtQuick

// Nothing quick-settings pill: white when active, dark when not, icon in a contrasting circle.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active
    property string trailing // optional glyph at the right edge, e.g. a chevron
    property real trailingRotation: 0

    signal clicked
    signal rightClicked

    implicitHeight: 48
    radius: height / 2
    color: active ? Theme.pill : Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        radius: 18
        color: root.active ? Theme.bg : Theme.surfaceHi

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: Theme.text
            font.family: Theme.fontIcon
            font.pixelSize: 16
        }
    }

    Text {
        id: trailingGlyph
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapM
        anchors.verticalCenter: parent.verticalCenter
        visible: root.trailing !== ""
        text: root.trailing
        rotation: root.trailingRotation
        color: root.active ? Theme.pillText : Theme.textDim
        font.family: Theme.fontIcon
        font.pixelSize: 14

        Behavior on rotation {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: Theme.gapS
        anchors.right: root.trailing !== "" ? trailingGlyph.left : parent.right
        anchors.rightMargin: root.trailing !== "" ? Theme.gapS : Theme.gapM
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.title
            color: root.active ? Theme.pillText : Theme.text
            font.family: Theme.fontLabel
            font.weight: Font.Medium
            font.pixelSize: 11
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.subtitle.toUpperCase()
            color: root.active ? Theme.textFaint : Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 8
            font.letterSpacing: 0.6
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
