# Patches to JaKooLit's vendor files

These are the only edits made outside `UserConfigs/` / `UserScripts/`. KooL's updater overwrites
these files, so re-apply after every `update-dots.sh`. Every changed line carries a `NOTHING-SHELL`
comment (except in swaync's `config.json`, since JSON has no comments); find them with `grep -rn NOTHING-SHELL ~/.config/hypr ~/.config/quickshell`.

Diffs are against Hyprland-Dots **v2.3.19** (the installed copy reported itself as 2.3.20, a
post-release snapshot).

| Patch | Why |
| --- | --- |
| `Startup_Apps.conf.patch` | Stop launching waybar (the Quickshell bar replaces it); the vendor file listed `qs -c overview` twice, which started two overview processes on every login. |
| `Refresh.sh.patch` | KooL's refresh (runs after wallpaper changes) restarted waybar and ran `pkill qs`, which killed the whole Nothing shell. |
| `RefreshNoWaybar.sh.patch` | Same `pkill qs` line. |
| `swaync-config.json.patch` | Notification panel: opens on the right under the bar, and drops its do-not-disturb, button grid, volume and brightness widgets (the bar's bell and the control center have those), leaving media, title and notifications. |
| `Appearance.qml.patch` | KooL's Quickshell overview (Super+A): Nothing palette, Lettera Mono / Ndot fonts, 16 px radii. `qml_color.json` and `config.json` never reach these properties (the loaders assign keys that do not exist), so the defaults are what you see. |

Apply them with `./apply.sh` (uses `git apply` inside `~/.config`, skips patches already applied).
