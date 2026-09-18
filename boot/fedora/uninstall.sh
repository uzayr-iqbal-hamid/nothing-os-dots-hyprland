#!/usr/bin/env bash
# Revert the Fedora boot installer: GDM back as display manager, plymouth back to bgrt,
# and the GRUB menu visible again.
# Packages stay installed; "rhgb quiet" stays on the kernel command line (Fedora's default anyway).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
systemctl disable sddm.service 2>/dev/null || true
systemctl enable gdm.service
rm -f /etc/sddm.conf.d/zz-nothing.conf
rm -rf /usr/share/sddm/themes/nothing
if [[ -d /usr/share/plymouth/themes/nothing ]]; then
  plymouth-set-default-theme -R bgrt
  rm -rf /usr/share/plymouth/themes/nothing
fi
grub2-editenv - unset menu_auto_hide
echo "reverted; reboot to get GDM back"