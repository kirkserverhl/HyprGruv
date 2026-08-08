# TTY (virtual console) palettes

Linux VTs (`Ctrl+Alt+F3` …) use a **16-color** RGB table via [`setvtrgb(8)`](https://man.archlinux.org/man/setvtrgb.8).

| File | Source |
|------|--------|
| `omarchy-gruvbox.vtrgb` | [Omarchy gruvbox `colors.toml`](https://github.com/basecamp/omarchy/blob/quattro/themes/gruvbox/colors.toml) — soft Gruvbox Material–style |

## Apply

```bash
# Now (needs sudo from a graphical session):
~/.config/hyprgruv/scripts/tty-theme.sh
# or
sudo setvtrgb -C /dev/tty0 ~/.config/hyprgruv/tty/omarchy-gruvbox.vtrgb

# Every boot (recommended, one-time):
~/.config/hyprgruv/scripts/tty-theme.sh --install-system-unit
```

Optional wallpaper-driven mapping:

```bash
~/.config/hyprgruv/scripts/tty-theme.sh matugen
```

Does **not** recolor early kernel/Plymouth boot messages.
