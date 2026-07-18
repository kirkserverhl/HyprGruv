# ~/.config/hypr — Hyprland Lua Config (Daily Driver)

This is now your primary Hyprland configuration using the native Lua format (Hyprland 0.55+).

## Structure
- `hyprland.lua` — Main entry point
- `conf/` — Split modules (monitors, keybinds, autostart, etc.)
- `colors/` — Dynamic color loading (matugen + wal + fallback)
- `scripts/` — All your custom scripts (still used by the config)
- `hyprlock/`, `shaders/`, `effects/`, etc. — Supporting assets

## Session at Login
- **Hyprland (Lua)** — Uses this directory (`~/.config/hypr/hyprland.lua`)

Legacy conf backups were removed; the old setup lives in the separate GitHub history if needed.

## Testing / Reloading
From inside Hyprland you can usually just save the file — it should hot reload.
For a full restart with this config:
`Hyprland --config ~/.config/hypr/hyprland.lua`

## LSP
Add this to your editor settings for good completion:
```json
{
  "Lua.workspace.library": ["/usr/share/hypr/stubs"]
}
```

This setup was migrated on 2026-05-29. Lua is now the one true config.
