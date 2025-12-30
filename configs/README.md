# Arch Linux Automated Installer - Configuration Guide

## Overview

This automated installer configures Arch Linux for a high-performance virtualization host with:
- Read-only root filesystem for stability
- LUKS encrypted BTRFS partitions with zstd compression
- KVM/QEMU virtualization with PCIe passthrough support
- NVIDIA RTX 5080 with proprietary drivers
- Intel 14700K with IOMMU enabled
- KDE Plasma desktop environment
- Multi-monitor support

## Hardware Requirements

- Intel 14700K CPU
- ASUS Z790 TUF Motherboard
- NVIDIA GeForce RTX 5080
- 48GB DDR5 RAM
- 2TB NVMe SSD

## Disk Layout

The installer will automatically partition your 2TB NVMe drive as follows:

1. **Boot Partition** (1GB, FAT32, unencrypted)
   - `/boot` - EFI System Partition
   - Compatible with UEFI boot
   - No encryption for maximum compatibility

2. **Root Partition** (200GB, BTRFS, LUKS encrypted)
   - `/` - Root filesystem (read-only after setup)
   - `/home` - User home directory
   - `/.snapshots` - Btrfs snapshots
   - `/var/log` - System logs (writable)
   - Zstd compression level 1
   - LUKS encryption

3. **Data Partition** (~1.8TB, BTRFS, LUKS encrypted)
   - `/data` - Large data partition for VMs, containers, projects
   - Zstd compression level 1
   - LUKS encryption
   - Fully writable

## Installation Instructions

### 1. Prepare the USB Drive

**WARNING: This will erase all data on the USB drive!**

Use the automated USB preparation script:

```bash
# Run the USB preparation script (recommended)
sudo /home/spooky/Documents/projects/install-arch/prepare-usb.sh
```

The script will:
1. Download the Arch Linux ISO if not present
2. Create two partitions on the USB:
   - Partition 1: Bootable Arch ISO (extracted contents, ~2.5GB)
   - Partition 2: Configuration files (remaining space)
3. Extract ISO contents and copy to bootable partition
4. Copy all configuration files to the config partition
5. Verify bootloader files are present
6. Create a QUICKSTART.txt guide on the USB

**Note**: The script now extracts ISO contents to a FAT32 partition instead of using `dd` to write the ISO directly. This approach:
- Allows for a separate configuration partition
- Avoids partition table conflicts
- Ensures proper bootability with modern UEFI systems

### 2. Boot from USB

1. Insert the USB drive into your target PC
2. Enter BIOS/UEFI (usually F2, F12, or DEL)
3. Enable the following in BIOS:
   - **VT-x / VT-d** (Intel Virtualization Technology)
   - **IOMMU** (Input-Output Memory Management Unit)
   - **Above 4G Decoding** (for GPU passthrough)
   - **Resizable BAR** (optional, for GPU performance)
4. Set USB as first boot device
5. Save and reboot

### 3. Run the Installer

Once booted into the Arch Linux live environment:

```bash
# Copy configuration from USB to RAM disk
mkdir -p /root/archinstall-configs
mount /dev/disk/by-label/CONFIGS /mnt
cp /mnt/archinstall-configs/* /root/archinstall-configs/
umount /mnt

# Set encryption password
# You'll need to edit the config to add your LUKS password
nano /root/archinstall-configs/archinstall-config.json
# Find the "btrfs_encryption" sections and add your password

# Run the automated installer
archinstall --config /root/archinstall-configs/archinstall-config.json
```

**Alternative: Manual archinstall**

If you prefer to use the interactive installer:

```bash
archinstall
```

Then select:
- Keyboard: US
- Mirror region: United States
- Locale: en_US.UTF-8
- Disk: /dev/nvme0n1 (select "Custom" and import config)
- Desktop: KDE Plasma
- Network: NetworkManager

### 4. Post-Installation Setup

After installation completes and you reboot:

```bash
# Login as kang (password: changeme123)
# You'll be forced to change the password immediately

# Copy post-install scripts to system
sudo mkdir -p /usr/local/bin
sudo mkdir -p /etc/profile.d

sudo cp /path/to/usb/archinstall/system-update /usr/local/bin/
sudo cp /path/to/usb/archinstall/first-login-setup /usr/local/bin/
sudo cp /path/to/usb/archinstall/force-password-change.sh /etc/profile.d/

sudo chmod +x /usr/local/bin/system-update
sudo chmod +x /usr/local/bin/first-login-setup
sudo chmod +x /etc/profile.d/force-password-change.sh

# Run post-install configuration
sudo bash /path/to/usb/archinstall/post-install.sh

# Reboot to activate read-only root
sudo reboot
```

## First Login

1. **Password Change**: You'll be forced to change your password from "changeme123"
2. **Display Configuration**: Configure monitors in System Settings > Display Configuration
3. **NVIDIA Drivers**: Should be working out of the box
4. **Virtualization**: libvirtd and docker are enabled and ready

## Key Features

### Read-Only Root Filesystem

The root filesystem is mounted read-only for stability and security. To update the system:

```bash
sudo system-update
```

This script automatically:
- Remounts root as read-write
- Updates packages with pacman
- Remounts root as read-only

### Encryption

Both root and data partitions are encrypted with LUKS. You'll need to enter your encryption password at boot.

### Virtualization

The system is pre-configured for KVM/QEMU:

```bash
# Check virtualization
lscpu | grep Virtualization

# Check IOMMU
dmesg | grep -i iommu

# Start virt-manager
virt-manager

# Check libvirt
sudo systemctl status libvirtd
```

### GPU Passthrough

IOMMU is enabled. To configure GPU passthrough:

1. Find GPU PCI IDs: `lspci -nn | grep -i nvidia`
2. Configure VFIO: See `/usr/share/doc/arch-setup/README.md`

### Multi-Monitor Support

KDE Plasma provides excellent multi-monitor support:
- System Settings > Display Configuration
- Automatic display detection
- Per-monitor scaling
- Display profiles

## Troubleshooting

### Cannot Install Software

Remember: root is read-only. Use:
```bash
sudo system-update  # For system packages
```

Or install to `/data`:
```bash
# For user applications, use flatpak or docker
flatpak install app-name
```

### NVIDIA Driver Not Loading

```bash
sudo modprobe nvidia
sudo systemctl restart sddm
```

### No IOMMU Groups

Check BIOS settings:
- VT-d must be enabled
- IOMMU must be enabled

## System Maintenance

```bash
# Update system
sudo system-update

# Clean package cache
sudo paccache -r

# Check system logs
sudo journalctl -xe

# Create system snapshot
sudo btrfs subvolume snapshot / /.snapshots/backup-$(date +%Y%m%d)

# Check disk usage
btrfs filesystem df /
btrfs filesystem df /data
```

## Default Credentials

- **Username**: kang
- **Password**: changeme123 (must change on first login)
- **Root**: Disabled (use sudo)

## Installed Software

- **Desktop**: KDE Plasma with Wayland support
- **Dev Tools**: git, vim, nano, base-devel, python, docker
- **Virtualization**: qemu, libvirt, virt-manager, docker
- **Utilities**: htop, tmux, neofetch, firefox
- **Drivers**: nvidia-dkms, intel-ucode

## Support

For Arch Linux help:
- ArchWiki: https://wiki.archlinux.org/
- Forums: https://bbs.archlinux.org/
- IRC: #archlinux on Libera.Chat

## License

Configuration files are provided as-is. Arch Linux is licensed under various open-source licenses.
