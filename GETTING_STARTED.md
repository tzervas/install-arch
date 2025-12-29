# Arch Linux Automated Installer - Ready to Use

## What Has Been Created

Your automated Arch Linux installer is ready! Here's what's been configured:

### Configuration Files Created:

1. **archinstall-config.json** - Main installation configuration
   - Auto-installs to first NVMe drive (/dev/nvme0n1)
   - 1GB EFI boot partition (FAT32, unencrypted)
   - 200GB root partition (BTRFS, LUKS encrypted, read-only)
   - ~1.8TB data partition (BTRFS, LUKS encrypted, writable)
   - KDE Plasma desktop environment
   - All required packages for virtualization and development

2. **system-update** - System update wrapper
   - Handles read-only root filesystem
   - Temporarily remounts as read-write for updates
   - Automatically remounts as read-only after updates

3. **force-password-change.sh** - First login security
   - Forces password change from default "changeme123"
   - Runs automatically on first login

4. **first-login-setup** - User environment setup
   - Creates standard directories
   - Sets up multi-monitor helper scripts
   - Configures basic user environment

5. **post-install.sh** - Advanced system configuration
   - Configures read-only root filesystem
   - Sets up NVIDIA drivers with persistence
   - Enables IOMMU for PCIe passthrough
   - Configures libvirt for KVM virtualization
   - Creates system documentation

6. **prepare-usb.sh** - Automated USB preparation script
   - Writes ISO to USB
   - Copies all configuration files
   - Sets correct permissions
   - Creates quick start guide

7. **configure-installer.sh** - Interactive configuration
   - Sets LUKS encryption password
   - Customizes hostname and timezone
   - Makes configuration user-friendly

## Quick Start - Prepare Your USB Drive

Run this single command to prepare your USB drive:

```bash
sudo /home/spooky/Documents/projects/install-arch/prepare-usb.sh
```

This will:
- Write the Arch ISO to /dev/sdb
- Copy all configuration files
- Create installation guides
- Make everything bootable and ready

**WARNING: This will erase everything on /dev/sdb (your USB drive)!**

## Installation Process

### Step 1: Prepare USB (run on your current system)
```bash
sudo /home/spooky/Documents/projects/install-arch/prepare-usb.sh
```

### Step 2: Configure BIOS on target PC
Enter BIOS and enable:
- **VT-x / VT-d** (Intel Virtualization)
- **IOMMU** (for GPU passthrough)
- **Above 4G Decoding** (for PCIe devices)
- **Resizable BAR** (optional, for RTX 5080 performance)

Set USB as first boot device.

### Step 3: Boot from USB and Install

Once booted into Arch Linux live environment:

```bash
# Mount USB and copy configs
mkdir -p /root/archconfig
mount /dev/disk/by-label/CONFIGS /mnt
cp /mnt/archinstall/* /root/archconfig/
umount /mnt

# Configure encryption password (IMPORTANT!)
cd /root/archconfig
./configure-installer.sh

# Run automated installer
archinstall --config /root/archconfig/archinstall-config.json
```

The installer will:
- Partition your 2TB NVMe drive
- Set up LUKS encryption
- Create BTRFS filesystems with compression
- Install base system + KDE Plasma
- Install development tools
- Install virtualization tools (KVM, QEMU, Docker)
- Install NVIDIA drivers
- Configure user 'kang' with sudo access

### Step 4: First Boot

After installation completes and system reboots:

1. **Enter LUKS password** at boot
2. **Login as kang** (password: changeme123)
3. **Change password** (forced immediately)
4. **Log out and log back in**

### Step 5: Post-Installation Configuration

```bash
# Mount the USB drive again (or use network transfer)
# Copy post-install script
sudo bash /path/to/post-install.sh

# Reboot to activate read-only root
sudo reboot
```

## System Features

### Hardware Support
- ✅ Intel 14700K with optimized settings
- ✅ ASUS Z790 TUF motherboard
- ✅ NVIDIA RTX 5080 with proprietary drivers
- ✅ 48GB DDR5 RAM fully utilized
- ✅ 2TB NVMe with optimal partitioning

### Security Features
- ✅ LUKS full-disk encryption (except /boot)
- ✅ Read-only root filesystem
- ✅ Forced password change on first login
- ✅ No root login (sudo only)
- ✅ Secure boot compatible (systemd-boot)

### Virtualization Ready
- ✅ KVM/QEMU with libvirt
- ✅ IOMMU enabled for PCIe passthrough
- ✅ NVIDIA GPU passthrough capable
- ✅ Docker and docker-compose
- ✅ Bridge networking configured
- ✅ UEFI firmware for VMs (OVMF)

