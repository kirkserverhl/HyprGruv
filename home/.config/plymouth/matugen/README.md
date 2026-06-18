# Matugen Plymouth Theme

This is the source template for a dynamic Plymouth boot splash that pulls colors from your current matugen palette.

## How it works

- `update-plymouth-theme.sh` (called automatically from the matugen post-hook) reads your latest `~/.cache/matugen/current.json`
- It substitutes the colors into copies of these files and installs them to `/usr/share/plymouth/themes/matugen/`
- It then activates the theme and rebuilds the initramfs

## Files

- `matugen.plymouth` — Theme metadata
- `matugen.script`   — The actual drawing script (uses baked-in 0-1 RGB floats for reliability)

## One-time setup (you must do these steps)

1. Install Plymouth:
   ```bash
   sudo pacman -S plymouth
   ```

2. Run the setup helper (creates the sudoers rule + prints the remaining steps):
   ```bash
   ~/.config/hyprgruv/scripts/update-plymouth-theme.sh --setup
   ```

3. Edit `/etc/mkinitcpio.conf` and add `plymouth` to the HOOKS array.
   Typical good order (example):
   ```
   HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck plymouth)
   ```
   Put it near the end, before `filesystems` or after `fsck` depending on your setup.

4. Add `splash` to your kernel command line.

   For GRUB (you are using GRUB):
   Edit `/etc/default/grub` and modify:
   ```
   GRUB_CMDLINE_LINUX_DEFAULT="... splash"
   ```
   Then:
   ```bash
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```

5. Rebuild initramfs:
   ```bash
   sudo mkinitcpio -P
   ```

6. (Optional but recommended) Set a nice font for the splash if you want better looking text:
   - Many people use `ttf-heavydata-nerd` or similar and make sure it's in the initramfs.

After the above, every time you change wallpaper via waypaper, the boot splash should update on the next reboot.

## Troubleshooting

- If you see the old theme on boot: make sure you ran `plymouth-set-default-theme matugen --rebuild-initrd` at least once.
- Test without rebooting: `sudo plymouthd --debug --mode=boot ; sudo plymouth --show-splash` then `sudo plymouth quit`
- Remove the splash temporarily: edit GRUB cmdline and remove `splash`, then `sudo grub-mkconfig ...`

## Limitations

Plymouth runs extremely early. The theme is "baked" at wallpaper change time, so it will always reflect the last wallpaper you set before the last reboot.
