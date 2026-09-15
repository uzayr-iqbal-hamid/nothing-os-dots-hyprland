#!/usr/bin/env bash
# Overview toggle: user override of KooL's scripts/OverviewToggle.sh (bound in UserKeybinds.conf).
# KooL's version checks `pgrep -x quickshell`, but the overview runs as `qs`, so that check
# always fails and every Super+A launched another overview instance. Asking the IPC directly
# needs no process-name guessing: it only fails when no instance is running.

if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
  exit 0
fi

qs -c overview >/dev/null 2>&1 &
disown
for _ in $(seq 20); do
  sleep 0.1
  qs ipc -c overview call overview toggle >/dev/null 2>&1 && exit 0
done

notify-send "Overview" "Quickshell overview failed to start" -u low 2>/dev/null
exit 1
