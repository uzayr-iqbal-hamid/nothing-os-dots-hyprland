// Preview harness: qs -p ~/.local/share/nothing-boot/sddm/nothing/preview.qml  (mocks the SDDM context objects)
import Quickshell
import QtQuick

ShellRoot {
    property var sddm: QtObject {
        signal loginFailed()
        signal loginSucceeded()
        property bool canPowerOff: true
        property bool canReboot: true
        property bool canSuspend: true
        function login(u, p, s) { console.log("login", u, p.length, s); loginFailed(); }
        function powerOff() {} function reboot() {} function suspend() {}
    }
    property var userModel: ListModel {
        property int lastIndex: 0
        property string lastUser: ""
        ListElement { name: "user"; realName: "User"; needsPassword: true }
    }
    property var sessionModel: ListModel {
        property int lastIndex: 0
        ListElement { name: "Hyprland"; file: "hyprland.desktop" }
        ListElement { name: "GNOME"; file: "gnome.desktop" }
    }
    property var keyboard: QtObject { property bool capsLock: false; property bool numLock: false }
    property bool primaryScreen: true

    FloatingWindow {
        title: "SDDM Nothing preview"
        implicitWidth: 1344
        implicitHeight: 756
        color: "black"
        Item {
            width: 1920; height: 1080
            scale: 0.7
            transformOrigin: Item.TopLeft
            Loader { anchors.fill: parent; source: "Main.qml" }
        }
    }
}
