#!/usr/bin/env bash

current_hour=$(date +%H)

if ((current_hour >= 19 || current_hour < 6)); then
  hyprctl hyprsunset temperature 3300
else
  hyprctl hyprsunset identity
fi

exit 0
