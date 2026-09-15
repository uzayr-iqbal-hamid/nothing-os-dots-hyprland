#!/usr/bin/env bash
# NOTHING-SHELL: hypridle's 30-minute action. Suspends on battery; on mains it does nothing.
# `--dry-run` prints the decision instead of suspending.
on_ac=0
for f in /sys/class/power_supply/*/online; do
    [ -r "$f" ] && [ "$(cat "$f")" = "1" ] && on_ac=1
done
if [ "$1" = "--dry-run" ]; then
    if [ "$on_ac" = 1 ]; then echo "on mains: would stay awake"; else echo "on battery: would suspend"; fi
    exit 0
fi
[ "$on_ac" = 1 ] && exit 0
systemctl suspend
