#!/bin/bash
# ____ _ _
# / ___| ___ _ __ ___ ___ _ __ ___| |__ ___ | |_
# \___ \ / __| '__/ _ \/ _ \ '_ \/ __| '_ \ / _ \| __|
# ___) | (__| | | __/ __/ | | \__ \ | | | (_) | |_
# |____/ \___|_| \___|\___|_| |_|___/_| |_|\___/ \__|
#
# Updated from grimblast to hyprshot
# -----------------------------------------------------
# Screenshots will be stored in $HOME by default.
# The screenshot will be moved into the screenshot directory
# Add this to ~/.config/user-dirs.dirs to save screenshots in a custom folder:
# XDG_SCREENSHOTS_DIR="$HOME/Screenshots"

prompt='Screenshot'
mesg="DIR: ~/Screenshots"

# Screenshot Filename
source ~/.config/hypr/scripts/screenshot-filename.sh

# Screenshot Folder
source ~/.config/hypr/scripts/screenshot-folder.sh

# Screenshot Editor (if you still want to use it)
export EDITOR="$(cat ~/.config/hypr/scripts/screenshot-editor.sh)" # renamed for clarity

# Options
option_1="Immediate"
option_2="Delayed"

option_capture_1="Capture Everything"     # output (monitor)
option_capture_2="Capture Active Display" # active output
option_capture_3="Capture Selection"      # region

option_time_1="5s"
option_time_2="10s"
option_time_3="20s"
option_time_4="30s"
option_time_5="60s"

copy='Copy'
save='Save'
copy_save='Copy & Save'
edit='Edit'

# Rofi CMD
rofi_cmd() {
    rofi -dmenu -replace -config ~/.config/rofi/config-screenshot.rasi -i -no-show-icons -l 2 -width 30 -p "Take screenshot"
}

run_rofi() {
    echo -e "$option_1\n$option_2" | rofi_cmd
}

# Timer menu
timer_cmd() {
    rofi -dmenu -replace -config ~/.config/rofi/config-screenshot.rasi -i -no-show-icons -l 5 -width 30 -p "Choose timer"
}

timer_exit() {
    echo -e "$option_time_1\n$option_time_2\n$option_time_3\n$option_time_4\n$option_time_5" | timer_cmd
}

timer_run() {
    selected_timer="$(timer_exit)"
    case "$selected_timer" in
    "$option_time_1") countdown=5 ;;
    "$option_time_2") countdown=10 ;;
    "$option_time_3") countdown=20 ;;
    "$option_time_4") countdown=30 ;;
    "$option_time_5") countdown=60 ;;
    *) exit ;;
    esac
    ${1}
}

# Capture type menu
type_screenshot_cmd() {
    rofi -dmenu -replace -config ~/.config/rofi/config-screenshot.rasi -i -no-show-icons -l 3 -width 30 -p "Type of screenshot"
}

type_screenshot_exit() {
    echo -e "$option_capture_1\n$option_capture_2\n$option_capture_3" | type_screenshot_cmd
}

type_screenshot_run() {
    selected_type="$(type_screenshot_exit)"
    case "$selected_type" in
    "$option_capture_1") option_type="output" ;;
    "$option_capture_2") option_type="active" ;;
    "$option_capture_3") option_type="region" ;;
    *) exit ;;
    esac
    ${1}
}

# Action menu
copy_save_editor_cmd() {
    rofi -dmenu -replace -config ~/.config/rofi/config-screenshot.rasi -i -no-show-icons -l 4 -width 30 -p "How to save"
}

copy_save_editor_exit() {
    echo -e "$copy\n$save\n$copy_save\n$edit" | copy_save_editor_cmd
}

copy_save_editor_run() {
    selected_chosen="$(copy_save_editor_exit)"
    case "$selected_chosen" in
    "$copy") option_chosen="copy" ;;
    "$save") option_chosen="save" ;;
    "$copy_save") option_chosen="copysave" ;;
    "$edit") option_chosen="edit" ;;
    *) exit ;;
    esac
    ${1}
}

# Countdown timer
timer() {
    if [[ $countdown -gt 10 ]]; then
        notify-send -t 1000 "Taking screenshot in ${countdown} seconds"
        sleep $((countdown - 10))
        countdown=10
    fi
    while [[ $countdown -ne 0 ]]; do
        notify-send -t 1000 "Taking screenshot in ${countdown} seconds"
        countdown=$((countdown - 1))
        sleep 1
    done
}

# Main screenshot function
takescreenshot() {
    sleep 1

    local cmd="hyprshot -m $option_type -f \"$NAME\""

    case "$option_chosen" in
    copy)
        cmd+=" --clipboard-only"
        ;;
    save)
        # hyprshot saves by default
        ;;
    copysave)
        # default behavior (save + copy)
        ;;
    edit)
        cmd+=" --clipboard-only" # we'll open editor after
        ;;
    esac

    eval "$cmd"

    # Move to desired folder if saved
    if [[ "$option_chosen" != "copy" && -f "$HOME/$NAME" ]]; then
        if [ -d "$screenshot_folder" ]; then
            mv "$HOME/$NAME" "$screenshot_folder/"
        fi
    fi

    # Handle edit
    if [[ "$option_chosen" == "edit" ]]; then
        if [ -f "$screenshot_folder/$NAME" ]; then
            ${EDITOR} "$screenshot_folder/$NAME"
        elif [ -f "$HOME/$NAME" ]; then
            ${EDITOR} "$HOME/$NAME"
        fi
    fi
}

takescreenshot_timer() {
    sleep 1
    timer
    takescreenshot
}

# Execute Command
run_cmd() {
    if [[ "$1" == '--opt1' ]]; then
        type_screenshot_run
        copy_save_editor_run "takescreenshot"
    elif [[ "$1" == '--opt2' ]]; then
        timer_run
        type_screenshot_run
        copy_save_editor_run "takescreenshot_timer"
    fi
}

# Main
chosen="$(run_rofi)"
case ${chosen} in
"$option_1")
    run_cmd --opt1
    ;;
"$option_2")
    run_cmd --opt2
    ;;
esac
