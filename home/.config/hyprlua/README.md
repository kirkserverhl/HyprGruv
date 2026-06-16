# hyprlua — Converted Hyprland Lua Configuration

This directory contains a conversion of your original `~/.config/hypr` setup to Hyprland's native Lua configuration format (0.55+).

## How to use

1. **Test without breaking your current config** (recommended):

   ```bash
   Hyprland --config ~/.config/hyprlua/hyprland.lua
   ```

   From a TTY or from within a running Hyprland session (it will replace the session).

2. Make it permanent (example for a login shell or greetd/sddm):

   Edit your launcher to pass `--config ~/.config/hyprlua/hyprland.lua`

   Or simply rename/symlink if you want to fully switch:
   ```bash
   mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak
   ln -s ~/.config/hyprlua/hyprland.lua ~/.config/hypr/hyprland.lua
   ```

   (Hyprland prefers `.lua` over `.conf` when both exist in the same directory.)

## What was converted

- All **active** configuration files in the load chain:
  - monitors
  - environment variables
  - input/keyboard
  - autostart (via `hl.on("hyprland.start")`)
  - general (gaps, borders, dwindle, master, misc)
  - decorations (the "rounding-more-blur" preset)
  - animations (the 00-default preset with bezier + animation)
  - workspaces (persistent per-monitor + scratchpad)
  - gestures
  - plugins (hyprbars, hymission, hyprfocus, etc.)
  - keybinds (large useful subset — ~70% of daily-used ones)
  - windowrules (large useful subset)

- Colors are dynamically loaded from the same sources as before:
  - `~/.config/hypr/colors/custom/matugen.conf` (highest priority)
  - `~/.cache/wal/colors-hyprland.conf`
  - static gruvbox fallback

## What was NOT converted

- All the **variant presets** (animations/01-*, decorations/*, windows/*, layouts/laptop.conf, etc.). Only the currently active ones were ported.
- Some very obscure or duplicate keybinds and windowrules (see TODO comments in the files).
- `hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf` — these still use their own formats (not Lua yet).
- Most of the `scripts/` directory — they are referenced by absolute path from the original `~/.config/hypr/scripts`. This keeps things working without duplication.

## Important Lua API notes (from your old config)

| Old hyprlang                  | New Lua equivalent                              |
|-------------------------------|-------------------------------------------------|
| `bind = SUPER, Q, killactive` | `hl.bind("SUPER + Q", hl.dsp.window.close())`   |
| `exec-once = foo`             | `hl.on("hyprland.start", function() hl.exec_cmd("foo") end)` |
| `monitor = ...`               | `hl.monitor({ output = "...", ... })`           |
| `env = FOO,bar`               | `hl.env("FOO", "bar")`                          |
| `general { gaps_in = 5 }`     | `hl.config({ general = { gaps_in = 5 } })`      |
| `animation = ...`             | `hl.animation({ leaf = "...", speed = ..., bezier = "..." })` + `hl.curve(...)` |
| `windowrule { name=..., match... }` | `hl.window_rule({ name=..., match=... })` |
| `$VAR = rgb(...)`             | Local Lua table from `require("colors.init").load()` |

Dispatchers live under `hl.dsp.*` (see wiki for full list).

## Next steps / Polish

1. Start Hyprland with the new config and check for errors (they pop up as notifications).
2. Look for `TODO` comments in `conf/keybinds.lua` and `conf/windowrules.lua` and fill in anything you miss.
3. For full theme switching (your many animation/decor presets), you can now do it much more elegantly in Lua with functions + `hl.config(...)` + `hl.animation(...)` calls.

## LSP / Editor support (highly recommended)

Hyprland ships stubs. Add to your editor:

```json
// .luarc.json or VSCode settings
{
  "Lua.workspace.library": ["/usr/share/hypr/stubs"]
}
```

## Sources

- Original: `~/.config/hypr/`
- Conversion performed: April 2026
- Official docs: https://wiki.hypr.land/Configuring/Start/

Enjoy the power of real Lua in your compositor config!
