#!/usr/bin/env bash
# Nothing OS boot chain for Fedora: SDDM with the Nothing greeter (replacing GDM at next boot),
# the Nothing plymouth theme, and Fedora's hidden GRUB menu.
#   sudo ~/.local/share/nothing-boot/fedora/install.sh [--x11] [--no-sddm] [--no-plymouth] [--no-grub] [--keep-cmdline]
# --x11           use the Xorg greeter (sddm-x11) instead of the Wayland one (sddm-wayland-generic, weston)
# --keep-cmdline  do not add "rhgb quiet" to the kernel command line (plymouth stays invisible without rhgb)
# Nothing here stops the running session: GDM keeps running until you reboot. Undo with uninstall.sh.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT="$(cd "$SRC/.." && pwd)"
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
DO_SDDM=1 DO_PLY=1 DO_GRUB=1 GREETER=wayland KEEP_CMDLINE=0
for a in "$@"; do
  case $a in
    --no-sddm) DO_SDDM=0 ;; --no-plymouth) DO_PLY=0 ;; --no-grub) DO_GRUB=0 ;;
    --x11) GREETER=x11 ;; --keep-cmdline) KEEP_CMDLINE=1 ;;
    *) echo "unknown option $a"; exit 1 ;;
  esac
done

if (( DO_SDDM )); then
  echo "== SDDM ($GREETER greeter)"
  if [[ $GREETER == x11 ]]; then dnf install -y sddm sddm-x11; else dnf install -y sddm sddm-wayland-generic; fi
  rm -rf /usr/share/sddm/themes/nothing
  cp -r "$BOOT/sddm/nothing" /usr/share/sddm/themes/nothing
  rm -f /usr/share/sddm/themes/nothing/preview.qml
  chmod -R a+rX /usr/share/sddm/themes/nothing
  mkdir -p /etc/sddm.conf.d
  {
    echo "[Theme]"; echo "Current=nothing"; echo
    echo "[General]"; echo "InputMethod="; echo "Numlock=none"
    # Fedora's sddm build already defaults to DisplayServer=wayland with "weston --shell=kiosk"
    # (see `sddm --example-config`); write it explicitly so the intent survives a packaging change.
    if [[ $GREETER == wayland ]]; then
      echo "DisplayServer=wayland"; echo
      echo "[Wayland]"; echo "CompositorCommand=weston --shell=kiosk"
    fi
    echo; echo "[Users]"; echo "RememberLastUser=true"; echo "RememberLastSession=true"
  } > /etc/sddm.conf.d/zz-nothing.conf
  systemctl disable gdm.service
  systemctl enable sddm.service
  echo "   SDDM enabled for the next boot; GDM stays up until then."
fi

if (( DO_PLY )); then
  echo "== plymouth"
  dnf install -y plymouth-plugin-script
  rm -rf /usr/share/plymouth/themes/nothing
  cp -r "$BOOT/plymouth/nothing" /usr/share/plymouth/themes/nothing
  plymouth-set-default-theme -R nothing
  if (( ! KEEP_CMDLINE )) && ! grep -qw rhgb /proc/cmdline; then
    grubby --update-kernel=ALL --args="rhgb quiet"
    echo "   added 'rhgb quiet' to every kernel entry (plymouth needs rhgb to show a splash)"
  fi
fi

if (( DO_GRUB )); then
  echo "== GRUB"
  grub2-editenv - set menu_auto_hide=1
  echo "   menu hidden after a successful boot; hold Shift or press Esc during boot to show it"
fi
echo "done. Reboot to see it. Undo: sudo $SRC/uninstall.sh"