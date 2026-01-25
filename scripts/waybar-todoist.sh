#!/bin/bash

todoist_command="${TODOIST_BIN:-todoist}"

if ! command -v "$todoist_command" >/dev/null 2>&1 || ! "$todoist_command" list &>/dev/null; then
    printf '{"text": "ERR: Todoist", "tooltip": "Todoist CLI not found or not configured. (Check mise or API token)"}\n'
    exit 0
fi

# --- Main Logic ---

ALL_FORMATTED_FOR_TOOLTIP=() # Stores tasks as "Date (Project Label) Name"
ALL_TEXT_ONLY_NAMES=()       # Stores tasks as "Name" for the main text display

# Get raw task list output in CSV format, filtered by "@important" label.
raw_task_output=$("$todoist_command" --csv list -f "@important" 2>/dev/null)

if [ -z "$raw_task_output" ]; then
    printf '{"text": "Chilling", "tooltip": "No tasks found with @important label."}\n'
    exit 0
fi

# Process each CSV line using AWK for robust parsing and formatting.
# AWK will output two lines for each task:
#   Line 1: Formatted for tooltip (e.g., "25/07/16(Wed) 00:00 (personal App Idea @important) penguine crochet")
#   Line 2: Formatted for text display (e.g., "penguine crochet")
parsed_output_lines=$(echo "$raw_task_output" | awk '
BEGIN { FS = "," } # Set field separator to comma

{
    # Assign CSV fields to variables
    # $1: id (unused for display here)
    # $2: priority (unused for display here)
    date_raw = $3;     # e.g., "25/07/16(Wed) 00:00" or ""
    project_raw = $4;  # e.g., "#personal/App Idea" or ""
    labels_raw = $5;   # e.g., "@important" or ""
    content_raw = $6;  # e.g., "penguine crochet"

    # --- Format Project and Labels for Tooltip ---
    project_labels_display = ""; # To hold "(Project Label)" part for tooltip
    
    # Process Project field
    if (project_raw != "") {
        cleaned_project_name = project_raw;
        gsub(/^#/, "", cleaned_project_name); # Remove leading '#'
        gsub(/\//, " ", cleaned_project_name); # Replace '/' with space
        project_labels_display = cleaned_project_name;
    }

    # Process Labels field
    if (labels_raw != "") {
        cleaned_labels = labels_raw;
        gsub(/^@/, "", cleaned_labels); # Remove leading '@'
        gsub(/@/, "", cleaned_labels); # Remove any other '@' within labels
        gsub(/,/, " ", cleaned_labels); # Replace commas with spaces
        
        # Combine project and labels for display
        if (project_labels_display == "") {
            project_labels_display = cleaned_labels;
        } else {
            project_labels_display = project_labels_display " " cleaned_labels;
        }
    }

    # Add parentheses if project/labels exist for tooltip
    if (project_labels_display != "") {
        project_labels_display = "(" project_labels_display ")";
    }


    # --- Construct current_tooltip_string (Date (Project Labels) Task Name) ---
    current_tooltip_string = "";
    if (date_raw != "") {
        current_tooltip_string = date_raw;
    }
    if (project_labels_display != "") {
        if (current_tooltip_string != "") current_tooltip_string = current_tooltip_string " ";
        current_tooltip_string = current_tooltip_string project_labels_display;
    }
    if (content_raw != "") {
        if (current_tooltip_string != "") current_tooltip_string = current_tooltip_string " ";
        current_tooltip_string = current_tooltip_string content_raw;
    }
    
    # --- Construct current_text_name (Task Name only) ---
    current_text_name = content_raw;

    # Print formatted strings for the shell script to read (one per line)
    print current_tooltip_string;
    print current_text_name;
}
')

# Read parsed output from awk into arrays (pairs of tooltip_string and text_name)
while IFS= read -r current_tooltip_string && IFS= read -r current_text_name; do
    if [[ -n "$current_tooltip_string" ]]; then # Ensure tooltip string is not empty
        ALL_FORMATTED_FOR_TOOLTIP+=("$current_tooltip_string")
        ALL_TEXT_ONLY_NAMES+=("$current_text_name")
    fi
done <<<"$parsed_output_lines"

# Get the last task name for the main Waybar text display
LAST_TASK_FOR_TEXT="No important tasks."
if [ "${#ALL_TEXT_ONLY_NAMES[@]}" -gt 0 ]; then
    LAST_TASK_FOR_TEXT="${ALL_TEXT_ONLY_NAMES[-1]}"
fi

# Create the full tooltip string by joining all formatted tasks with newlines
TOOLTIP_CONTENT=$(printf "%s\n" "${ALL_FORMATTED_FOR_TOOLTIP[@]}")

# Manually escape text and tooltip content for JSON safety.
escaped_text=$(printf "%s" "$LAST_TASK_FOR_TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')
escaped_tooltip=$(printf "%s" "$TOOLTIP_CONTENT" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Output the final, manually-crafted JSON for Waybar
printf '{"text": "%s", "tooltip": "%s"}\n' \
    "$escaped_text" \
    "$escaped_tooltip"

exit 0
