import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Nothing power menu: dims the screen behind a row of round buttons. Lock and sleep run at once;
// log out, restart and shut down turn red and wait for a second press. Keys: arrows or Tab move,
// 1-5 pick, Enter runs, Escape (or a click on the backdrop) closes.
PanelWindow {
    id: panel

    readonly property bool shown: ShellState.powerMenuOpen && ShellState.powerMenuScreen === screen.name
    property bool entered: false
    property int current: 0
    property int armed: -1 // button waiting for its confirming press

    readonly property var actions: [
        { icon: Icons.lock, label: "Lock", confirm: false },
        { icon: Icons.sleep, label: "Sleep", confirm: false },
        { icon: Icons.logout, label: "Log out", confirm: true },
        { icon: Icons.restart, label: "Restart", confirm: true },
        { icon: Icons.power, label: "Shut down", confirm: true }
    ]

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "nothing-powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: entered = true

    function move(step) {
        current = (current + step + actions.length) % actions.length;
        armed = -1;
    }

    function activate(index) {
        current = index;
        if (actions[index].confirm && armed !== index) {
            armed = index;
            disarm.restart();
            return;
        }
        ShellState.closePowerMenu();
        switch (index) {
        case 0:
            Quickshell.execDetached(["sh", "-c", Config.lockCommand]);
            break;
        case 1:
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case 2:
            Hyprland.dispatch("exit");
            break;
        case 3:
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case 4:
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: panel.armed = -1
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#B3000000"
        opacity: panel.entered && panel.shown ? 1 : 0
        focus: true

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }

        // once faded out, unload the window (deferred: this handler belongs to the window being unloaded)
        onOpacityChanged: {
            if (panel.entered && opacity === 0 && !panel.shown)
                Qt.callLater(ShellState.unloadPowerMenu, panel.screen?.name ?? "");
        }

        Keys.onPressed: event => {
            const key = event.key;
            if (key === Qt.Key_Escape)
                ShellState.closePowerMenu();
            else if (key === Qt.Key_Left || key === Qt.Key_Backtab || key === Qt.Key_Up)
                panel.move(-1);
            else if (key === Qt.Key_Right || key === Qt.Key_Tab || key === Qt.Key_Down)
                panel.move(1);
            else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
                panel.activate(panel.current);
            else if (key >= Qt.Key_1 && key <= Qt.Key_5)
                panel.activate(key - Qt.Key_1);
            else
                return;
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closePowerMenu()
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.gapXl

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, Config.clockFormat)
                color: Theme.text
                font.family: Theme.fontDot
                font.pixelSize: 56
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.gapL

                Repeater {
                    model: panel.actions

                    delegate: PowerButton {
                        required property int index
                        required property var modelData
                        buttonIndex: index
                        icon: modelData.icon
                        label: modelData.label
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panel.armed >= 0 ? "PRESS AGAIN TO CONFIRM" : "ESC TO CANCEL"
                color: panel.armed >= 0 ? Theme.accent : Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
        }
    }

    component PowerButton: Item {
        id: button

        property int buttonIndex
        property string icon
        property string label
        readonly property bool selected: panel.current === buttonIndex
        readonly property bool armed: panel.armed === buttonIndex

        width: 92
        height: circle.height + Theme.gapM + caption.implicitHeight

        Rectangle {
            id: circle
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72
            height: 72
            radius: 36
            color: button.armed ? Theme.accent : button.selected ? Theme.pill : Theme.surface
            border.width: Theme.hairline
            border.color: button.selected || button.armed ? "transparent" : Theme.outline

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animFast
                }
            }

            Text {
                anchors.centerIn: parent
                text: button.icon
                color: button.armed ? Theme.text : button.selected ? Theme.pillText : Theme.text
                font.family: Theme.fontIcon
                font.pixelSize: 26
            }
        }

        Text {
            id: caption
            anchors.top: circle.bottom
            anchors.topMargin: Theme.gapM
            anchors.horizontalCenter: parent.horizontalCenter
            text: (button.armed ? "Confirm" : button.label).toUpperCase()
            color: button.armed ? Theme.accent : button.selected ? Theme.text : Theme.textDim
            font.family: Theme.fontLabel
            font.pixelSize: 9
            font.letterSpacing: Theme.labelSpacing
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (panel.current !== button.buttonIndex)
                    panel.armed = -1;
                panel.current = button.buttonIndex;
            }
            onClicked: panel.activate(button.buttonIndex)
        }
    }
}
