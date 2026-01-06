#!/bin/bash

# Define browser
BROWSER="chromium"

# Define rooms
declare -A rooms
rooms=(
    ["Rick 🧪"]="https://meet.google.com/ynu-tcbv-uko"
    ["Morty ⚠️"]="https://meet.google.com/hnd-dwjh-dpq"
    ["Status 📊"]="https://meet.google.com/rfi-ushg-iov"
)

# --- Selection Logic ---

# Check if gum is installed for a pretty menu, otherwise fall back to fzf
if command -v gum &> /dev/null; then
    # Extract keys, sort them, and pipe to gum
    CHOICE=$(printf "%s\n" "${!rooms[@]}" | sort | gum choose --header "Select Meeting Room")
else
    # Fallback to fzf
    CHOICE=$(printf "%s\n" "${!rooms[@]}" | sort | fzf --height 20% --reverse --prompt="Select Room > ")
fi

# --- Execution ---

if [ -n "$CHOICE" ]; then
    URL="${rooms[$CHOICE]}"

    # Notify user (requires libnotify)
    notify-send "Opening Meeting" "$CHOICE" --icon=google-chrome

    # Launch browser in App mode
    # The --app flag forces the browser to open the URL without address bars/tabs
     # omarchy-launch-webapp $URL & disown
    $BROWSER --app="$URL" & disown
fi
