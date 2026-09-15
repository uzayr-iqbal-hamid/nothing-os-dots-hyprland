#!/usr/bin/env bash
# ---- custom rofi Wi-Fi menu (NetworkManager / nmcli) ----
# Invoked by the waybar `network` module on-click.
# Lists available networks and handles connect / disconnect / enable-disable.

export LC_ALL=C

rofi_menu() { rofi -dmenu -i -p "Wi-Fi" "$@"; }

notify()     { command -v notify-send >/dev/null 2>&1 && notify-send -i network-wireless "Wi-Fi" "$1"; }
notify_err() { command -v notify-send >/dev/null 2>&1 && notify-send -u critical -i network-error "Wi-Fi" "$1"; }

radio="$(nmcli -t -f WIFI radio 2>/dev/null)"

labels=()
keys=()
add() { labels+=("$1"); keys+=("$2"); }

if [ "$radio" = "enabled" ]; then
    nmcli device wifi rescan >/dev/null 2>&1

    active="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
              | awk -F: '$2=="802-11-wireless"{print $1; exit}')"

    [ -n "$active" ] && add "⏏  Disconnect ($active)" "__disconnect"
    add "✖  Disable Wi-Fi"     "__off"
    add "↻  Rescan networks"   "__rescan"
    add "⚙  Connection editor" "__editor"

    # available networks (nmcli already sorts by signal); dedup, skip hidden/empty
    while IFS= read -r ssid; do
        [ -z "$ssid" ] && continue
        skip=0; for k in "${keys[@]}"; do [ "$k" = "$ssid" ] && skip=1 && break; done
        [ "$skip" = 1 ] && continue
        if [ "$ssid" = "$active" ]; then add "●  $ssid" "$ssid"
        else                             add "○  $ssid" "$ssid"; fi
    done < <(nmcli -g SSID device wifi list 2>/dev/null)
else
    add "✓  Enable Wi-Fi" "__on"
fi

idx="$(printf '%s\n' "${labels[@]}" | rofi_menu -format i)"
[ -z "$idx" ] && exit 0
key="${keys[$idx]}"

case "$key" in
    __on)      nmcli radio wifi on ;;
    __off)     nmcli radio wifi off ;;
    __rescan)  nmcli device wifi rescan >/dev/null 2>&1; exec "$0" ;;
    __editor)  setsid -f nm-connection-editor >/dev/null 2>&1 ;;
    __disconnect)
        nmcli connection down "$active" && notify "Disconnected from $active" ;;
    *)
        ssid="$key"
        if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$ssid"; then
            # known network: bring the saved profile up
            nmcli connection up id "$ssid" && notify "Connected to $ssid" || notify_err "Failed to connect to $ssid"
        else
            secured="$(nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null \
                       | awk -F: -v s="$ssid" '$1==s && $2!=""{print $2; exit}')"
            if [ -n "$secured" ] && [ "$secured" != "--" ]; then
                pass="$(rofi -dmenu -password -p "Password for $ssid" < /dev/null)"
                [ -z "$pass" ] && exit 0
                nmcli device wifi connect "$ssid" password "$pass" && notify "Connected to $ssid" || notify_err "Failed to connect to $ssid"
            else
                nmcli device wifi connect "$ssid" && notify "Connected to $ssid" || notify_err "Failed to connect to $ssid"
            fi
        fi ;;
esac
