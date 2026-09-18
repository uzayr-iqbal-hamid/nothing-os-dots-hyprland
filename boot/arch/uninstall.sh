#!/usr/bin/env bash
# Remove Arch boot integration installed by boot/arch/install.sh.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
systemctl disable sddm.service 2>/dev/null || true
rm -f /etc/sddm.conf.d/zz-nothing.conf
rm -rf /usr/share/sddm/themes/nothing

if [[ -d /usr/share/plymouth/themes/nothing ]]; then
  plymouth-set-default-theme -R bgrt 2>/dev/null || true
  rm -rf /usr/share/plymouth/themes/nothing
fi

if [[ -f /etc/default/grub.nothing-arch.bak ]]; then
  mv /etc/default/grub.nothing-arch.bak /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "Nothing Arch boot integration removed. Enable your previous display manager if needed."