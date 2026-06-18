cd ~/.config/waybar/themes

for theme in alchemy blur-dark blur-light blur-mixed blur-mixed_1 colored dark gruv gruv-blur gruv-modern light modern-colored modern-dark modern-light modern-mixed ultra_minimal velvetline waybar-v1 waybar-v2; do
    if [ -d "$theme" ]; then
        echo "Updating $theme/config.jsonc"
        cat >"$theme/config.jsonc" <<'EOF'
{
    // Shared modules
    "include": "../modules.json",

    // ==================== GENERAL ====================
    "layer": "top",
    "position": "top",
    "height": 42,
    "margin": "8px 12px 0 12px",

    // ==================== LAYOUT ====================
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": [
        "group/hardware",
        "group/tools",
        "network",
        "pulseaudio",
        "battery",
        "clock",
        "custom/exit"
    ]
}
EOF
    fi
done
