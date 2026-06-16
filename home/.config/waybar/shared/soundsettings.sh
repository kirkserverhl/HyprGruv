"custom/wallpaper": {
"format": "\uf03e",
"on-click": "waypaper",
"on-click-right": "~/.config/hypr/scripts/decorations.sh",
"tooltip-format": "Left: Wallpaper\nRight: Decorations"
},
"custom/waybarthemes": {
"format": "\uf141",
"on-click": "~/.config/hypr/scripts/themeswitcher.sh",
"on-click-right": "~/.config/hypr/scripts/animations.sh",
"tooltip-format": "Left: Waybar themes\nRight: Animations"
},

"group/settings": {
"orientation": "inherit",
"drawer": {
"transition-duration": 300,
"children-class": "not-memory",
"transition-left-to-right": true
},
"modules": ["custom/settings", "custom/waybarthemes", "custom/wallpaper"]
},
