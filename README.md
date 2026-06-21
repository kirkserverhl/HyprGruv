⚠️ Beta Version - Under Construction ⚠️

Use at your own risk. Save your work frequently and consider testing in a VM first.

**Recommended VM specs**

```bash
Hypervisor: VirtualBox, VMware, QEMU/KVM, or Hyper-V
RAM:        4GB minimum (8GB+ recommended)
Storage:    40GB+ free disk space
```

# HyprGruv

Hyprland on Arch Linux with Gruvbox theming.

Developed by Kirk Bass

## Prerequisites

- Ventoy USB with the latest Arch Linux ISO (or another boot method)
- Wired or wireless internet during installation

## Step 1: Boot Arch Linux

Boot the Arch ISO (Normal Mode → `archinstall` medium if using the guided installer).

## Step 2: Install Arch Linux

Launch the guided installer:

```bash
archinstall
```

Suggested options (adjust to taste):

| Setting | Recommendation |
|---------|----------------|
| Mirrors | US or your region |
| Disk | btrfs or ext4, compression on, no separate `/home` unless you want it |
| Swap | enabled |
| Bootloader | grub |
| Profile | Desktop → Hyprland, polkit enabled |
| Audio | PipeWire |
| Network | NetworkManager |
| Extra packages | `git` (firefox is installed later by Hyprgruv) |
| Timezone | your locale |

When finished, exit the installer and reboot. Remove the USB when powered off.

## Step 3: First login and run Hyprgruv

At SDDM, choose **Hyprland** (not uwsm-managed) and log in with the user you created.

Open a terminal (`Win + Q` before install completes; `Win + Enter` after) and run:

```bash
sudo pacman -S git
git clone https://github.com/kirkserverhl/hyprgruv.git ~/.hyprgruv
cd ~/.hyprgruv
./install.sh
```

If you already have the tree elsewhere, copy or symlink it to `~/.hyprgruv` and run `./install.sh` from there.

## What `install.sh` does

The installer runs in one pass. On a graphical session (e.g. EndeavourOS KDE), the setup wizard runs **before** reboot; on a TTY-only install it may reboot first.

### Pre-reboot modules

| Step | Module | What it does |
|------|--------|--------------|
| 1 | `00-preflight.sh` | Arch sanity checks, multilib, mirror/keyring repair, EndeavourOS cleanup |
| 2 | `01-packages.sh` | Installs yay, optional Chaotic-AUR, core Hyprland stack, then `lib/packages/pacman.list` + `aur.list` |
| 3 | `02-stow.sh` | Stows `home/` configs into `$HOME` (with timestamped backup) |
| 4 | `default_wp.sh` | Opening wallpaper + first matugen palette (skipped with `SKIP_WALLPAPER=1`) |
| 5 | `post_reboot_setup.sh` | Full setup wizard (modules 03–05) when `SKIP_SETUP_WIZARD` is unset |
| 6 | Final sync | `yay -Syu` or `pacman -Syu` |
| 7 | Reboot | Skipped when a graphical session is detected (`WAYLAND_DISPLAY` / `DISPLAY` set) |

### Setup wizard (`post_reboot_setup.sh`)

Can also be run manually after login:

```bash
FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh
```

| Step | Script | What it does |
|------|--------|--------------|
| Wallpaper | `waypaper_setup.sh` | Installs waypaper stack, optional wallpaper repo download, initial theme |
| System | `03-setup.sh` | Hyprpm plugins; MIME handlers (handlr, Zathura, nvim/LibreOffice defaults); enables SDDM + Sugar Candy theme; VM GRUB tweaks |
| Interactive | `04-config.sh` | Optional: SDDM theme, GRUB theme, shell/zsh, Atuin, Pacseek, SSH key, zram, cleanup |
| Defaults | `05-setup_defaults.sh` | Choose default terminal (kitty/alacritty/wezterm/foot/…), browser, and editor; offers to install if missing |

Monitor layout is **not** part of the installer. Configure displays in Hyprland with `save-monitor-layout.sh`, `monitor-rofi.sh`, or by editing `~/.config/hypr/conf/monitors.lua`.

## Package lists (canonical source)

Package names are **not** maintained in `assets/README/package.list` anymore. The single source of truth is:

```
lib/packages/pacman.list   # official repos
lib/packages/aur.list      # AUR (via yay)
lib/packages/new.list      # potential optional packages (not auto-installed by install.sh)
```

`01-packages.sh` also installs a small hardcoded core set (Hyprland, pipewire, kitty, thunar, mpv, etc.) before syncing the manifest lists.

**Required AUR highlight:** `aylurs-gtk-shell-git` (AGS) is in `aur.list` and retried in `ESSENTIAL_CHECK`. The dotfiles ship `~/.config/ags/` (power menu, display switcher, sidebar). Waybar remains the primary bar, but AGS must be installed for those layer-shell widgets — including the power menu in `~/.config/ags/power-menu.js`. Keybinds and waybar still launch `wlogout` via `launch-wlogout.sh`; both packages are installed.

### Potential packages (for review)

These live in `lib/packages/new.list`. They are **not** installed during `./install.sh` (final sync uses `--skip-new`). Install on demand when you want to try one:

```bash
bash ~/.hyprgruv/sync-packages.sh --new-only
```

