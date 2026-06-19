# HyprGruv Theming

HyprGruv uses **matugen** as the primary theming engine. Wallpaper changes drive Material You palettes across the desktop.

## How it works

```
Wallpaper change (waypaper / awww)
        ↓
set_wallpaper.sh  (waypaper post-command)
        ↓
apply-matugen-auto.sh  (optional rofi source-color picker)
        ↓
matugen image <wallpaper>  →  templates in ~/.config/matugen/config.toml
        ↓
Generated colors land in app config paths; post-hooks reload where possible
```

**Config:** `~/.config/matugen/config.toml`  
**Templates:** `~/.config/matugen/templates/`  
**Logs:** `~/.cache/matugen.log`

### What gets themed automatically

| App / area | Output path (typical) |
|------------|----------------------|
| Hyprland | `~/.config/hypr/colors/custom/matugen.conf` |
| Hyprlock | `~/.config/hypr/hyprlock/colors/matugen.conf` |
| Kitty | `~/.config/kitty/colors/custom/matugen.conf` |
| Ghostty | `~/.config/ghostty/colors/matugen.conf` |
| Waybar | `~/.config/waybar/colors/matugen-waybar.css` |
| Starship | `~/.config/starship/matugen-rainbow.toml` |
| Rofi | `~/.config/rofi/colors.rasi` |
| GTK 3/4 | `~/.config/gtk-3.0/colors.css`, `gtk-4.0/colors.css` |
| Qt (qt5ct/qt6ct) | `~/.config/qt5ct/colors/matugen.conf`, `qt6ct/...` |
| Kvantum | `~/.config/Kvantum/matugen/` |
| Neovim | `~/.config/nvim/lua/matugen-theme.lua` |
| btop / bpytop | `~/.config/btop/themes/matugen.theme` |
| bat | `~/.config/bat/themes/Matugen.tmTheme` |
| cava | `~/.config/cava/themes/matugen` |
| tmux | `~/.config/tmux/generated.conf` |
| yazi | `~/.config/yazi/theme.toml` |
| wlogout | `~/.config/wlogout/colors.css` |
| Obsidian | `~/.config/obsidian/matugen.css` (+ vault snippets); fonts via `apply-fonts.sh` → Agave headings, ShureTechMono body |
| Firefox | `~/.mozilla/firefox/<profile>/chrome/userChrome.css` |
| Chrome user CSS | `~/.config/chrome/matugen-theme.user.css` |
| SDDM | via `update-sddm-wallpaper.sh` on wallpaper change |

Some apps need a manual reload after theme updates (Ghostty: `Ctrl+Shift+,`; Firefox: restart; Qt apps: restart).

## First wallpaper / install

During install:

1. `default_wp.sh` runs after stow (opening wallpaper + first palette)
2. `waypaper_setup.sh` in the setup wizard installs the waypaper stack and can seed `~/Pictures/Wallpapers`

Change wallpaper anytime with **waypaper** (GUI) or:

```bash
waypaper --wallpaper /path/to/image.png --apply
```

The waypaper post-command runs `set_wallpaper.sh`, which triggers matugen.

## Choosing palettes manually

| Tool | When to use |
|------|-------------|
| **Automatic** (`apply-matugen-auto.sh`) | Runs on every wallpaper change; shows a 2×2 rofi color grid when a display is available |
| **`palette.sh`** (`Ctrl+P`) | Full interactive chooser: mode, scheme type, source color, optional transparent waybar |
| **`rofi-palette.sh`** | Standalone rofi source-color picker |
| **`rofi-choose-matugen-style.sh`** | Step-by-step mode + type + source color |

Source colors come from `extract-good-source-colors.sh` (saturation-aware — avoids grey palettes).

### Transparent waybar

`palette.sh` can leave the waybar background transparent while keeping semantic colors elsewhere. A marker file at `~/.cache/matugen/waybar-transparent-this-time` controls one-shot transparent mode during auto-apply.

## Firefox setup

Matugen writes Firefox chrome CSS. One-time Firefox configuration:

1. Open `about:config` and set:
   ```
   toolkit.legacyUserProfileCustomizations.stylesheets = true
   ```
2. Find your profile folder: `about:profiles` → copy the profile path (e.g. `xxxx.default-release`).
3. Update **your** profile path in `~/.config/matugen/config.toml` under `[templates.firefox]`, `[templates.firefox_github]`, `[templates.firefox_website_colors]`, and `[templates.firefox_youtube]` — the stowed config ships with a placeholder profile name.
4. Change wallpaper once (or run `matugen image ~/Pictures/Wallpapers/<image>`) to generate:
   - `chrome/userChrome.css`
   - `chrome/colors.css`
   - `chrome/websites/github.css`, `youtube.css`
5. Restart Firefox.

Firefox theming is matugen-only (`templates/firefox-colors.css` and per-site `userContent.css`). Remove any installed Dark Reader or pywalfox extensions so they do not override matugen colors.

## GTK / Qt appearance

- GTK theme: `adw-gtk3` (dark/light follows matugen mode)
- Icons: Papirus (set in install / stow)
- Qt: `qt5ct` / `qt6ct` with matugen color files; Kvantum `matugen` scheme for some apps

Run `~/.config/hyprgruv/scripts/gtk.sh` if you need to re-apply GTK settings manually.

## Plymouth / boot splash

Plymouth themes under `~/.config/plymouth/matugen/` can be regenerated with:

```bash
~/.config/hyprgruv/scripts/update-plymouth-theme.sh
```

(requires root for initramfs rebuild)

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Colors didn't update after wallpaper change | Check `~/.cache/matugen.log`; run `matugen image <wallpaper>` manually |
| Waybar stale | `pkill -SIGUSR2 waybar` or toggle via waybar reload |
| Hyprland colors stale | `hyprctl reload` |
| Firefox chrome empty | Fix profile path in `config.toml`, enable `userChrome` pref, restart Firefox |
| Grey / washed-out palette | Re-pick source color in `palette.sh` or `rofi-palette.sh` |
| waypaper search picks wrong image | Ensure `~/waypaper_fixed_app.py` exists (patched wrapper in `~/.local/bin/waypaper`) |

## Adding a new themed app

1. Add a template under `~/.config/matugen/templates/`
2. Register it in `~/.config/matugen/config.toml` with `input_path`, `output_path`, and optional `post_hook`
3. Test: `matugen image ~/Pictures/Wallpapers/<image>`
4. If the app should update on wallpaper change, ensure `apply-matugen-auto.sh` or `matugen-posthook` covers any extra reload steps