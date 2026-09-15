#!/usr/bin/env bash
# NOTHING-SHELL: brightness keys. Steps the panel backlight (never below 5%) and shows the shell's OSD.
case "$1" in
    --inc) brightnessctl -q set 5%+ ;;
    --dec) brightnessctl -q --min-value=$(( $(brightnessctl m) / 20 )) set 5%- ;;
    *) echo "usage: $0 --inc|--dec" >&2; exit 1 ;;
esac
qs ipc -c nothing call osd brightness >/dev/null 2>&1
