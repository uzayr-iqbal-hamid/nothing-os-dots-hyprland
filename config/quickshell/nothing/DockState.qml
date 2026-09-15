pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Dock model: pinned apps (desktop entry ids, persisted in the shell's state dir), the apps that
// have windows, and the launch/focus/close actions. An app's key is its desktop entry id, or its
// window class when no entry matches.
Singleton {
    id: root

    // Keep the dock up regardless of hover/workspace (IPC: qs ipc -c nothing call dock toggle)
    property bool forced: false

    readonly property var pinned: Array.from(adapter.pinned)
    readonly property var runningKeys: {
        const keys = [];
        for (const t of Hyprland.toplevels.values) {
            const k = keyFor(t);
            if (k && !keys.includes(k))
                keys.push(k);
        }
        return keys;
    }
    readonly property var apps: pinned.concat(runningKeys.filter(k => !pinned.includes(k)))

    function keyFor(toplevel) {
        const appId = toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "";
        if (!appId)
            return "";
        return DesktopEntries.heuristicLookup(appId)?.id ?? appId;
    }

    function windowsFor(key) {
        return Hyprland.toplevels.values.filter(t => keyFor(t) === key);
    }

    function isPinned(key) {
        return pinned.includes(key);
    }

    function togglePin(key) {
        adapter.pinned = isPinned(key) ? pinned.filter(k => k !== key) : pinned.concat([key]);
    }

    function launch(key) {
        const entry = DesktopEntries.heuristicLookup(key);
        if (entry)
            entry.execute();
        else
            Quickshell.execDetached([key]);
    }

    function address(toplevel) {
        return toplevel.address.startsWith("0x") ? toplevel.address : "0x" + toplevel.address;
    }

    // Focus the app's next window after the active one, switching workspace if needed.
    function focusNext(key) {
        const wins = windowsFor(key);
        if (wins.length === 0)
            return;
        const next = wins[(wins.findIndex(w => w.activated) + 1) % wins.length];
        Hyprland.dispatch("focuswindow address:" + address(next));
    }

    function closeAll(key) {
        for (const w of windowsFor(key))
            Hyprland.dispatch("closewindow address:" + address(w));
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    // lastIpcObject (the class fallback) only fills on refresh
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "openwindow")
                Hyprland.refreshToplevels();
        }
    }

    FileView {
        path: Quickshell.statePath("dock.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property list<string> pinned: ["zen", "kitty", "thunar"]
        }
    }
}
