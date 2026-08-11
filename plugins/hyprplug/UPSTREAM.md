# Upstream provenance

- Upstream: https://github.com/hyprwm/hyprland-plugins
- Path: hyprbars/
- Vendored from tag: v0.56.0 (7644cecdb947060682891a0db2a0cdc5c0b9e704)
- Date: 2026-08-11
- Target Hyprland: 0.56.2 (efb50993780079460b0cbed1363e2166a2de1d9f)

## Why pin to plugins v0.56.0 (not main)

Hyprland-plugins `main` after a9eaa5263a ("hyprbars: chase hyprland") includes:

    #include <hyprland/src/keybinds/Manager.hpp>

That path exists on Hyprland *git* only. Stable 0.56.2 headers still ship
`managers/KeybindManager.hpp` and have no `src/keybinds/` tree. Building tip
hyprbars against 0.56.2 fails with:

    fatal error: hyprland/src/keybinds/Manager.hpp: No such file or directory

When upgrading Hyprland, re-vendor from the matching hyprland-plugins tag
(e.g. v0.57.0 for 0.57.x), not from plugins main.
