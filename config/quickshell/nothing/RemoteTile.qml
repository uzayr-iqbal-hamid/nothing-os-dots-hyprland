import QtQuick
import Quickshell
import Quickshell.Io

// Phone remote (~/workspace/hypr-remote): starts and stops its systemd user service, and while it
// runs shows the pairing QR code the server writes to ~/.cache/hypr-remote. Scan it with the phone.
Rectangle {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/hypr-remote"
    property bool active: false
    property bool installed: true
    property string url: ""

    implicitHeight: active && url !== "" ? address.y + address.height + Theme.gapM : 44
    radius: Theme.radiusCard
    color: Theme.surface
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.animMed
            easing.type: Theme.easing
        }
    }

    // Poll only while the control center is open.
    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!status.running)
                status.running = true;
        }
    }

    Process {
        id: status
        command: ["systemctl", "--user", "is-active", "hypr-remote"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim();
                root.active = state === "active" || state === "activating";
                if (root.active && !pairUrl.running)
                    pairUrl.running = true;
            }
        }
    }

    Process {
        id: installCheck
        running: true
        command: ["systemctl", "--user", "cat", "hypr-remote"]
        onExited: code => root.installed = code === 0
    }

    Process {
        id: pairUrl
        command: ["cat", root.cacheDir + "/pair-url"]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = text.trim();
                if (next === root.url)
                    return;
                root.url = next;
                // A new url means a new code: drop the old image and load it again.
                qr.source = "";
                qr.source = "file://" + root.cacheDir + "/pair.png";
            }
        }
    }

    Process {
        id: toggle
        onExited: status.running = true
    }

    Text {
        id: phone
        x: Theme.gapM
        y: (44 - height) / 2
        text: Icons.phone
        color: root.active ? Theme.text : Theme.textDim
        font.family: Theme.fontIcon
        font.pixelSize: 15
    }

    Text {
        anchors.left: phone.right
        anchors.leftMargin: Theme.gapS
        anchors.verticalCenter: phone.verticalCenter
        text: root.installed ? "PHONE REMOTE" : "PHONE REMOTE · RUN INSTALL-SERVICE"
        color: root.active ? Theme.text : Theme.textDim
        font.family: Theme.fontLabel
        font.pixelSize: 9
        font.letterSpacing: Theme.labelSpacing
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.rightMargin: Theme.gapM
        anchors.verticalCenter: phone.verticalCenter
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
        width: parent.width
        height: 44
        cursorShape: Qt.PointingHandCursor
        enabled: root.installed
        onClicked: {
            if (toggle.running)
                return;
            toggle.command = ["systemctl", "--user", root.active ? "stop" : "start", "hypr-remote"];
            toggle.running = true;
        }
    }

    // The code itself: black on white, so phone cameras read it at a glance.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 44 + Theme.gapXs
        width: qr.width + Theme.gapS * 2
        height: qr.height + Theme.gapS * 2
        radius: Theme.radiusSmall
        color: "#FFFFFF"
        opacity: root.active && root.url !== "" ? 1 : 0

        Image {
            id: qr
            anchors.centerIn: parent
            width: 132
            height: 132
            cache: false
            smooth: false
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animMed
            }
        }
    }

    Text {
        id: address
        anchors.horizontalCenter: parent.horizontalCenter
        y: 44 + qr.height + Theme.gapS * 2 + Theme.gapS
        width: parent.width - Theme.gapM * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        // The token stays off screen: this is only to confirm which network the code is for.
        text: root.url.replace(/\?.*$/, "").toLowerCase()
        color: Theme.textDim
        opacity: root.active ? 1 : 0
        font.family: Theme.fontLabel
        font.pixelSize: 9
        font.letterSpacing: Theme.labelSpacing
    }
}
