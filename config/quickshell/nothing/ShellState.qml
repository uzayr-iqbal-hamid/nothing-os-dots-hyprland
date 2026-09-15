pragma Singleton
import QtQuick
import Quickshell

// UI state shared across screens.
Singleton {
    id: root

    // Control center: the screen it lives on ("" = unloaded) and whether it's shown. Closing
    // keeps the screen set until the fade-out finishes; ControlCenter then clears it.
    property string controlCenterScreen: ""
    property bool controlCenterOpen: false

    // Power menu: same open/screen pair as the control center
    property string powerMenuScreen: ""
    property bool powerMenuOpen: false

    // Caffeine: keep the screen awake (idle inhibitor in Bar.qml)
    property bool caffeine: false

    function openControlCenter(screenName) {
        // set "open" first: setting the screen loads the window, which must not see itself as closed
        controlCenterOpen = true;
        controlCenterScreen = screenName;
    }

    function closeControlCenter() {
        controlCenterOpen = false;
    }

    // called by the window once its fade-out ends; ignored if it was reopened meanwhile
    function unloadControlCenter(screenName) {
        if (!controlCenterOpen && controlCenterScreen === screenName)
            controlCenterScreen = "";
    }

    function toggleControlCenter(screenName) {
        if (controlCenterOpen && controlCenterScreen === screenName)
            closeControlCenter();
        else
            openControlCenter(screenName);
    }

    function openPowerMenu(screenName) {
        powerMenuOpen = true;
        powerMenuScreen = screenName;
    }

    function closePowerMenu() {
        powerMenuOpen = false;
    }

    function unloadPowerMenu(screenName) {
        if (!powerMenuOpen && powerMenuScreen === screenName)
            powerMenuScreen = "";
    }

    function togglePowerMenu(screenName) {
        if (powerMenuOpen && powerMenuScreen === screenName)
            closePowerMenu();
        else
            openPowerMenu(screenName);
    }
}