### Development Environment
- ✅ Full base-devel toolchain
- ✅ Git, vim, nano
- ✅ Python with pip
- ✅ Docker for containers
- ✅ SSH server enabled
- ✅ Comprehensive CLI tools

### Desktop Environment
- ✅ KDE Plasma 6 with Wayland
- ✅ Multi-monitor support (2-3 monitors)
- ✅ NVIDIA Wayland compatibility
- ✅ Display configuration tools
- ✅ Modern, stable, customizable

### File Systems
- ✅ BTRFS with zstd compression (level 1)
- ✅ Automatic snapshots support (snapper)
- ✅ Separate /data partition (1.8TB)
- ✅ Efficient storage management

## Daily Usage

### System Updates
```bash
sudo system-update
```

### Multi-Monitor Configuration
```bash
setup-monitors
# Or use: System Settings > Display Configuration
```

### Virtual Machines
```bash
virt-manager           # GUI
virsh list --all       # CLI
```

### GPU Passthrough Setup
```bash
# Find GPU PCI IDs
lspci -nn | grep -i nvidia

# Edit VFIO configuration
sudo system-update
# Then edit: /etc/modprobe.d/vfio.conf
```

### Check Virtualization
```bash
# Check IOMMU groups
for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done
```

## Partition Layout

| Partition | Size | Type | Encrypted | Mount | Purpose |
|-----------|------|------|-----------|-------|---------|
| /dev/nvme0n1p1 | 1GB | FAT32 | No | /boot | EFI boot |
| /dev/nvme0n1p2 | 200GB | BTRFS | Yes | / | System (read-only) |
| /dev/nvme0n1p3 | ~1.8TB | BTRFS | Yes | /data | User data |

### BTRFS Subvolumes
- **@root** → / (read-only)
- **@home** → /home (read-write)
- **@snapshots** → /.snapshots (snapshots)
- **@log** → /var/log (read-write)
- **@data** → /data (read-write, main storage)

## Default Credentials

- **Username**: kang
- **Initial Password**: changeme123 (must change on first login)
- **Root Account**: Disabled (use sudo)

## Installed Packages

### Core System
- linux, linux-lts (dual kernels)
- base-devel (compiler toolchain)
- intel-ucode (CPU microcode)
- nvidia-dkms (GPU drivers)

### Desktop
- plasma-desktop (KDE Plasma)
- sddm (display manager)
- kde-applications-meta
- firefox

### Virtualization
- qemu-full
- libvirt
- virt-manager
- edk2-ovmf
- docker, docker-compose

### Development
- git, vim, nano
- python, python-pip
- base-devel
- tmux, htop

### Utilities
- btrfs-progs, snapper
- networkmanager
- openssh
- cups (printing)
- bluez (bluetooth)

## Troubleshooting

### Can't Install Packages
Root is read-only. Use: `sudo system-update`

### Display Issues
Configure via: System Settings > Display Configuration

### NVIDIA Not Working
```bash
sudo modprobe nvidia
sudo systemctl restart sddm
```

### IOMMU Not Working
Check BIOS: VT-d and IOMMU must be enabled

### Forgot Encryption Password
**Cannot recover!** Encryption password is required at boot.

## Documentation Locations

- Main guide: /usr/share/doc/arch-setup/README.md
- Update script: /usr/local/bin/system-update
- MOTD: /etc/motd
- This guide: USB drive /archinstall/README.md

## Support Resources

- **ArchWiki**: https://wiki.archlinux.org/
- **Forums**: https://bbs.archlinux.org/
- **KVM**: https://wiki.archlinux.org/title/KVM
- **NVIDIA**: https://wiki.archlinux.org/title/NVIDIA

## Next Steps After Installation

1. ✅ Change password (forced)
2. ⚙️ Configure display/monitors
3. ⚙️ Set up GPU passthrough (optional)
4. ⚙️ Install additional software
5. ⚙️ Create virtual machines
6. ⚙️ Configure backups
7. ⚙️ Set up Btrfs snapshots

## File Locations

All configuration files are in:
```
/home/spooky/Documents/projects/install-arch/configs/
```

USB preparation script:
```
/home/spooky/Documents/projects/install-arch/prepare-usb.sh
```

ISO location:
```
/home/spooky/Documents/projects/install-arch/iso/arch/archlinux-2025.12.01-x86_64.iso
```

---

**Ready to proceed? Run:**

```bash
sudo /home/spooky/Documents/projects/install-arch/prepare-usb.sh
```

This will prepare your USB drive for installation!
