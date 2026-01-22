# Arch Linux VM Rescue Guide – Network & Chroot Recovery

**Last tested:** January 2026 (Arch 6.11+ live ISO)  
**Common scenario:** Minimal archinstall → no NetworkManager/dhcpcd → offline after reboot → can't install anything → chroot fails with "/bin/bash: No such file or directory" due to Btrfs subvolume.

## Initial Diagonis lists below mentioned issues
- Booted into installed system → no internet (ping unreachable)
- pacman fails (no mirrors reachable)
- Live ISO has internet → but chroot fails mysteriously
- Errors like:
  - `arch-chroot: failed to run command '/bin/bash': No such file or directory`
  - `mount: /mnt/boot: mount point does not exist`
  - `ls /mnt/bin/bash: No such file or directory`

## Root Causes
1. **Minimal profile** in archinstall → no network service installed/enabled
2. **Btrfs default layout** (`@` subvolume for root) → mounting raw `/dev/vda2` puts you in empty top-level volume (no `/bin`, `/usr`, etc.)
3. Trying to mount EFI (`/dev/vda1`) before mounting root subvolume → mount failures

## Rescue Procedure (Boot from Arch Live ISO in VM)

### 1. Boot live ISO (with internet working via NAT)
- Make sure VM is using NAT network ('default' in Virt-Manager)
- Verify in live ISO:
  ```bash
  ping archlinux.org
  ```

### 2. Identify partitions (usually in VM)
```bash
lsblk -f
# Example output:
# vda
# ├─vda1  vfat   EFI
# └─vda2  btrfs  root (Btrfs)
```

Root = `/dev/vda2` (Btrfs), EFI = `/dev/vda1`

### 3. Clean mounts & mount correctly
```bash
umount -R /mnt 2>/dev/null   # Ignore errors if nothing mounted

# Mount Btrfs root subvolume @
mount -o subvol=@ /dev/vda2 /mnt

# Mount EFI
mkdir -p /mnt/boot
mount /dev/vda1 /mnt/boot

# Optional: Mount other subvolumes if they exist (check with btrfs subvolume list /mnt)
# mkdir -p /mnt/home          && mount -o subvol=@home /dev/vda2 /mnt/home
# mkdir -p /mnt/var/log       && mount -o subvol=@log  /dev/vda2 /mnt/var/log
# mkdir -p /mnt/.snapshots    && mount -o subvol=@snapshots /dev/vda2 /mnt/.snapshots
```

### 4. Verify mounts (critical!)
```bash
ls /mnt/bin/bash          # Must exist!
ls /mnt/etc/fstab         # Should show subvol=@ entries
ls /mnt/boot              # Should show EFI/BOOT/ etc.
btrfs subvolume list /mnt # Confirm @ is there
```

If `/mnt/bin/bash` still missing → wrong subvol name (rare). Try:
```bash
umount /mnt
mount /dev/vda2 /mnt
btrfs subvolume list /mnt   # Look for the root one (usually @)
umount /mnt
mount -o subvol=THE_NAME /dev/vda2 /mnt
```

### 5. Chroot in
```bash
arch-chroot /mnt
```

You should now see prompt: `[root@archiso /]#` (but it's your installed system)

### 6. Fix networking inside chroot
```bash
# Option A: Recommended (full-featured, auto DHCP)
pacman -Syu networkmanager
systemctl enable NetworkManager

# Option B: Lightweight alternative
# pacman -Syu dhcpcd
# systemctl enable dhcpcd
```

### 7. Exit & reboot
```bash
exit
umount -R /mnt
poweroff   # or reboot
```

### 8. Boot without ISO
In Virt-Manager:
- Edit VM → Overview → Boot Options
- Uncheck/remove CDROM/ISO
- Move hard disk to top
- Start VM

Should boot into installed system with internet now.

## Quick One-Liner Mount (copy-paste friendly)
```bash
umount -R /mnt 2>/dev/null && \
mount -o subvol=@ /dev/vda2 /mnt && \
mkdir -p /mnt/boot && \
mount /dev/vda1 /mnt/boot && \
arch-chroot /mnt
```

## Prevention for Next Time
- During archinstall: Choose "desktop" profile or explicitly add NetworkManager
- Or after base install (in live ISO): `pacstrap /mnt networkmanager` before reboot

