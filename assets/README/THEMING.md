# HyprGruv Theming

HyprGruv ships **static named themes** (Gruvbox, Catppuccin, Nord, Everforest, …).
The install default is **gruvbox-dark** plus the Arch/Gruvbox stripes wallpaper
(`gruvbox_stripes_arch.png`, source `#689d6a`). Those files are copied once at
install — they are **not** regenerated on `git pull` / `git-eod-pull`.

**Matugen** is optional after install (Waypaper tile, Super+W “matugen” path).
Install and deploy pull never run `matugen image`.

## How it works

**Normal theme switch (Super+W)** — official presets first, leftover matugen after:

```
Theme + wallpaper + source accent
        ↓
Official GTK / icons / kitty / starship / nvim / yazi / obsidian
        ↓
Leftover matugen json (waybar, swaync, rofi, gtk colors, …)
        — starship/kitty/nvim/hypr/obsidian templates are skipped
```

Starship used to paint a generated palette and then snap to the theme preset.
Official files are written first so that flash does not happen.

**Optional matugen (Waypaper / free wallpaper)**

```
Wallpaper change (waypaper)
        ↓
set_wallpaper.sh  (waypaper post-command)
        ↓
apply-matugen-auto.sh  (optional rofi source-color picker)
        ↓
matugen image <wallpaper>  →  templates in ~/.config/matugen/config.toml
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

Some apps need a manual reload after theme updates (Firefox: restart; Qt apps: restart).

## First wallpaper / install

During install:

1. `default_wp.sh` copies `lib/defaults/gruvbox-dark/` (wallpaper + source color + live configs). No matugen.
2. `waypaper_setup.sh` in the setup wizard installs the waypaper stack and can seed `~/Pictures/Wallpapers`
3. Optional (default No): pre-generate waypaper thumbnails so the picker stays snappy. Skip on low disk/CPU. Re-run later with:

```bash
bash ~/.hyprgruv/lib/scripts/cache-wallpapers.sh
```

Thumbs live in `~/.cache/waypaper` (one 240px PNG per image, keyed by real path). Pressing `r` in waypaper wipes them.

Change wallpaper anytime with **waypaper** (GUI) or:

```bash
waypaper --wallpaper /path/to/image.png --apply
```

The waypaper post-command runs `set_wallpaper.sh`. Theme-folder wallpapers keep
the static preset; only free wallpapers (or the Super+W matugen tile) run matugen.

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

HyprGruv is **dark-only** on every machine. Light GTK/Qt/Grok appearance is treated as a regression and re-forced on login and Super+W.

- GTK theme: dark slot for the active colorscheme (`Gruvbox-Dark`, `Catppuccin-Dark`, …), never `*-Light`
- `gsettings` `color-scheme=prefer-dark`, `gtk-application-prefer-dark-theme=true`, `Gtk/ApplicationPreferDarkTheme=1`
- GTK2 `~/.gtkrc-2.0` is rewritten by `apply-desktop-assets.sh` (stops nwg-look / Plasma Breeze from leaving light file pickers)
- Icons: Papirus-Dark / theme slot
- Qt: `qt5ct` / `qt6ct` with matugen color files; Kvantum `matugen` scheme
- Grok: `GROK_APPEARANCE=dark` + `theme = groknight` unless a custom dark theme is already set

Run `~/.config/hyprgruv/scripts/apply-desktop-assets.sh` (or `gtk.sh`) to re-apply.

## Plymouth / boot splash

Plymouth themes under `~/.config/plymouth/matugen/` can be regenerated with:

```bash
~/.config/hyprgruv/scripts/update-plymouth-theme.sh
```

(requires root for initramfs rebuild)

## Machine-local palettes (git-eod / dual-device)

**Active** palette outputs (starship, nvim, gtk, waybar, hypr, `user-palette.json`, …) are **gitignored** and must not be committed. First install copies them from `lib/defaults/gruvbox-dark/live/`. After that they stay machine-local. Super+W rewrites them from `~/.config/colorschemes/<theme>/`; matugen is opt-in.

### Default vs chosen (system) theme

**Default for all machines until the user picks something: `gruvbox-dark`.**

| Entry point | Behavior |
|-------------|----------|
| **Super+W** | Pick a **theme** → sorted **themed wallpapers** → **source color** → official presets first (starship, kitty, nvim, …), then leftover matugen. Optional grid tile **Waypaper · all / matugen** only if you want free wallpapers or matugen/pywal. |
| **Waypaper** (tile or standalone) | All wallpapers + matugen/pywal (`set_wallpaper` posthook). Not used for normal theme switches. |
| **themed-wallpapers / theme folder** | Static preset for the Super+W theme (no matugen re-extract). |
| Live palette files already present | Follow system until next explicit theme apply. |
| Nothing chosen yet | **gruvbox-dark**. |

Neovim: loads `lua/matugen-theme.lua` when present; otherwise `:colorscheme gruvbox`.

**CLI / install / greeter (same policy):**

| Surface | How colors apply |
|---------|------------------|
| gum (install, setup, upkeep) | matugen `templates.gum` → `~/.cache/matugen/gum.env`; Super+W / `matugen-posthook-gum.sh` rebuilds from live hypr via `colors.sh --gum --refresh` |
| toilet headers | **graffiti** font system-wide (`header.sh`); **lsd-print** if installed, else gum/`COLOR_PRIMARY` |
| SDDM Sugar Candy | Asset defaults = gruvbox; `update-sddm-wallpaper.sh` overwrites from live palette |
| Shell cache | `~/.cache/matugen/colors.sh` regenerated on load / theme ensure |
| **mpv / ModernZ** | `mpv-matugen.conf` (OSD) + `script-opts/modernz-matugen.conf` (OSC); reopen player after theme change |

| Role | Behavior |
|------|----------|
| Source `git-eod` | Does not stage live palette files (ignored). Do not force-add them. |
| Deploy `git-eod-pull` | After a hyprgruv pull, runs `ensure-local-palette.sh` only if live files are **missing**. Does not re-apply the shipped default over an existing theme. |
| Manual restore | `THEME_SWITCHER_APPLY=1 ~/.config/colorschemes/apply-theme.sh gruvbox-dark` |
| Manual switch | Super+W / `apply-theme.sh <name>` — updates `.current-theme` and live outputs. |

If a deploy machine suddenly shows another host’s palette (e.g. noir/nord after pull), re-apply a local theme; then pull the gitignore fix so it cannot happen again.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Colors didn't update after wallpaper change | Check `~/.cache/matugen.log`; run `matugen image <wallpaper>` manually |
| Waybar stale | `pkill -SIGUSR2 waybar` or toggle via waybar reload |
| Hyprland colors stale | `hyprctl reload` |
| Firefox chrome empty | Fix profile path in `config.toml`, enable `userChrome` pref, restart Firefox |
| Grey / washed-out palette | Re-pick source color in `palette.sh` or `rofi-palette.sh` |
| Deploy looks like source palette after pull | Live outputs were committed historically; `git-eod-pull` + `ensure-local-palette.sh`, or re-apply theme |
| waypaper search picks wrong image | Ensure `~/waypaper_fixed_app.py` exists (patched wrapper in `~/.local/bin/waypaper`) |
| waypaper rebuilds previews every launch | Do not press `r` / refresh (that deletes `~/.cache/waypaper`); re-warm with `cache-wallpapers.sh` |

## Adding a new themed app

1. Add a template under `~/.config/matugen/templates/`
2. Register it in `~/.config/matugen/config.toml` with `input_path`, `output_path`, and optional `post_hook`
3. Test: `matugen image ~/Pictures/Wallpapers/<image>`
4. If the app should update on wallpaper change, ensure `apply-matugen-auto.sh` or `matugen-posthook` covers any extra reload steps