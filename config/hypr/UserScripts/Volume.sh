#!/usr/bin/env bash
# NOTHING-SHELL: volume keys. WirePlumber makes the change; the shell's OSD follows PipeWire by itself.
sink=@DEFAULT_AUDIO_SINK@
src=@DEFAULT_AUDIO_SOURCE@
case "$1" in
    --inc)         wpctl set-volume -l 1.0 "$sink" 5%+ && wpctl set-mute "$sink" 0 ;;
    --dec)         wpctl set-volume "$sink" 5%- ;;
    --inc-precise) wpctl set-volume -l 1.0 "$sink" 1%+ && wpctl set-mute "$sink" 0 ;;
    --dec-precise) wpctl set-volume "$sink" 1%- ;;
    --toggle)      wpctl set-mute "$sink" toggle ;;
    --toggle-mic)  wpctl set-mute "$src" toggle ;;
    *) echo "usage: $0 --inc|--dec|--inc-precise|--dec-precise|--toggle|--toggle-mic" >&2; exit 1 ;;
esac
