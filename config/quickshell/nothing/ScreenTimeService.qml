pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Screen time: seconds of active use per day, in total and per app. App keys are DockState's
// (desktop entry id, else window class). Time counts only while you're active: input within
// idleSeconds, or an idle inhibitor such as a playing video. The focused window gets the time; time
// with nothing focused (an empty workspace) only adds to the total. Days are kept in the state dir.
Singleton {
    id: root

    readonly property int idleSeconds: 180
    readonly property int tickSeconds: 30
    readonly property int keepDays: 30

    // { "yyyy-MM-dd": { total: seconds, apps: { key: seconds } } }, mutated in place
    property var days: ({})
    // bumped on every change: bindings read it to notice the in-place updates
    property int revision: 0
    property bool ready: false
    property string today: dayKey(new Date())

    readonly property bool tracking: ready && !idle.isIdle
    readonly property string focusedKey: Hyprland.activeToplevel ? DockState.keyFor(Hyprland.activeToplevel) : ""

    readonly property real todayTotal: {
        revision;
        return days[today]?.total ?? 0;
    }
    // app keys, most used first
    readonly property var todayRanking: {
        revision;
        const apps = days[today]?.apps ?? {};
        return Object.keys(apps).sort((a, b) => apps[b] - apps[a]);
    }

    property string countingKey: ""
    property real stamp: Date.now()
    property bool dirty: false

    function todaySeconds(key) {
        revision;
        return days[today]?.apps[key] ?? 0;
    }

    function dayKey(date) {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function add(seconds, key) {
        const day = dayKey(new Date());
        if (day !== today) {
            today = day;
            prune();
        }
        const entry = days[day] ?? (days[day] = { total: 0, apps: {} });
        entry.total = Math.max(0, entry.total + seconds);
        if (key)
            entry.apps[key] = Math.max(0, (entry.apps[key] ?? 0) + seconds);
        persist.snapshot = JSON.stringify(days);
        dirty = true;
        revision++;
    }

    // Credit the time since the last stamp to the app that had focus, then follow the new focus.
    // Gaps longer than a few ticks (suspend) aren't counted.
    function settle() {
        const now = Date.now();
        const elapsed = (now - stamp) / 1000;
        stamp = now;
        if (tracking && elapsed > 0 && elapsed <= tickSeconds * 3)
            add(elapsed, countingKey);
        countingKey = focusedKey;
    }

    function prune() {
        const cutoff = dayKey(new Date(Date.now() - keepDays * 86400000));
        for (const day of Object.keys(days))
            if (day < cutoff)
                delete days[day];
    }

    function save() {
        if (!dirty)
            return;
        file.setText(JSON.stringify(days));
        dirty = false;
    }

    onFocusedKeyChanged: settle()

    onTrackingChanged: {
        const now = Date.now();
        if (tracking) {
            // back from idle, or just loaded: start a fresh interval
            stamp = now;
            countingKey = focusedKey;
        } else if (ready) {
            // went idle: count up to now, then take back the idle wait, which had no input
            const elapsed = (now - stamp) / 1000;
            stamp = now;
            if (elapsed <= tickSeconds * 3)
                add(elapsed - idleSeconds, countingKey);
        }
    }

    // Carries the counts across config reloads, which would otherwise race the file: the new config
    // reads it before the old one's last save. Kept as JSON, not objects from the old JS engine.
    PersistentProperties {
        id: persist
        reloadableId: "screenTime"

        property string snapshot: ""

        onReloaded: {
            if (!snapshot)
                return;
            root.days = JSON.parse(snapshot);
            root.ready = true;
            root.revision++;
        }
    }

    IdleMonitor {
        id: idle
        timeout: root.idleSeconds
        respectInhibitors: true
    }

    Timer {
        interval: root.tickSeconds * 1000
        running: root.tracking
        repeat: true
        onTriggered: root.settle()
    }

    Timer {
        interval: 60000
        running: root.ready
        repeat: true
        onTriggered: root.save()
    }

    FileView {
        id: file
        path: Quickshell.statePath("screentime.json")
        printErrors: false
        onLoaded: {
            if (root.ready)
                return; // our own writes, or already restored across a reload
            try {
                root.days = JSON.parse(text());
            } catch (e) {
                console.warn("screen time: couldn't read", path, e);
            }
            root.prune();
            root.ready = true;
            root.revision++;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("screen time: couldn't read", path, FileViewError.toString(error));
            root.ready = true; // first run: nothing saved yet
        }
    }

    // shutdown: keep what was counted since the last save
    Component.onDestruction: {
        try {
            settle();
            save();
            file.waitForJob();
        } catch (e) {}
    }
}
