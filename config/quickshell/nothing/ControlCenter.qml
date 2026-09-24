import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Wayland

// Nothing control center: drops below the bar on the screen whose clock was clicked.
// Click outside it or press Escape to close.
PanelWindow {
    id: panel

    required property var bar
    property bool outputsOpen: false
    property bool editing: false // the pencil: drag any piece to a new place on the grid
    property int remoteRows: 4 // the phone remote grows to fit its QR code
    readonly property bool shown: ShellState.controlCenterOpen && ShellState.controlCenterScreen === screen.name
    property bool entered: false

    anchors.top: true
    margins.top: Config.barMarginTop + Config.barHeight + Theme.gapS
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Config.controlCenterWidth
    implicitHeight: card.implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "nothing-controlcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: entered = true

    // the bar is part of the grab, so clicking its clock toggles instead of close-then-reopen
    HyprlandFocusGrab {
        active: panel.shown
        windows: [panel, panel.bar]
        onCleared: ShellState.closeControlCenter()
    }

    function run(command) {
        ShellState.closeControlCenter();
        Quickshell.execDetached(["sh", "-c", command]);
    }

    Rectangle {
        id: card

        property real slide: panel.entered && panel.shown ? 0 : -10

        width: parent.width
        implicitHeight: layout.implicitHeight + 2 * Theme.gapM
        radius: Theme.radiusPanel
        color: Theme.glass
        border.width: Theme.hairline
        border.color: Theme.outline
        opacity: panel.entered && panel.shown ? 1 : 0
        transform: Translate {
            y: card.slide
        }
        focus: true
        Keys.onEscapePressed: panel.editing ? panel.editing = false : ShellState.closeControlCenter()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }
        Behavior on slide {
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Theme.easing
            }
        }

        // once faded out, unload the window (deferred: this handler belongs to the window being unloaded)
        onOpacityChanged: {
            if (panel.entered && opacity === 0 && !panel.shown)
                Qt.callLater(ShellState.unloadControlCenter, panel.screen?.name ?? "");
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Theme.gapM
            spacing: Theme.gapS

            CcHeader {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.gapXs
            }

            // edit mode: what to do, and a way back to the default arrangement
            Item {
                Layout.fillWidth: true
                implicitHeight: 26
                visible: panel.editing

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DRAG ANYTHING TO MOVE IT"
                    color: Theme.textDim
                    font.family: Theme.fontLabel
                    font.pixelSize: 9
                    font.letterSpacing: Theme.labelSpacing
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: resetLabel.implicitWidth + 2 * Theme.gapM
                    height: 26
                    radius: height / 2
                    color: resetHover.hovered ? Theme.surfaceHi : Theme.surface

                    Text {
                        id: resetLabel
                        anchors.centerIn: parent
                        text: "RESET"
                        color: Theme.text
                        font.family: Theme.fontLabel
                        font.pixelSize: 9
                        font.letterSpacing: Theme.labelSpacing
                    }
                    HoverHandler {
                        id: resetHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: CcLayout.reset()
                    }
                }
            }

            // Every piece on one grid (CcLayout). In edit mode each one can be dragged anywhere: an
            // outline shows where it will land and the others move out of the way.
            Item {
                id: grid

                readonly property real colW: (width - (CcLayout.columns - 1) * Theme.gapS) / CcLayout.columns
                readonly property real rowStep: CcLayout.rowHeight + Theme.gapS
                property var preview: null // {key, x, y} while a piece is dragged
                readonly property var arranged: CcLayout.arrange({
                    media: MediaService.player ? 2 : 1,
                    remote: panel.remoteRows
                }, preview)

                function xOf(spot) {
                    return spot.x * (colW + Theme.gapS);
                }
                function yOf(spot) {
                    return spot.y * rowStep;
                }
                function widthOf(spot) {
                    return spot.w * colW + (spot.w - 1) * Theme.gapS;
                }
                function heightOf(spot) {
                    return spot.h * CcLayout.rowHeight + (spot.h - 1) * Theme.gapS;
                }

                Layout.fillWidth: true
                // edit mode adds an empty row to drop into
                implicitHeight: (arranged.rows + (panel.editing ? 1 : 0)) * rowStep - Theme.gapS

                // where the dragged piece will land
                Rectangle {
                    readonly property var spot: grid.preview ? grid.arranged.items[grid.preview.key] : null

                    visible: spot !== null
                    x: spot ? grid.xOf(spot) : 0
                    y: spot ? grid.yOf(spot) : 0
                    width: spot ? grid.widthOf(spot) : 0
                    height: spot ? grid.heightOf(spot) : 0
                    radius: Math.min(Theme.radiusCard, width / 2, height / 2)
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: Theme.hairline
                    border.color: Theme.textDim
                }

                Repeater {
                    model: CcLayout.keys

                    Item {
                        id: cell

                        required property string modelData
                        readonly property var spot: grid.arranged.items[modelData]
                        readonly property real spotX: grid.xOf(spot)
                        readonly property real spotY: grid.yOf(spot)
                        readonly property bool dragging: grab.drag.active

                        x: spotX
                        y: spotY
                        width: grid.widthOf(spot)
                        height: grid.heightOf(spot)
                        z: dragging ? 10 : 0
                        scale: dragging ? 1.04 : panel.editing ? 0.94 : 1
                        opacity: dragging ? 0.9 : 1

                        Behavior on x {
                            enabled: !cell.dragging
                            NumberAnimation {
                                duration: Theme.animMed
                                easing.type: Theme.easing
                            }
                        }
                        Behavior on y {
                            enabled: !cell.dragging
                            NumberAnimation {
                                duration: Theme.animMed
                                easing.type: Theme.easing
                            }
                        }
                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.animMed
                                easing.type: Theme.easing
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Theme.easing
                            }
                        }

                        Loader {
                            anchors.fill: parent
                            sourceComponent: panel.pieces[cell.modelData] ?? null
                        }

                        // edit mode: the whole piece is the handle, and it ignores its own clicks
                        MouseArea {
                            id: grab

                            anchors.fill: parent
                            enabled: panel.editing
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            drag.target: cell
                            drag.threshold: 2
                            drag.minimumX: 0
                            drag.maximumX: grid.width - cell.width
                            drag.minimumY: 0
                            drag.maximumY: grid.height - cell.height

                            onPositionChanged: {
                                if (!drag.active)
                                    return;
                                const x = Math.round(cell.x / (grid.colW + Theme.gapS));
                                const y = Math.round(cell.y / grid.rowStep);
                                const p = grid.preview;
                                if (!p || p.x !== x || p.y !== y)
                                    grid.preview = {
                                        key: cell.modelData,
                                        x: x,
                                        y: y
                                    };
                            }
                            onReleased: {
                                const p = grid.preview;
                                if (p?.key === cell.modelData)
                                    CcLayout.move(p.key, p.x, p.y);
                                grid.preview = null;
                                // back under the layout's control; the Behaviors glide it into place
                                cell.x = Qt.binding(() => cell.spotX);
                                cell.y = Qt.binding(() => cell.spotY);
                            }
                        }
                    }
                }

                // the sound output list, opened from the Output tile: below it, or above if it
                // doesn't fit
                Rectangle {
                    id: outputs

                    readonly property var spot: grid.arranged.items.output
                    readonly property real below: grid.yOf(spot) + grid.heightOf(spot) + Theme.gapXs

                    visible: panel.outputsOpen && !panel.editing
                    z: 20
                    x: grid.xOf(spot)
                    y: below + height <= grid.height ? below : grid.yOf(spot) - height - Theme.gapXs
                    width: grid.widthOf(spot)
                    height: outputList.implicitHeight + 2 * Theme.gapXs
                    radius: Theme.radiusCard + Theme.gapXs
                    color: Theme.bg
                    border.width: Theme.hairline
                    border.color: Theme.outline

                    OutputList {
                        id: outputList
                        anchors.fill: parent
                        anchors.margins: Theme.gapXs
                        onChosen: panel.outputsOpen = false
                    }
                }
            }
        }

        // pencil: edit mode on / off (a check while editing)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.gapM
            width: 28
            height: 28
            radius: 14
            color: panel.editing ? Theme.pill : editHover.hovered ? Theme.surfaceHi : Theme.surface

            Text {
                anchors.centerIn: parent
                text: panel.editing ? Icons.check : Icons.pencil
                color: panel.editing ? Theme.pillText : Theme.textDim
                font.family: Theme.fontIcon
                font.pixelSize: 13
            }
            HoverHandler {
                id: editHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    panel.editing = !panel.editing;
                    panel.outputsOpen = false;
                }
            }
        }
    }

    /* ---- pieces (keys and spans in CcLayout) ------------------------------------------- */

    readonly property var pieces: ({
            wifi: wifiPiece,
            bluetooth: bluetoothPiece,
            output: outputPiece,
            volume: volumePiece,
            brightness: brightnessPiece,
            nightLight: nightLightPiece,
            caffeine: caffeinePiece,
            mic: micPiece,
            record: recordPiece,
            screenshot: screenshotPiece,
            colorPicker: colorPickerPiece,
            lock: lockPiece,
            power: powerPiece,
            media: mediaPiece,
            remote: remotePiece,
            glyph: glyphPiece,
            timer: timerPiece
        })

    Component {
        id: wifiPiece

        QuickTile {
            icon: NetworkService.icon
            title: NetworkService.title
            subtitle: NetworkService.subtitle
            active: NetworkService.connected
            // wired: nothing to toggle, open the menu; wifi: toggle the radio
            onClicked: NetworkService.wired ? NetworkService.openMenu() : NetworkService.toggleWifi()
            onRightClicked: NetworkService.openMenu()
        }
    }

    Component {
        id: bluetoothPiece

        QuickTile {
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property var device: adapter?.devices.values.find(d => d.connected) ?? null

            icon: adapter?.enabled ? Icons.bluetooth : Icons.bluetoothOff
            title: "Bluetooth"
            subtitle: !adapter ? "Unavailable" : !adapter.enabled ? "Off" : device ? device.name : "On"
            active: adapter?.enabled ?? false
            onClicked: {
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            }
            onRightClicked: panel.run(Config.bluetoothManager)
        }
    }

    Component {
        id: outputPiece

        QuickTile {
            icon: AudioOutputs.icon(AudioOutputs.current)
            title: "Output"
            subtitle: AudioOutputs.label(AudioOutputs.current)
            active: false
            trailing: Icons.chevronDown
            trailingRotation: panel.outputsOpen ? 180 : 0
            onClicked: panel.outputsOpen = !panel.outputsOpen
            onRightClicked: panel.run(Config.mixer)
        }
    }

    Component {
        id: volumePiece

        VolumePill {}
    }

    Component {
        id: brightnessPiece

        BrightnessPill {}
    }

    Component {
        id: nightLightPiece

        NightLightButton {}
    }

    Component {
        id: caffeinePiece

        IconButton {
            icon: Icons.coffee
            active: ShellState.caffeine
            onClicked: ShellState.caffeine = !ShellState.caffeine
        }
    }

    Component {
        id: micPiece

        MicButton {}
    }

    // click: record the screen; right-click: record a region
    Component {
        id: recordPiece

        IconButton {
            icon: RecorderService.recording ? Icons.stop : Icons.record
            active: RecorderService.recording
            opacity: RecorderService.available ? 1 : 0.4
            onClicked: {
                ShellState.closeControlCenter();
                RecorderService.toggle();
            }
            onRightClicked: {
                ShellState.closeControlCenter();
                if (!RecorderService.recording)
                    RecorderService.start(true);
            }
        }
    }

    // click: select an area; right-click: the whole screen
    Component {
        id: screenshotPiece

        IconButton {
            icon: Icons.screenshot
            onClicked: panel.run(`sleep 0.4; ${Config.screenshotCommand} --area`)
            onRightClicked: panel.run(`sleep 0.4; ${Config.screenshotCommand} --now`)
        }
    }

    Component {
        id: colorPickerPiece

        IconButton {
            icon: Icons.colorPicker
            onClicked: panel.run("sleep 0.4; " + Config.colorPickerCommand)
        }
    }

    Component {
        id: lockPiece

        IconButton {
            icon: Icons.lock
            onClicked: panel.run(Config.lockCommand)
        }
    }

    Component {
        id: powerPiece

        IconButton {
            icon: Icons.power
            onClicked: {
                ShellState.closeControlCenter();
                ShellState.openPowerMenu(panel.screen.name);
            }
        }
    }

    Component {
        id: mediaPiece

        MediaCard {}
    }

    // grows to show its QR code; the grid gives it as many rows as that needs (at least 4)
    Component {
        id: remotePiece

        RemoteTile {
            function report() {
                panel.remoteRows = Math.max(CcLayout.spans.remote[1], Math.ceil((implicitHeight + Theme.gapS) / (CcLayout.rowHeight + Theme.gapS)));
            }

            onImplicitHeightChanged: report()
            Component.onCompleted: report()
        }
    }

    Component {
        id: glyphPiece

        GlyphTile {}
    }

    Component {
        id: timerPiece

        TimerCard {}
    }
}
