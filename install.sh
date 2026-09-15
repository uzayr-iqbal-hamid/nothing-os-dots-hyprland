#!/usr/bin/env bash
# Copy the Nothing OS dotfiles into place. Backs up every file it replaces to
# ~/.config/nothing-dotfiles-backup/<timestamp>/ (same relative paths).
#   ./install.sh [--dry-run] [--no-wallpapers]
# Does NOT touch JaKooLit's vendor files: run patches/apply.sh for those.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0 WALL=1
for a in "$@"; do case $a in --dry-run) DRY=1 ;; --no-wallpapers) WALL=0 ;; *) echo "unknown option $a"; exit 1 ;; esac; done
stamp=$(date +%Y-%m-%d_%H%M%S)
backup="$HOME/.config/nothing-dotfiles-backup/$stamp"

put() { # put SRC DST
  local src=$1 dst=$2
  if (( DRY )); then echo "would copy $src -> $dst"; return; fi
  if [[ -e $dst && ! -d $dst ]]; then
    mkdir -p "$backup/$(dirname "${dst#$HOME/}")"
    cp -a "$dst" "$backup/${dst#$HOME/}"
  fi
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
}

echo "== ~/.config"
while IFS= read -r -d '' f; do
  rel=${f#$here/config/}
  put "$f" "$HOME/.config/$rel"
done < <(find "$here/config" -type f -print0)

echo "== ~/.local/bin"
for f in "$here"/local/bin/*; do put "$f" "$HOME/.local/bin/$(basename "$f")"; done
(( DRY )) || chmod +x "$HOME"/.local/bin/nothing-mono-icons.py "$HOME"/.config/hypr/UserScripts/*.sh "$HOME"/.config/fastfetch/nothing-logo.py

if (( WALL )); then
  echo "== wallpapers -> ~/Pictures/wallpapers/nothing"
  for f in "$here"/wallpapers/*.png; do put "$f" "$HOME/Pictures/wallpapers/nothing/$(basename "$f")"; done
fi

echo "== boot staging -> ~/.local/share/nothing-boot (nothing is installed until you run its install.sh with sudo)"
while IFS= read -r -d '' f; do
  rel=${f#$here/boot/}
  put "$f" "$HOME/.local/share/nothing-boot/$rel"
done < <(find "$here/boot" -type f -print0)
fonts="$HOME/.local/share/fonts/Nothing"
if [[ -f $fonts/Ndot57-Regular.otf && -f $fonts/LetteraMonoLL-Regular.otf ]]; then
  put "$fonts/Ndot57-Regular.otf" "$HOME/.local/share/nothing-boot/sddm/nothing/fonts/Ndot57-Regular.otf"
  put "$fonts/LetteraMonoLL-Regular.otf" "$HOME/.local/share/nothing-boot/sddm/nothing/fonts/LetteraMonoLL-Regular.otf"
else
  echo "   fonts not found in $fonts: copy Ndot57-Regular.otf and LetteraMonoLL-Regular.otf into"
  echo "   ~/.local/share/nothing-boot/sddm/nothing/fonts/ before running the boot installer"
fi

(( DRY )) && { echo "dry run, nothing written"; exit 0; }
[[ -d $backup ]] && echo "replaced files backed up to $backup"
cat <<MSG

Next:
  patches/apply.sh                       # JaKooLit vendor files
  ~/.local/bin/nothing-mono-icons.py     # build the Nothing-Mono icon theme
  see README.md for gsettings, flatpak overrides, fonts, apps
  hyprctl reload && qs -c nothing
MSG
