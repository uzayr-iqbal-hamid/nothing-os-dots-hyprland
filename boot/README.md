# Nothing OS boot chain

Staging for the parts that need root. Everything else in the Nothing setup lives in the home directory.

- `sddm/nothing/` — SDDM greeter theme (Qt 6 QML) mirroring hyprlock: dimmed glyph wallpaper, Ndot clock,
  letter-spaced date, user pills, pill password field, session switcher bottom-left, SLEEP / RESTART / SHUT DOWN
  bottom-right. Fonts ship inside the theme. Preview without installing:
  `qs -p ~/.local/share/nothing-boot/sddm/nothing/preview.qml` (quickshell window with mocked SDDM objects).
- `plymouth/nothing/` — script-plugin theme: black, dot-matrix "fedora." wordmark, 24-dot progress ring with an
  orbiting red dot. `logo.png` comes from `~/.config/fastfetch/nothing-logo.py`.
- `fedora/install.sh` / `fedora/uninstall.sh` — Fedora boot integration; run with sudo.
- `arch/install.sh` / `arch/uninstall.sh` — complete Arch installer and boot integration.

Choose exactly one boot path. On Fedora, run `sudo ~/.local/share/nothing-boot/fedora/install.sh`.
On Arch, run `bash ~/nothing-os-dots-hyprland/boot/arch/install.sh` from the repository.
If the Fedora Wayland greeter does not appear after reboot, switch to a VT (Ctrl+Alt+F3), log in,
and run `sudo ~/.local/share/nothing-boot/fedora/install.sh --x11 --no-plymouth --no-grub`.
Use the matching `uninstall.sh` to undo the integration. On Arch, run
`sudo bash ~/nothing-os-dots-hyprland/boot/arch/uninstall.sh`.
Test the greeter in place after installing: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/nothing`.
