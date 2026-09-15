// Nothing OS greeter for SDDM (Qt 6). Mirrors ~/.config/hypr/hyprlock.conf:
// dimmed wallpaper, letter-spaced date, Ndot clock, a pill password field, red only on failure.
import QtQuick

Item {
    id: root
    width: 1920
    height: 1080

    readonly property color cText: "#FFFFFF"
    readonly property color cDim: "#8C8C8C"
    readonly property color cFaint: "#5A5A5A"
    readonly property color cOutline: "#2E2E2E"
    readonly property color cAccent: "#D71921"

    property string userName: userModel.lastUser
    property int sessionIndex: sessionModel.lastIndex
    property bool failed: false
    property bool busy: false

    FontLoader { id: ndot; source: Qt.resolvedUrl("fonts/Ndot57-Regular.otf") }
    FontLoader { id: lettera; source: Qt.resolvedUrl("fonts/LetteraMonoLL-Regular.otf") }

    Rectangle { anchors.fill: parent; color: "#000000" }
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(typeof config !== "undefined" && config.background ? config.background : "background.jpg")
        fillMode: Image.PreserveAspectCrop
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const d = new Date();
            timeText.text = Qt.formatTime(d, "HH:mm");
            dateText.text = Qt.formatDate(d, "dddd, d MMMM").toUpperCase();
        }
    }

    // Date + clock, same offsets as hyprlock (centre-relative, scaled to physical pixels)
    Text {
        id: dateText
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 250 - height / 2
        color: root.cDim
        font.family: lettera.font.family
        font.pixelSize: 15
        font.letterSpacing: 3
    }
    Text {
        id: timeText
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 125 - height / 2
        color: root.cText
        font.family: ndot.font.family
        font.pixelSize: 160
    }

    // Login block on every screen: SDDM's primaryScreen flag is unreliable under weston
    Item {
        anchors.fill: parent

        // User pills
        Row {
            id: users
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 + 60
            spacing: 10
            Repeater {
                id: userRepeater
                model: userModel
                delegate: Rectangle {
                    required property int index
                    required property string name
                    required property string realName
                    // first boot: SDDM remembers no user yet, so take the first one
                    Component.onCompleted: if (root.userName.length === 0 && index === 0) root.userName = name
                    readonly property bool selected: name === root.userName
                    width: label.implicitWidth + 28
                    height: 30
                    radius: 15
                    color: selected ? root.cText : "transparent"
                    border.width: 1
                    border.color: selected ? root.cText : root.cOutline
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: (parent.realName && parent.realName.length ? parent.realName : parent.name).toUpperCase()
                        color: parent.selected ? "#000000" : root.cDim
                        font.family: lettera.font.family
                        font.pixelSize: 12
                        font.letterSpacing: 1.5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.userName = parent.name; input.forceActiveFocus(); }
                    }
                }
            }
        }

        // Password pill
        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            y: users.y + users.height + 22
            width: 340
            height: 54
            radius: 27
            color: "#CC000000"
            border.width: 1
            border.color: root.failed ? root.cAccent : (input.activeFocus ? root.cText : root.cOutline)
            Behavior on border.color { ColorAnimation { duration: 160 } }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: root.cText
                font.family: lettera.font.family
                font.pixelSize: 14
                font.letterSpacing: 4
                selectionColor: root.cText
                selectedTextColor: "#000000"
                focus: true
                enabled: !root.busy
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
            }
            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0 && !root.failed
                text: root.busy ? "SIGNING IN" : "ENTER PASSWORD"
                color: root.cFaint
                font.family: lettera.font.family
                font.pixelSize: 12
                font.letterSpacing: 2
            }
            Text {
                anchors.centerIn: parent
                visible: root.failed && input.text.length === 0
                text: "WRONG PASSWORD"
                color: root.cAccent
                font.family: lettera.font.family
                font.pixelSize: 12
                font.letterSpacing: 2
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: field.y + field.height + 16
            visible: typeof keyboard !== "undefined" && keyboard.capsLock
            text: "CAPS LOCK"
            color: root.cAccent
            font.family: lettera.font.family
            font.pixelSize: 11
            font.letterSpacing: 2
        }

        // Session, bottom-left: click cycles through the installed sessions
        Item {
            id: sessionBox
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 36
            anchors.bottomMargin: 30
            width: 260
            height: 20
            Repeater {
                id: sessionRepeater
                model: sessionModel
                delegate: Text {
                    required property int index
                    required property string name
                    required property string file
                    visible: index === root.sessionIndex
                    text: "●  " + name.toUpperCase()
                    color: root.cDim
                    font.family: lettera.font.family
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.count
            }
        }

        // Power actions, bottom-right
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 36
            anchors.bottomMargin: 30
            spacing: 28
            Repeater {
                model: [
                    { label: "SLEEP", can: sddm.canSuspend, run: function() { sddm.suspend(); } },
                    { label: "RESTART", can: sddm.canReboot, run: function() { sddm.reboot(); } },
                    { label: "SHUT DOWN", can: sddm.canPowerOff, run: function() { sddm.powerOff(); } }
                ]
                delegate: Text {
                    required property var modelData
                    visible: modelData.can
                    text: modelData.label
                    color: hover.containsMouse ? root.cText : root.cDim
                    font.family: lettera.font.family
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.run()
                    }
                }
            }
        }
    }

    function login() {
        if (root.busy || input.text.length === 0) return;
        if (root.userName.length === 0 && userRepeater.count > 0) root.userName = userRepeater.itemAt(0).name;
        if (root.userName.length === 0) return;
        root.failed = false;
        root.busy = true;
        sddm.login(root.userName, input.text, root.sessionIndex);
    }

    Timer { id: failTimer; interval: 2500; onTriggered: root.failed = false }
    Connections {
        target: sddm
        function onLoginFailed() { root.busy = false; root.failed = true; input.text = ""; failTimer.restart(); input.forceActiveFocus(); }
        function onLoginSucceeded() { root.busy = false; }
    }
    // First login with no remembered session: prefer config.defaultSession (theme.conf) over index 0
    function pickDefaultSession() {
        if (sessionModel.lastIndex > 0 || typeof config === "undefined" || !config.defaultSession) return;
        for (let i = 0; i < sessionRepeater.count; i++) {
            const it = sessionRepeater.itemAt(i);
            if (it && String(it.file).endsWith(config.defaultSession)) { root.sessionIndex = i; return; }
        }
    }
    Component.onCompleted: { pickDefaultSession(); input.forceActiveFocus(); }
}
