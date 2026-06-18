#!/usr/bin/env bash
# Push fonts.sh roles into waypaper-engine config.toml ([app] typography).
set -euo pipefail

FONTS_SH="${FONTS_SH:-$HOME/.config/settings/fonts.sh}"
[[ -f "$FONTS_SH" ]] && source "$FONTS_SH"

CONF="$HOME/.config/waypaper-engine/config.toml"
mkdir -p "$(dirname "$CONF")"

UI_STACK="'\"${FONT_UI:-Agave Nerd Font Propo}\", sans-serif'"
TEXT_STACK="'\"${FONT_TEXT:-ShureTechMono Nerd Font}\", monospace'"

if [[ ! -f "$CONF" ]]; then
    cat > "$CONF" <<EOF
# Managed by ~/.config/settings/apply-fonts.sh
[app]
font_preset = "custom"
font_family_display = $UI_STACK
font_family_body = $UI_STACK
font_family_mono = $TEXT_STACK

[daemon]
compositor = "auto"
EOF
    echo "  ✓ Created waypaper-engine/config.toml with custom fonts"
    exit 0
fi

set_toml_key() {
    local key="$1"
    local value="$2"
    if grep -qE "^${key}[[:space:]]*=" "$CONF"; then
        sed -i "s|^${key}[[:space:]]*=.*|${key} = ${value}|" "$CONF"
    else
        if ! grep -q '^\[app\]' "$CONF"; then
            printf '\n[app]\n' >>"$CONF"
        fi
        sed -i "/^\[app\]/a ${key} = ${value}" "$CONF"
    fi
}

set_toml_key "font_preset" '"custom"'
set_toml_key "font_family_display" "$UI_STACK"
set_toml_key "font_family_body" "$UI_STACK"
set_toml_key "font_family_mono" "$TEXT_STACK"

echo "  ✓ Updated waypaper-engine/config.toml → display/body=$FONT_UI, mono=$FONT_TEXT"