#!/bin/bash

# Check if the Docker daemon is running
if ! docker info &>/dev/null; then
  exit 0
fi

# Get container counts
running_count=$(docker ps --format '{{.ID}}' | wc -l)

if [ "$running_count" -eq 0 ]; then
  exit 0
fi

total_count=$(docker ps -a --format '{{.ID}}' | wc -l)

# Prepare the tooltip text
tooltip="Running Containers:"
running_names=$(docker ps --format '{{.Names}} ({{.Status}})')

if [ -n "$running_names" ]; then
  tooltip+="$running_names"
else
  tooltip+="None"
fi

# Manually escape the tooltip to be JSON-safe.
# 1. Escape backslashes and double quotes.
# 2. Replace literal newlines with the \n sequence.
escaped_tooltip=$(echo "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Output the final, manually-crafted JSON
printf '{"text": "%s/%s", "tooltip": "%s"}' \
  "$running_count" \
  "$total_count" \
  "$escaped_tooltip"
