#!/bin/bash
# Usage: brightness.sh <up|down>

# Send notification with current brightness level
send_notification() {
  brightness=$(brightnessctl -m | cut -d, -f4)
  notify-send "" -h int:value:"${brightness//%/}" -h string:x-canonical-private-synchronous:brightness
}

case $1 in
up)
  brightnessctl -e4 -n2 set 5%+
  ;;
down)
  brightnessctl -e4 -n2 set 5%-
  ;;
esac

send_notification
