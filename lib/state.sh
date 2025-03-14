#!/bin/bash
# State management for Hyprgruv installer

STATE_FILE="$CONFIG_DIR/install_state.json"

# Initialize state file if it doesn't exist
init_state() {
    mkdir -p "$CONFIG_DIR"
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" <<EOF
{
  "completed_steps": [],
  "user_choices": {},
  "install_date": "$(date +"%Y-%m-%d %H:%M:%S")",
  "version": "1.0"
}
EOF
    fi
}

# Mark a step as completed
mark_completed() {
    local step="$1"
    # Using jq to update the JSON state file
    if command_exists jq; then
        local temp_file="$(mktemp)"
        jq --arg step "$step" '.completed_steps += [$step]' "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
    else
        # Fallback if jq isn't available
        echo "$step" >> "$CONFIG_DIR/completed_steps.txt"
    fi
}

# Check if a step is already completed
is_completed() {
    local step="$1"
    if command_exists jq; then
        jq -e --arg step "$step" '.completed_steps | contains([$step])' "$STATE_FILE" >/dev/null
    else
        grep -q "^$step$" "$CONFIG_DIR/completed_steps.txt" 2>/dev/null
    fi
}

# Save user choice
save_choice() {
    local key="$1"
    local value="$2"
    if command_exists jq; then
        local temp_file="$(mktemp)"
        jq --arg key "$key" --arg value "$value" '.user_choices[$key] = $value' "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
    else
        echo "$key=$value" >> "$CONFIG_DIR/user_choices.txt"
    fi
}

# Get user choice
get_choice() {
    local key="$1"
    local default="$2"
    if command_exists jq; then
        local value=$(jq -r --arg key "$key" '.user_choices[$key] // ""' "$STATE_FILE")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    else
        if [[ -f "$CONFIG_DIR/user_choices.txt" ]]; then
            local value=$(grep "^$key=" "$CONFIG_DIR/user_choices.txt" | cut -d= -f2)
            if [[ -n "$value" ]]; then
                echo "$value"
                return 0
            fi
        fi
    fi
    echo "$default"
}

# Get user input with remembered choice
ask_with_memory() {
    local key="$1"
    local prompt="$2"
    local default="$3"

    local previous=$(get_choice "$key" "$default")
    if [[ -n "$previous" && "$previous" != "$default" ]]; then
        read -p "$prompt [$previous]: " answer
        answer=${answer:-$previous}
    else
        read -p "$prompt [$default]: " answer
        answer=${answer:-$default}
    fi

    save_choice "$key" "$answer"
    echo "$answer"
}

# Initialize state system
init_state
