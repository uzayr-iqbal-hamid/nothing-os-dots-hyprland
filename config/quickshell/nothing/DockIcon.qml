import QtQuick
import Quickshell

// One dock slot: the app icon turned monochrome, with an underline when active and a dot when running.
// Left click focuses (cycling windows) or launches, middle click opens a new window, right click asks
// for the menu.
Item {
    id: root

    required property string modelData
    required property int index

    readonly property string appKey: modelData
    readonly property var entry: DesktopEntries.heuristicLookup(appKey)
    readonly property string name: entry?.name ?? appKey
    readonly property var windows: DockState.windowsFor(appKey)
    readonly property bool active: windows.some(w => w.activated)
    readonly property bool hovered: area.containsMouse
    readonly property bool separatorBefore: index > 0 && index === DockState.pinned.length

    signal menuRequested

    implicitWidth: Config.dockIconSize
    implicitHeight: Config.dockIconSize

    Rectangle {
        visible: root.separatorBefore
        x: -Theme.gapM / 2 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 2
        width: Theme.hairline
        height: 28
        color: Theme.outline
    }

    AppIcon {
        anchors.fill: parent
        appKey: root.appKey
        decodeSize: Config.dockIconSize * 2
        scale: area.pressed ? 0.9 : area.containsMouse ? 1.06 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Theme.easing
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 5
        visible: root.windows.length > 0
        width: root.active ? 16 : 3
        height: 3
        radius: 1.5
        color: root.active ? Theme.text : Theme.textDim

        Behavior on width {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -Theme.gapM / 2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.menuRequested();
            else if (event.button === Qt.MiddleButton || root.windows.length === 0)
                DockState.launch(root.appKey);
            else
                DockState.focusNext(root.appKey);
        }
    }
}
