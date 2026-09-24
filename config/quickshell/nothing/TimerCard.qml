import QtQuick

// Glyph timer: a countdown on the glyph lights' bottom strip. Idle, it offers presets in minutes;
// running, it shows the time left in dot-matrix digits with +1 minute and stop. The countdown itself
// lives in GlyphService, so it keeps going after the control center closes.
Rectangle {
    id: root

    readonly property var presets: [5, 15, 25, 45]
    readonly property bool running: GlyphService.timerRunning
    readonly property bool available: GlyphService.enabled

    // Time left in ms, refreshed while the card is on screen.
    property real remaining: 0

    function format(ms) {
        const total = Math.ceil(ms / 1000);
        const pad = n => String(n).padStart(2, "0");
        return pad(Math.floor(total / 60)) + ":" + pad(total % 60);
    }

    implicitHeight: 120
    radius: Theme.radiusCard
    color: Theme.surface

    Timer {
        interval: 250
        repeat: true
        triggeredOnStart: true
        running: root.running && root.visible
        onTriggered: root.remaining = Math.max(0, GlyphService.timerEnd - Date.now())
    }

    Text {
        id: label
        x: Theme.gapM
        y: Theme.gapM
        text: "TIMER"
        color: Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 9
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapM
        anchors.verticalCenter: label.verticalCenter
        text: !root.available ? "GLYPH OFF" : root.running ? "RUNNING" : "MINUTES"
        color: root.running ? Theme.accent : Theme.textFaint
        font.family: Theme.fontLabel
        font.pixelSize: 9
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        x: Theme.gapM - 2
        anchors.top: label.bottom
        anchors.topMargin: Theme.gapXs
        text: root.running ? root.format(root.remaining) : "00:00"
        color: root.running ? Theme.text : Theme.textFaint
        font.family: Theme.fontDot
        font.pixelSize: 34
    }

    Row {
        id: buttons
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.gapM
        spacing: 6

        readonly property real cell: (width - spacing * 3) / 4

        // Idle: one pill per preset.
        Repeater {
            model: root.running ? [] : root.presets

            Pill {
                required property int modelData
                width: buttons.cell
                text: String(modelData)
                enabled: root.available
                onClicked: GlyphService.startTimer(modelData * 60)
            }
        }

        // Running: +1 minute and stop.
        Pill {
            visible: root.running
            width: buttons.cell * 2 + buttons.spacing
            text: "+1 MIN"
            onClicked: GlyphService.addTime(60)
        }
        Pill {
            visible: root.running
            width: buttons.cell * 2 + buttons.spacing
            text: "STOP"
            primary: true
            onClicked: GlyphService.clearProgress()
        }
    }

    component Pill: Rectangle {
        id: pill

        property string text
        property bool primary: false
        signal clicked

        height: 26
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        color: primary ? Theme.pill : hover.hovered ? Theme.surfaceHi : Theme.track

        Text {
            anchors.centerIn: parent
            text: pill.text
            color: pill.primary ? Theme.pillText : Theme.text
            font.family: Theme.fontLabel
            font.pixelSize: 10
            font.letterSpacing: Theme.labelSpacing
        }

        HoverHandler {
            id: hover
            cursorShape: pill.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            enabled: pill.enabled
            onTapped: pill.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.animFast
            }
        }
    }
}
