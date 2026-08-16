#!/usr/bin/env bash
# First-letter mnemonics for no-search rofi menus.
#
# Unique first letters win (Exit keeps E even if Settings also has e).
# Colliding first letters fall through to the next free letter in the label
# (Clear/Cancel → C and a). Binds a-z / 0-9 via -kb-custom-N (rofi exit 10–28).

hyprgruv_rofi_pango_escape() {
    local s=$1
    s=${s//&/&amp;}
    s=${s//</&lt;}
    s=${s//>/&gt;}
    printf '%s' "$s"
}

hyprgruv_rofi_strip_markup() {
    local s=$1
    s=${s//&amp;/&}
    s=${s//&lt;/<}
    s=${s//&gt;/>}
    printf '%s' "$s" | sed 's/<[^>]*>//g'
}

# First a-z / 0-9 in the label (skips emoji, checkboxes, punctuation).
hyprgruv_rofi_first_alnum() {
    local label=$1 i c
    for ((i = 0; i < ${#label}; i++)); do
        c=${label:i:1}
        c=${c,,}
        if [[ "$c" == [[:alnum:]] ]]; then
            printf '%s' "$c"
            return 0
        fi
    done
    return 1
}

hyprgruv_rofi_mnemonic_markup() {
    local label=$1 key=$2
    if [[ -z "$key" ]]; then
        hyprgruv_rofi_pango_escape "$label"
        return 0
    fi
    local i c
    local key_lc=${key,,}
    for ((i = 0; i < ${#label}; i++)); do
        c=${label:i:1}
        if [[ "${c,,}" == "$key_lc" ]]; then
            printf '%s<u>%s</u>%s' \
                "$(hyprgruv_rofi_pango_escape "${label:0:i}")" \
                "$(hyprgruv_rofi_pango_escape "$c")" \
                "$(hyprgruv_rofi_pango_escape "${label:i+1}")"
            return 0
        fi
    done
    hyprgruv_rofi_pango_escape "$label"
}

# Fills HYPRGRUV_ROFI_KEYS and HYPRGRUV_ROFI_MARKUP (parallel to "$@").
hyprgruv_rofi_assign_mnemonics() {
    HYPRGRUV_ROFI_KEYS=()
    HYPRGRUV_ROFI_MARKUP=()
    local -a labels=("$@")
    local -a firsts=()
    local -A count=()
    local -A used=()
    local label first key i c

    for label in "${labels[@]}"; do
        first=$(hyprgruv_rofi_first_alnum "$label" || true)
        firsts+=("$first")
        if [[ -n "$first" ]]; then
            count[$first]=$((${count[$first]:-0} + 1))
        fi
    done

    for i in "${!labels[@]}"; do
        first=${firsts[$i]}
        if [[ -n "$first" && ${count[$first]} -eq 1 ]]; then
            HYPRGRUV_ROFI_KEYS+=("$first")
            used[$first]=1
        else
            HYPRGRUV_ROFI_KEYS+=("")
        fi
    done

    for i in "${!labels[@]}"; do
        [[ -n "${HYPRGRUV_ROFI_KEYS[$i]}" ]] && continue
        label=${labels[$i]}
        key=""
        for ((c = 0; c < ${#label}; c++)); do
            first=${label:c:1}
            first=${first,,}
            [[ "$first" == [[:alnum:]] ]] || continue
            [[ -n "${used[$first]:-}" ]] && continue
            key=$first
            used[$first]=1
            break
        done
        HYPRGRUV_ROFI_KEYS[$i]=$key
    done

    for i in "${!labels[@]}"; do
        HYPRGRUV_ROFI_MARKUP+=("$(hyprgruv_rofi_mnemonic_markup "${labels[$i]}" "${HYPRGRUV_ROFI_KEYS[$i]}")")
    done
}

# Fills HYPRGRUV_ROFI_CUSTOM_MAP[N]=label_index and HYPRGRUV_ROFI_KB_ARGS.
hyprgruv_rofi_bind_mnemonics() {
    HYPRGRUV_ROFI_CUSTOM_MAP=()
    HYPRGRUV_ROFI_KB_ARGS=(-markup-rows)
    local i n=1 key
    for i in "${!HYPRGRUV_ROFI_KEYS[@]}"; do
        key=${HYPRGRUV_ROFI_KEYS[$i]}
        [[ -n "$key" ]] || continue
        ((n > 19)) && break
        if [[ "$key" == [[:alpha:]] ]]; then
            HYPRGRUV_ROFI_KB_ARGS+=(-kb-custom-$n "${key},${key^^}")
        else
            HYPRGRUV_ROFI_KB_ARGS+=(-kb-custom-$n "$key")
        fi
        HYPRGRUV_ROFI_CUSTOM_MAP[$n]=$i
        ((n++)) || true
    done
}

# Map a rofi exit + printed row back to the original label.
# Prints the label and returns 0, or returns 1 on cancel.
hyprgruv_rofi_choice_from_exit() {
    local rc=$1 stdout=$2
    shift 2
    local -a labels=("$@")

    if ((rc >= 10 && rc <= 28)); then
        local n=$((rc - 9))
        local idx=${HYPRGRUV_ROFI_CUSTOM_MAP[$n]:-}
        if [[ -n "$idx" ]]; then
            printf '%s' "${labels[$idx]}"
            return 0
        fi
        return 1
    fi
    ((rc == 0)) || return 1
    [[ -n "$stdout" ]] || return 1

    local plain lab
    plain=$(hyprgruv_rofi_strip_markup "$stdout")
    for lab in "${labels[@]}"; do
        if [[ "$plain" == "$lab" ]]; then
            printf '%s' "$lab"
            return 0
        fi
    done
    printf '%s' "$plain"
    return 0
}

# hyprgruv_rofi_menu PROMPT CONFIG item...
# CONFIG may be empty. Prints the original item text (no markup).
hyprgruv_rofi_menu() {
    local prompt=$1 config=$2
    shift 2
    local -a items=("$@")
    ((${#items[@]} > 0)) || return 1

    hyprgruv_rofi_assign_mnemonics "${items[@]}"
    hyprgruv_rofi_bind_mnemonics

    local out rc=0
    local -a cmd=(rofi -dmenu -i -p "$prompt" "${HYPRGRUV_ROFI_KB_ARGS[@]}")
    [[ -n "$config" ]] && cmd+=(-config "$config")

    out=$(printf '%s\n' "${HYPRGRUV_ROFI_MARKUP[@]}" | "${cmd[@]}") || rc=$?
    hyprgruv_rofi_choice_from_exit "$rc" "$out" "${items[@]}"
}
