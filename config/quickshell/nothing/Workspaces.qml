import QtQuick
import Quickshell
import Quickshell.Hyprland

// Nothing-style pager: a dot per workspace on this monitor, the active one stretched into a pill.
// Click a dot to go there; scroll to step through this monitor's workspaces.
Item {
    id: root

    required property var monitor
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    readonly property var ids: {
        const name = monitor?.name ?? "";
        const set = new Set(WorkspaceRules.idsFor(name));
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0 && ws.monitor?.name === name)
                set.add(ws.id);
        if (activeId > 0)
            set.add(activeId);
        return [...set].sort((a, b) => a - b);
    }

    function occupied(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        return !!ws && ws.toplevels.values.length > 0;
    }

    property real _wheel: 0

    implicitWidth: dots.implicitWidth
    implicitHeight: 14

    Row {
        id: dots
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
            // ScriptModel keeps delegates alive across updates, so the pill animates between dots
            model: ScriptModel {
                values: root.ids
            }

            delegate: Rectangle {
                id: dot
                required property int modelData
                readonly property bool active: modelData === root.activeId

                anchors.verticalCenter: parent.verticalCenter
                width: active ? 18 : 6
                height: 6
                radius: 3
                color: active ? Theme.text : root.occupied(modelData) ? Theme.textDim : Theme.textFaint

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animMed
                        easing.type: Theme.easing
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animMed
                    }
                }

                MouseArea {
                    anchors.centerIn: parent
                    width: parent.width + 5
                    height: 20
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + dot.modelData)
                }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            // touchpads send many small deltas; step once per notch
            root._wheel += event.angleDelta.y;
            if (Math.abs(root._wheel) < 120)
                return;
            Hyprland.dispatch(root._wheel < 0 ? "workspace m+1" : "workspace m-1");
            root._wheel = 0;
        }
    }
}
