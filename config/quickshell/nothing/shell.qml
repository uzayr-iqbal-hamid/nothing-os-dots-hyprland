//@ pragma IconTheme Nothing-Mono
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Nothing shell entry point: per screen, a bar and its control center (loaded only while open);
// desktop widgets and the dock on their configured screens.
// The IconTheme pragma matches the GTK theme (Nothing-Mono, built by ~/.local/bin/nothing-mono-icons.py).
ShellRoot {
    // referencing the tracker starts it, so screen time counts even with no widget on screen
    readonly property bool screenTimeTracking: ScreenTimeService.tracking

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            Bar {
                id: bar
                modelData: perScreen.modelData
            }

            LazyLoader {
                active: ShellState.controlCenterScreen === perScreen.modelData.name

                ControlCenter {
                    screen: perScreen.modelData
                    bar: bar
                }
            }

            LazyLoader {
                active: ShellState.powerMenuScreen === perScreen.modelData.name

                PowerMenu {
                    screen: perScreen.modelData
                }
            }

            LazyLoader {
                active: perScreen.modelData.name === Config.widgetScreen

                DesktopWidgets {
                    targetScreen: perScreen.modelData
                }
            }

            LazyLoader {
                active: Config.glyphScreens.length === 0 || Config.glyphScreens.includes(perScreen.modelData.name)

                Glyph {
                    screen: perScreen.modelData
                }
            }

            LazyLoader {
                active: perScreen.modelData.name === Config.dockScreen

                Dock {
                    screen: perScreen.modelData
                }
            }
        }
    }

    // one OSD window; it moves to whichever screen OsdState names
    Osd {}

    // qs ipc -c nothing call powermenu toggle|open|close, or openOn <output> for a specific screen
    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            ShellState.togglePowerMenu(Hyprland.focusedMonitor?.name ?? "");
        }
        function open(): void {
            ShellState.openPowerMenu(Hyprland.focusedMonitor?.name ?? "");
        }
        function openOn(screen: string): void {
            ShellState.openPowerMenu(screen);
        }
        function close(): void {
            ShellState.closePowerMenu();
        }
    }

    // qs ipc -c nothing call osd volume|mic|brightness (focused screen), or preview <kind> <output>
    IpcHandler {
        target: "osd"

        function volume(): void {
            OsdState.showVolume("");
        }
        function mic(): void {
            OsdState.showMic("");
        }
        function brightness(): void {
            OsdState.showBrightness("");
        }
        function preview(kind: string, screen: string): void {
            if (kind === "brightness")
                OsdState.showBrightness(screen);
            else if (kind === "mic")
                OsdState.showMic(screen);
            else
                OsdState.showVolume(screen);
        }
    }

    // qs ipc -c nothing call controlcenter toggle|open|close (open: 3-finger swipe down, UserSettings.conf)
    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            ShellState.toggleControlCenter(Hyprland.focusedMonitor?.name ?? "");
        }
        function open(): void {
            ShellState.openControlCenter(Hyprland.focusedMonitor?.name ?? "");
        }
        function close(): void {
            ShellState.closeControlCenter();
        }
    }

    // qs ipc -c nothing call dock toggle|open|close (close returns it to auto-hide).
    // Not show/hide: `qs ipc call dock show` is parsed as the `show` subcommand and never calls.
    IpcHandler {
        target: "dock"

        function toggle(): void {
            DockState.forced = !DockState.forced;
        }
        function open(): void {
            DockState.forced = true;
        }
        function close(): void {
            DockState.forced = false;
        }
    }

    // qs ipc -c nothing call caffeine toggle|set true|get
    IpcHandler {
        target: "caffeine"

        function toggle(): void {
            ShellState.caffeine = !ShellState.caffeine;
        }
        function set(enabled: bool): void {
            ShellState.caffeine = enabled;
        }
        function get(): bool {
            return ShellState.caffeine;
        }
    }

    // Glyph lights. Scripts can drive them:
    //   qs ipc -c nothing call glyph play chase       (pulse|double|chase|breathe|rise|sparkle|critical|done)
    //   qs ipc -c nothing call glyph progress 40      (0-100 on the bottom strip; 100 finishes it)
    //   qs ipc -c nothing call glyph timer 300        (seconds; the strip drains, then a chase)
    //   qs ipc -c nothing call glyph clear | demo | toggle | set true | get | music true
    IpcHandler {
        target: "glyph"

        function play(pattern: string): void {
            GlyphService.play(pattern);
        }
        function progress(percent: int): void {
            GlyphService.setProgress(percent);
        }
        function timer(seconds: int): void {
            GlyphService.startTimer(seconds);
        }
        function clear(): void {
            GlyphService.stop();
        }
        function demo(): void {
            GlyphService.demo();
        }
        function toggle(): void {
            GlyphService.setEnabled(!GlyphService.enabled);
        }
        function set(enabled: bool): void {
            GlyphService.setEnabled(enabled);
        }
        function get(): bool {
            return GlyphService.enabled;
        }
        function music(enabled: bool): void {
            GlyphService.setMusic(enabled);
        }
    }

    Component.onCompleted: {
        const fonts = [Theme.fontDot, Theme.fontDotCaps, Theme.fontHead, Theme.fontLabel, Theme.fontSerif, Theme.fontIcon];
        const missing = fonts.filter(f => !Qt.fontFamilies().includes(f));
        if (missing.length)
            console.warn("nothing shell: missing fonts:", missing.join(", "));
        else
            console.info("nothing shell: theme loaded, all fonts present");
    }
}
