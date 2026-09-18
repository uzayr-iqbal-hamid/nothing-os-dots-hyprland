#!/usr/bin/env bash
# Install the Arch Linux dependencies, Nothing configuration, and optional boot integration.
# Run this script on Arch Linux, not on Windows.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_PACKAGES=1
INSTALL_BOOT=1
INSTALL_AUR=1
BOOT_ONLY=0
GRUB=0

for arg in "$@"; do
  case "$arg" in
    --no-packages) INSTALL_PACKAGES=0 ;;
    --no-boot) INSTALL_BOOT=0 ;;
    --no-aur) INSTALL_AUR=0 ;;
    --grub) GRUB=1 ;;
    --boot-only) BOOT_ONLY=1 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

[[ -r /etc/os-release ]] || { echo "cannot identify the operating system" >&2; exit 1; }
. /etc/os-release
[[ ${ID:-} == arch || ${ID_LIKE:-} == *arch* ]] || {
  echo "This installer supports Arch Linux only (detected: ${ID:-unknown})." >&2
  exit 1
}
command -v pacman >/dev/null || { echo "pacman is required" >&2; exit 1; }
if (( BOOT_ONLY )); then
  [[ $EUID -eq 0 ]] || { echo "run --boot-only with sudo" >&2; exit 1; }
else
  command -v sudo >/dev/null || { echo "sudo is required" >&2; exit 1; }
fi

packages=(
  hyprland hypridle hyprlock hyprsunset swww rofi-wayland swaync kitty wallust
  brightnessctl wireplumber pavucontrol blueman nvtop python python-pillow
  starship fastfetch btop yazi kvantum qt5ct qt6ct adw-gtk3
  xdg-desktop-portal-hyprland polkit-kde-agent
)

install_boot() {
  local boot="$ROOT/boot"
  pacman -S --needed sddm weston plymouth

  echo "== SDDM"
  systemctl disable gdm.service 2>/dev/null || true
  rm -rf /usr/share/sddm/themes/nothing
  cp -r "$boot/sddm/nothing" /usr/share/sddm/themes/nothing
  rm -f /usr/share/sddm/themes/nothing/preview.qml
  chmod -R a+rX /usr/share/sddm/themes/nothing
  mkdir -p /etc/sddm.conf.d
  cat > /etc/sddm.conf.d/zz-nothing.conf <<'CONF'
[Theme]
Current=nothing

[General]
InputMethod=
Numlock=none

[Wayland]
CompositorCommand=weston --shell=kiosk

[Users]
RememberLastUser=true
RememberLastSession=true
CONF
  systemctl enable sddm.service

  echo "== Plymouth"
  rm -rf /usr/share/plymouth/themes/nothing
  cp -r "$boot/plymouth/nothing" /usr/share/plymouth/themes/nothing
  plymouth-set-default-theme -R nothing

  if (( GRUB )); then
    echo "== GRUB"
    [[ -f /etc/default/grub.nothing-arch.bak ]] || cp /etc/default/grub /etc/default/grub.nothing-arch.bak
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
      sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
    else
      printf '\nGRUB_CMDLINE_LINUX_DEFAULT="quiet splash"\n' >> /etc/default/grub
    fi
    pacman -S --needed grub
    grub-mkconfig -o /boot/grub/grub.cfg
  fi
}

if (( BOOT_ONLY )); then
  install_boot
  echo "done. Reboot to test the Nothing login screen and boot splash."
  exit 0
fi

if (( INSTALL_PACKAGES )); then
  echo "== Arch packages"
  sudo pacman -Syu --needed "${packages[@]}"
fi

if (( INSTALL_AUR )) && ! command -v qs >/dev/null; then
  aur_helper=""
  if command -v paru >/dev/null; then
    aur_helper=paru
  elif command -v yay >/dev/null; then
    aur_helper=yay
  fi
  if [[ -n $aur_helper ]]; then
    echo "== Quickshell"
    "$aur_helper" -S --needed quickshell-git
  else
    echo "Quickshell was not installed: install quickshell-git with paru or yay."
  fi
fi

echo "== Nothing user configuration"
"$ROOT/install.sh"
"$ROOT/patches/apply.sh"

if (( INSTALL_BOOT )); then
  echo "== Arch boot integration"
  boot_args=(--boot-only)
  (( GRUB )) && boot_args+=(--grub)
  sudo bash "$ROOT/boot/arch/install.sh" "${boot_args[@]}"
else
  echo "Boot integration skipped (--no-boot)."
fi

cat <<'MSG'

Next:
  1. Install the fonts listed in README.md.
  2. Run ~/.local/bin/nothing-mono-icons.py.
  3. Configure gsettings and flatpak overrides from README.md.
  4. Log out and start the Nothing shell with: qs -c nothing
MSG