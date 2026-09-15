import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Auto-hiding bottom dock. Shows on an empty workspace, after the pointer rests on the bottom edge,
// while its menu is open, or when forced over IPC. The window stays mapped at a fixed size and its
// input mask follows what's on screen, so everything else passes clicks through to windows below.
PanelWindow {
    id: dock

    readonly property var workspace: Hyprland.monitorFor(screen)?.activeWorkspace ?? null
    readonly property bool workspaceEmpty: workspace !== null && workspace.toplevels.values.length === 0
    property bool hoverRevealed: false
    readonly property bool revealed: DockState.forced || workspaceEmpty || menuApp !== ""
                                     || (hoverRevealed && !(workspace?.hasFullscreen ?? false))

    property Item hoveredIcon: null
    property string menuApp: ""
    property real menuAnchorX: 0
    readonly property var menuEntry: menuApp ? DesktopEntries.heuristicLookup(menuApp) : null
    readonly property var menuWindows: menuApp ? DockState.windowsFor(menuApp) : []

    // where the pill's top edge sits when shown, in window coordinates
    readonly property real pillTop: height - Config.dockMarginBottom - pill.height

    function openMenu(icon) {
        menuAnchorX = icon.mapToItem(dock.contentItem, icon.width / 2, 0).x;
        menuApp = icon.appKey;
    }

    function closeMenu() {
        menuApp = "";
        hideTimer.restart();
    }

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: 240
    color: "transparent"
    WlrLayershell.namespace: "nothing-dock"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: maskItem

        Region {
            x: menu.x
            y: menu.y
            width: dock.menuApp ? menu.width : 0
            height: dock.menuApp ? menu.height : 0
        }
    }

    HyprlandFocusGrab {
        active: dock.menuApp !== ""
        windows: [dock]
        onCleared: dock.closeMenu()
    }

    Timer {
        id: revealTimer
        interval: Config.dockRevealDelay
        onTriggered: dock.hoverRevealed = true
    }

    Timer {
        id: hideTimer
        interval: Config.dockHideDelay
        onTriggered: if (!hover.hovered)
            dock.hoverRevealed = false
    }

    // input region: a thin strip on the bottom edge while hidden, the pill and the gap under it while shown
    Item {
        id: maskItem
        x: zone.x
        width: zone.width
        anchors.bottom: parent.bottom
        height: dock.revealed ? zone.height : 3
    }

    Item {
        id: zone
        x: Math.round((dock.width - width) / 2)
        width: pill.width
        anchors.bottom: parent.bottom
        height: pill.height + Config.dockMarginBottom + Theme.gapS

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    revealTimer.restart();
                } else {
                    revealTimer.stop();
                    hideTimer.restart();
                }
            }
        }

        Rectangle {
            id: pill
            width: row.implicitWidth + 2 * Theme.gapM
            height: Config.dockIconSize + 2 * Theme.gapM
            y: dock.revealed ? zone.height - Config.dockMarginBottom - height : zone.height + Theme.gapS
            radius: height / 2
            color: Theme.glass
            border.width: Theme.hairline
            border.color: Theme.outline
            opacity: dock.revealed ? 1 : 0
            visible: opacity > 0

            Behavior on y {
                NumberAnimation {
                    duration: Theme.animMed
                    easing.type: Theme.easing
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animMed
                }
            }

            Row {
                id: row
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                spacing: Theme.gapM

                Repeater {
                    model: ScriptModel {
                        values: DockState.apps
                    }

                    delegate: DockIcon {
                        id: slot
                        onMenuRequested: dock.openMenu(slot)
                        onHoveredChanged: {
                            if (hovered)
                                dock.hoveredIcon = slot;
                            else if (dock.hoveredIcon === slot)
                                dock.hoveredIcon = null;
                        }
                    }
                }
            }
        }
    }

    // app name above the hovered icon
    Rectangle {
        visible: dock.hoveredIcon !== null && dock.menuApp === "" && dock.revealed
        x: dock.hoveredIcon ? Math.round(dock.hoveredIcon.mapToItem(dock.contentItem, dock.hoveredIcon.width / 2, 0).x - width / 2) : 0
        y: dock.pillTop - height - Theme.gapS
        width: tipText.implicitWidth + 2 * Theme.gapM
        height: 26
        radius: height / 2
        color: Theme.glass
        border.width: Theme.hairline
        border.color: Theme.outline

        Text {
            id: tipText
            anchors.centerIn: parent
            text: dock.hoveredIcon?.name ?? ""
            color: Theme.text
            font.family: Theme.fontLabel
            font.pixelSize: 11
        }
    }

    Rectangle {
        id: menu
        visible: dock.menuApp !== ""
        width: 200
        height: menuColumn.implicitHeight + 2 * Theme.gapS
        x: Math.round(Math.max(Theme.gapS, Math.min(dock.width - width - Theme.gapS, dock.menuAnchorX - width / 2)))
        y: dock.pillTop - height - Theme.gapS
        radius: Theme.radiusCard
        color: Theme.glass
        border.width: Theme.hairline
        border.color: Theme.outline

        Column {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: Theme.gapS
            spacing: 2

            Text {
                width: parent.width
                leftPadding: Theme.gapM
                topPadding: Theme.gapXs
                bottomPadding: Theme.gapXs
                elide: Text.ElideRight
                text: (dock.menuEntry?.name ?? dock.menuApp).toUpperCase()
                color: Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }

            MenuItem {
                visible: dock.menuEntry !== null
                label: "New window"
                onTriggered: DockState.launch(dock.menuApp)
            }
            MenuItem {
                label: DockState.isPinned(dock.menuApp) ? "Unpin from dock" : "Pin to dock"
                onTriggered: DockState.togglePin(dock.menuApp)
            }
            MenuItem {
                visible: dock.menuWindows.length > 0
                label: dock.menuWindows.length > 1 ? `Close ${dock.menuWindows.length} windows` : "Close"
                labelColor: Theme.accent
                onTriggered: DockState.closeAll(dock.menuApp)
            }
        }
    }

    component MenuItem: Rectangle {
        id: item

        property string label
        property color labelColor: Theme.text

        signal triggered

        width: menuColumn.width
        height: 32
        radius: Theme.radiusSmall
        color: itemArea.containsMouse ? Theme.surfaceHi : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Theme.gapM
            text: item.label
            color: item.labelColor
            font.family: Theme.fontLabel
            font.pixelSize: 12
        }

        MouseArea {
            id: itemArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                item.triggered();
                dock.closeMenu();
            }
        }
    }
}
