#!/usr/bin/env bash
# Apply the Nothing wallpaper set, one composition per monitor, and point rofi/hyprlock at the
# laptop panel's image. Usage: NothingWallpaperApply.sh [dark|light]   (default: dark)
# Regenerate the images with NothingWallpaper.py. KooL's picker (Super+W) still works but sets
# the same image on every output; re-run this script to get the per-monitor set back.
mode="${1:-dark}"
dir="$HOME/Pictures/wallpapers/nothing"
declare -A pick=(
  [eDP-1]="nothing-02-glyph-$mode-1920x1080.png"
  [DP-3]="nothing-03-dots-$mode-1366x768.png"
  [HDMI-A-1]="nothing-05-arc-$mode-1920x1080.png"
)
opts=(--transition-type fade --transition-duration 0.6)
for out in $(swww query | cut -d: -f2 | tr -d ' '); do
  img="$dir/${pick[$out]:-nothing-01-shapes-$mode-1920x1080.png}"
  [[ -f $img ]] && swww img -o "$out" "$img" "${opts[@]}"
done
main="$dir/${pick[eDP-1]}"
ln -sfn "$main" "$HOME/.config/rofi/.current_wallpaper"
cp -f "$main" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
