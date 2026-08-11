# LUKS full-disk encryption (laptop reinstall outline)

Use this when reinstalling a laptop so the disk is encrypted **before** Hyprgruv (or any rice) is deployed.

## When must encryption happen?

**During OS install, at the disk / partitioning step — not after.**

| Stage | Encrypt here? |
|-------|----------------|
| Boot live USB (EndeavourOS / Arch ISO) | No |
| **Disk layout / partitioning / “Erase disk”** | **Yes — this is the step** |
| Package install, bootloader, user creation | No (runs *on* the encrypted volume) |
| First reboot into new system | Unlock LUKS passphrase, then login |
| `git clone` + `./install.sh` (Hyprgruv) | No — already encrypted underneath |

**Rule of thumb:** once the installer has written an unencrypted root filesystem and you have rebooted into it, adding full-disk LUKS later means **reinstall** (or a painful offline migration). There is no clean “toggle encryption on” after a normal desktop install.

Hyprgruv does **not** set up LUKS. Encryption is entirely the job of **EndeavourOS Calamares**, **archinstall**, or manual `cryptsetup` **before** you clone this repo.

---

## Recommended flow (EndeavourOS laptop)

1. **Backup** anything you need from this machine (dotfiles are in git; local wallpapers / keys / notes are not).
2. Boot the **EndeavourOS** USB (or Arch ISO if you prefer `archinstall`).
3. Connect to network.
4. Start the installer.
5. **Disk / partitions**
   - Choose erase / replace disk (or a free partition if dual-boot).
   - Enable **encrypt system** / **LUKS** (wording varies by Calamares version).
   - Set a **strong passphrase** (this is the unlock prompt at every cold boot; it is *not* your user password, though you may choose the same string).
   - Prefer **btrfs** or **ext4** on the unlocked volume; swap as encrypted swap or zram (Hyprgruv can set zram later).
6. Create your user, timezone, hostname, etc.
7. Finish install → reboot → **enter LUKS passphrase** at the unlock screen → then SDDM / greeter → Hyprland or Plasma once.
8. Install Hyprgruv as usual:

   ```bash
   sudo pacman -S git
   git clone https://github.com/kirkserverhl/hyprgruv.git ~/.hyprgruv
   cd ~/.hyprgruv
   ./install.sh
   ```

9. On multi-DE images (e.g. EOS + Plasma), the SDDM installer will **claim** `display-manager` for SDDM and disable rivals (`plasmalogin`, etc.) so Sugar Candy actually runs.

---

## Recommended flow (Arch `archinstall`)

1. Boot Arch ISO, `archinstall`.
2. **Disk configuration** → select disk → use a layout that supports encryption (guided “best effort” / LVM on LUKS / btrfs on LUKS depending on version).
3. Set encryption password when prompted.
4. Profile: Hyprland (or minimal + install Hyprland later).
5. Reboot → unlock LUKS → login → clone Hyprgruv → `./install.sh`.

---

## Manual sketch (advanced; only if you partition by hand)

Order on the live USB **before** `pacstrap` / installer package stage:

1. Partition disk (e.g. EFI `ESP` unencrypted + root partition for LUKS).
2. `cryptsetup luksFormat` on the root partition → `cryptsetup open` → map name e.g. `cryptroot`.
3. Create filesystem on `/dev/mapper/cryptroot` (and optional subvolumes).
4. Mount, install base system, generate `crypttab` + initramfs hooks (`encrypt` / `sd-encrypt`), install bootloader that can unlock or use a passphrase prompt.
5. Only then reboot into the new system and run Hyprgruv.

If you are not comfortable with this path, use **Calamares or archinstall** checkboxes instead.

---

## What stays unencrypted (normal layouts)

- **EFI system partition (ESP)** — small FAT32 boot partition (kernels/bootloader bits depending on setup).
- Firmware/BIOS settings.
- Everything under the unlocked root (home, configs, wallpapers) is encrypted **at rest** when the machine is powered off.

---

## Passphrase vs login password

| Prompt | When | What |
|--------|------|------|
| **LUKS unlock** | Early boot (before full userspace) | Disk passphrase |
| **SDDM / greeter** | After unlock | User password |

Losing the LUKS passphrase = disk contents are unrecoverable. Store it offline (password manager, paper, etc.).

---

## After reinstall checklist (Hyprgruv laptop)

- [ ] LUKS unlock works on cold boot  
- [ ] SDDM shows Sugar Candy (not Plasma Login Manager only)  
- [ ] `./install.sh` completed; rofi / waypaper / wallpaper library path OK  
- [ ] SSH key / GitHub access if you need private repos  
- [ ] Machine profile at install (Laptop vs Desktop) — touchpad, idle, lid, power  
- [ ] Re-run anytime: `bash ~/.hyprgruv/lib/scripts/apply-machine-profile.sh --prompt`  


---

## References

- [ArchWiki: dm-crypt / LUKS](https://wiki.archlinux.org/title/Dm-crypt)
- [ArchWiki: archinstall](https://wiki.archlinux.org/title/Archinstall)
- EndeavourOS installer: disk step → encryption option in Calamares  