| Package | Repo | Notes |
|---------|------|-------|
| `aphototoollibre` | AUR | Installed via `aur.list` / `setup-mime-handlers.sh` for image MIME types |
| `easyeffects` | official | PipeWire audio effects |
| `qt6-virtualkeyboard` | official | SDDM Sugar Candy on-screen keyboard |

**Excluded from install (by design):**

| Item | Reason |
|------|--------|
| `overskride` | Use `blueman-manager` (waybar Bluetooth click) instead |
| `hypremoji` / `smile` | Emoji picker removed from default install and keybinds |
| `ghostty-git`, `ghostty-shell-integration-git`, `ghostty-terminfo-git` | Use official `ghostty` via setup defaults wizard instead |
| `tmux-resurrect`, `tmux-resurrect-git` | Flaky AUR build; dropped from auto-install |
| `tmuxai` | Removed from auto-install |
| `ttf-jetbrains-mono`, `ttf-jetbrains-mono-nerd` | Not used; Agave / ShureTechMono / HeavyData are defaults |
| `ttf-nerd-fonts-symbols` | Redundant — full nerd fonts below already include icon glyphs |

To add or remove potentials, edit `lib/packages/new.list` or run:

```bash
bash ~/.hyprgruv/sync-packages.sh add <package> --new
```

### Cross-device package sync

```bash
# Preview what would install
bash ~/.hyprgruv/sync-packages.sh --dry-run

# Install missing packages from confirmed lists (skips potentials)
bash ~/.hyprgruv/sync-packages.sh --skip-new

# Install only potential/optional packages
bash ~/.hyprgruv/sync-packages.sh --new-only

# Stage a potential package for review
bash ~/.hyprgruv/sync-packages.sh add <package> --new

# Promote from potential → confirmed
bash ~/.hyprgruv/sync-packages.sh promote <package> --to pacman
bash ~/.hyprgruv/sync-packages.sh promote <package> --to aur
```

## File openers (nvim, yazi, handlr)

Stowed configs:

- `~/.config/mimeapps.list` — default apps (nvim for text, Zathura for PDF, LibreOffice for Office, Brave for URLs)
- `~/.local/bin/xdg-open` — uses `handlr` when installed, otherwise `/usr/bin/xdg-open`

Packages: `handlr-regex`, `zathura`, `zathura-pdf-mupdf`, `xdg-utils`, `libreoffice-fresh`, `aphototoollibre` (AUR), `brave-bin` (AUR).

Applied automatically during the setup wizard (`setup-mime-handlers.sh` in `03-setup.sh`). Re-apply after stow or MIME edits:

```bash
bash ~/.hyprgruv/lib/scripts/setup-mime-handlers.sh
```

## Install environment variables

| Variable | Effect |
|----------|--------|
| `FORCE=1` | Re-run completed modules |
| `RESET_STATE=1` | Clear install state and start fresh |
| `SKIP_PACKAGES=1` | Skip `01-packages.sh` (configs only) |
| `SKIP_WALLPAPER=1` | Skip opening wallpaper / matugen step |
| `SKIP_SETUP_WIZARD=1` | Skip modules 03–05 during install |
| `SKIP_REBOOT=1` | Never reboot at end of install |
| `FORCE_REBOOT=1` | Reboot even in a graphical session |
| `SKIP_CHAOTIC=1` | Skip Chaotic-AUR bootstrap in packages step |
| `CONTINUE_ON_PACKAGE_FAIL=0` | Stop install if packages step fails (default: continue) |

Examples:

```bash
# Re-test stow without reinstalling packages
SKIP_PACKAGES=1 FORCE=1 ./install.sh

# Clean state, full re-run
RESET_STATE=1 FORCE=1 ./install.sh

# Re-run wizard only
FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh
```

## Tips during install

- Move windows: `Win + Left Mouse` (works before and after install)
- Close windows during install: `Win + C` (after install: `Win + Q`)
- Full keybind list after install: `Win + K` or type `keybinds` in a terminal

## Post-installation

After a successful run you should have:

- Hyprland session at SDDM (Sugar Candy greeter)
- Stowed configs under `~/.config/hypr`, waybar, rofi, etc.
- Matugen-driven theming tied to wallpaper changes
- Optional extras from the interactive wizard (Atuin, zram, GRUB theme, …)

If anything was skipped, re-run the wizard:

```bash
FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh
```

Legacy paths like `~/.dotfiles/install.sh` are no longer used.

## Repository layout

```
.hyprgruv/
├── install.sh                 # Main entry point
├── sync-packages.sh           # Wrapper → lib/scripts/sync-packages.sh
├── lib/
│   ├── common.sh              # Shared helpers
│   ├── state.sh               # Install state tracking
│   ├── packages/              # pacman.list, aur.list, new.list, manifest.sh
│   └── scripts/               # Setup helpers (grub, shell, waypaper, …)
├── modules/
│   ├── 00-preflight.sh
│   ├── 01-packages.sh
│   ├── 02-stow.sh
│   ├── 03-setup.sh
│   ├── 04-config.sh
│   └── 05-setup_defaults.sh
├── home/                      # Stow package (user configs)
└── assets/                    # SDDM themes, GRUB assets, install logs
```

## Feedback

Issues and suggestions: open an issue on the repository.