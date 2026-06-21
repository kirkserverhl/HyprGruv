# Centralized Font System

Single source of truth: **`~/.config/settings/fonts.sh`**

## The Three Roles

| Role         | Default Font                    | Used For                                      |
|--------------|---------------------------------|-----------------------------------------------|
| `FONT_TEXT`  | ShureTechMono Nerd Font         | Terminals (Kitty), Dunst, body text           |
| `FONT_UI`    | Agave Nerd Font Propo           | Waybar, Rofi menus, GTK, app chrome            |
| `FONT_HEADER`| HeavyData Nerd Font             | SDDM login, Hyprlock big elements, Wlogout    |

## How to Change Fonts

1. Edit only this file:
   ```bash
   $EDITOR ~/.config/settings/fonts.sh
   ```

2. Apply everywhere:
   ```bash
   ~/.config/settings/apply-fonts.sh
   ```

3. For some things (SDDM, full Hyprland reload) you may need to:
   - Change wallpaper (so the SDDM patcher runs), or
   - `hyprctl reload`, or log out/in

## What Gets Updated

- Rofi (all the important configs via rofi-font.rasi + fonts.rasi)
- Waybar (main styles + several themes)
- Kitty
- Dunst
- Hyprlock (smart HEADER vs UI split)
- Wlogout
- GTK 3/4
- Hyprland plugin bars (hyprbars)
- Obsidian (vault `appearance.json` + matugen snippet headings/body)
- SDDM patcher script (sugar-candy theme)
- `fonts.env` (for shell scripts)
- `fonts.rasi` (Rofi)
- `fonts-waybar.css` (importable CSS snippet)
- `conf/fonts.lua` (for Hyprland Lua config)

## Quick Experimentation

Inside `fonts.sh` there are commented example blocks at the bottom.
Uncomment one, save, run `apply-fonts.sh`, and see the whole desktop change.

## For Neovim

Neovim (when running inside a terminal) automatically uses whatever font the terminal is using.
So "text font in nvim" = `FONT_TEXT` (ShureTechMono by default).

If you ever use Neovide (GUI), source the `fonts.env` or `dofile` the Lua equivalent.

## Adding New Tools Later

When a new app needs a font:
1. Add a small section in `apply-fonts.sh` that reads the variables from `fonts.sh`
2. (Optional) Add a supporting snippet file in this directory (like `fonts-waybar.css`)
3. Document it here

This system exists so you can try wild font combinations without hunting through 15 different files.
