#!/bin/bash
# Touch/mouse-friendly calculator pad for Rofi.
# Uses qalc for evaluation and keeps launcher-matched styling via config-calc-pad.rasi.
#
# Usage:
#   rofi_calc_pad.sh          → numpad mode (default)
#   rofi_calc_pad.sh --classic → original keyboard rofi-calc modi

set -euo pipefail

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyprgruv/calc"
EXPR_FILE="$STATE_DIR/expression"
THEME="$HOME/.config/rofi/config-calc-pad.rasi"
CLASSIC_THEME="$HOME/.config/rofi/config-calc.rasi"

mkdir -p "$STATE_DIR"

read_expr() {
    cat "$EXPR_FILE" 2>/dev/null || true
}

write_expr() {
    printf '%s' "$1" >"$EXPR_FILE"
}

calc_result() {
    local expr="$1"
    [[ -z "$expr" ]] && return 0
    qalc -t "$expr" 2>/dev/null || echo "Error"
}

launch_classic() {
    pkill -x rofi 2>/dev/null || true
    exec rofi -show calc -modi calc -no-show-match -no-sort -replace \
        -config "$CLASSIC_THEME"
}

if [[ "${1:-}" == "--classic" || "${ROFI_CALC_CLASSIC:-}" == "1" ]]; then
    launch_classic
fi

if ! command -v qalc >/dev/null 2>&1; then
    notify-send "Calculator" "qalc is required for the numpad calculator." -u critical 2>/dev/null || true
    exit 1
fi

expr=$(read_expr)
result=$(calc_result "$expr")

format_mesg() {
    if [[ -z "$expr" ]]; then
        echo "Type an expression or tap the pad"
        return
    fi

    if [[ -n "$result" && "$result" != "Error" ]]; then
        local safe_result
        safe_result=$(printf '%s' "$result" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        printf '<span size="large"><b>= %s</b></span>' "$safe_result"
    elif [[ "$result" == "Error" ]]; then
        echo "<span size='small' foreground='#ffb4ab'>Invalid expression</span>"
    fi
}

is_keypad_choice() {
    case "$1" in
        7|8|9|/|4|5|6|\*|1|2|3|-|0|.|⌫|+|'('|')'|C|=|√|^|%|Copy)
            return 0
            ;;
    esac
    return 1
}

build_menu() {
    # 4 columns × 6 rows — numbers, operators, functions, utilities
    printf '%s\n' \
        '7' '8' '9' '/' \
        '4' '5' '6' '*' \
        '1' '2' '3' '-' \
        '0' '.' '⌫' '+' \
        '(' ')' 'C' '=' \
        '√' '^' '%' 'Copy'
}

map_choice() {
    case "$1" in
        ⌫|Backspace|back) echo "__BACK__" ;;
        C|Clear|clear)      echo "__CLEAR__" ;;
        =|Eq|eq)            echo "__EVAL__" ;;
        Copy|copy)           echo "__COPY__" ;;
        √|sqrt|Sqrt)         echo "sqrt(" ;;
        *)                  echo "$1" ;;
    esac
}

pkill -x rofi 2>/dev/null || true

choice=$(
    build_menu | rofi -dmenu \
        -config "$THEME" \
        -markup \
        -mesg "$(format_mesg)" \
        -p "Calc" \
        -filter "$expr" \
        -width 46 \
        2>/dev/null || true
)

[[ -z "$choice" ]] && exit 0

if ! is_keypad_choice "$choice"; then
    write_expr "$choice"
    exec "$0"
fi

action=$(map_choice "$choice")

case "$action" in
    __BACK__)
        write_expr "${expr%?}"
        ;;
    __CLEAR__)
        write_expr ""
        ;;
    __EVAL__)
        if [[ -n "$result" && "$result" != "Error" ]]; then
            write_expr "$result"
            wl-copy -n <<<"$result" 2>/dev/null || true
            notify-send "Calculator" "Result copied: $result" -t 1500 2>/dev/null || true
        fi
        ;;
    __COPY__)
        if [[ -n "$result" && "$result" != "Error" ]]; then
            wl-copy -n <<<"$result" 2>/dev/null || true
            notify-send "Calculator" "Copied: $result" -t 1500 2>/dev/null || true
        fi
        ;;
    *)
        write_expr "${expr}${action}"
        ;;
esac

exec "$0"