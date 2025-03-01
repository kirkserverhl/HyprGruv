#!/bin/bash

# Define the timestamp file
TIMESTAMP_FILE="$HOME/.last_cleanup_time"

# Function to check if 12 hours have passed
should_run_script() {
    if [[ -f "$TIMESTAMP_FILE" ]]; then
        last_run=$(cat "$TIMESTAMP_FILE")
        current_time=$(date +%s)
        elapsed_time=$((current_time - last_run))

        if (( elapsed_time < 43200 )); then
            echo "Script last ran less than 12 hours ago. Skipping."
            return 1
        fi
    fi

    return 0
}

# Function to update the timestamp
update_timestamp() {
    date +%s > "$TIMESTAMP_FILE"
}

# Function to clean orphaned packages
cleanup_packages() {
    echo "Checking for orphaned packages..."
    orphans=$(yay -Qdtq)

    if [[ -z "$orphans" ]]; then
        echo "No orphaned packages to remove."
    else
        echo "Removing orphaned packages..."
        yay -Rns $orphans
        echo "Orphaned packages removed successfully."
    fi
}

# Function to check for updates
check_updates() {
    echo "Checking for system updates..."
    yay -Syu --noconfirm
    echo "System update check completed."
}

# Function to empty the trash
empty_trash() {
    echo "Emptying the trash..."
    trash_path="$HOME/.local/share/Trash"
    if [[ -d "$trash_path" ]]; then
        rm -rf "$trash_path/"*
        echo "Trash emptied."
    else
        echo "Trash folder not found, skipping."
    fi
}

# Main function to call all tasks
main() {
    echo "Starting system cleanup and update process..."
    cleanup_packages
    check_updates
    empty_trash
    echo "All tasks completed successfully!"
}

# Check if the script should run
if should_run_script; then
    main
    update_timestamp
fi
