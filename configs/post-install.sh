#!/bin/bash
# Post-installation script to configure read-only root and other advanced features
# Run this after the base installation completes

set -e

echo "=== Post-Installation Configuration ==="
echo "Configuring read-only root filesystem and virtualization..."

# Mount point (adjust if needed for chroot environment)
ROOT_MOUNT="/mnt"

# Check if we're in the installer environment
if [ ! -d "$ROOT_MOUNT/etc" ]; then
    ROOT_MOUNT=""
fi

# Configure fstab for read-only root
echo "Configuring fstab for read-only root..."
sed -i 's|\(.*\s/\s.*btrfs\s.*\)|\1,ro|' "$ROOT_MOUNT/etc/fstab"

# Ensure /var/log is writable (already a subvolume)
if ! grep -q "/var/log" "$ROOT_MOUNT/etc/fstab"; then
    # Already should be there from btrfs subvolumes
    echo "Note: /var/log should be configured as a separate btrfs subvolume"
fi

# Create systemd tmpfiles for writable directories
cat > "$ROOT_MOUNT/etc/tmpfiles.d/var-rw.conf" << 'EOF'
# Writable directories needed for system operation
d /var/tmp 1777 root root -
d /var/cache 0755 root root -
d /var/lib 0755 root root -
d /var/spool 0755 root root -
EOF

# Configure NVIDIA for persistence
cat > "$ROOT_MOUNT/etc/modprobe.d/nvidia.conf" << 'EOF'
# Enable NVIDIA persistence mode
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF

# Configure IOMMU for virtualization
if [ -f "$ROOT_MOUNT/boot/loader/entries/arch.conf" ]; then
    echo "Configuring IOMMU for PCIe passthrough..."
    sed -i 's/options.*/& intel_iommu=on iommu=pt/' "$ROOT_MOUNT/boot/loader/entries/"*.conf
fi

# Configure libvirt for UEFI
echo "Configuring libvirt for UEFI and QEMU..."
mkdir -p "$ROOT_MOUNT/etc/libvirt"
cat > "$ROOT_MOUNT/etc/libvirt/qemu.conf" << 'EOF'
# QEMU configuration for UEFI
nvram = [
    "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd:/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
]

# User and group for QEMU processes
user = "kang"
group = "kvm"
EOF

# Configure KVM modules
cat > "$ROOT_MOUNT/etc/modprobe.d/kvm.conf" << 'EOF'
# KVM Configuration
options kvm ignore_msrs=1
options kvm report_ignored_msrs=0

# Intel specific
options kvm_intel nested=1
options kvm_intel enable_shadow_vmcs=1
options kvm_intel enable_apicv=1
options kvm_intel ept=1
EOF

# Enable nested virtualization
echo "options kvm_intel nested=1" > "$ROOT_MOUNT/etc/modprobe.d/kvm-nested.conf"

# Configure VFIO for GPU passthrough (placeholder - needs specific PCI IDs)
cat > "$ROOT_MOUNT/etc/modprobe.d/vfio.conf" << 'EOF'
# VFIO Configuration for GPU passthrough
# Uncomment and configure with your GPU's PCI IDs
# options vfio-pci ids=10de:XXXX,10de:XXXX
# softdep nvidia pre: vfio-pci
EOF

# Add helpful message
cat > "$ROOT_MOUNT/etc/motd" << 'EOF'
================================================================================
        Welcome to Kang's Arch Linux Virtualization Host
================================================================================

System Configuration:
  - Read-only root filesystem (security & stability)
  - LUKS encrypted partitions with BTRFS & zstd compression
  - Virtualization ready: KVM, QEMU, libvirt
  - NVIDIA GPU with proprietary drivers
  - Intel 14700K with IOMMU enabled

Important Commands:
  system-update          - Update system (handles read-only root)
  setup-monitors        - Configure multi-monitor setup
  virsh list --all      - List virtual machines
  virt-manager          - Launch VM manager (GUI)

Data Partition: /data (large, encrypted, read-write)
User Data: /home/kang (encrypted, read-write)

Documentation: See /usr/share/doc/arch-setup/README.md

================================================================================
EOF

# Create documentation directory
mkdir -p "$ROOT_MOUNT/usr/share/doc/arch-setup"

cat > "$ROOT_MOUNT/usr/share/doc/arch-setup/README.md" << 'EOF'
# Arch Linux Virtualization Host Setup Guide

## System Overview

This system is configured as a virtualization host with the following features:

- **Read-Only Root**: The root filesystem is mounted read-only for stability and security
- **Encrypted Storage**: LUKS encryption on all data partitions
- **BTRFS**: Modern filesystem with compression and snapshot support
- **KVM/QEMU**: Full virtualization support with PCIe passthrough capability

## Important Locations

- `/data` - Large data partition for VMs, containers, and general storage (1.8TB)
- `/home/kang` - User home directory (encrypted)
- `/boot` - Unencrypted EFI boot partition (ext4)

## System Updates

To update the system, use the provided script:

```bash
sudo system-update
```

This script:
1. Temporarily remounts root as read-write
2. Performs system update with pacman
3. Automatically remounts root as read-only

## GPU Passthrough Configuration

The system has IOMMU enabled. To configure GPU passthrough:

1. Find your GPU's PCI IDs:
   ```bash
   lspci -nn | grep -i nvidia
   ```

2. Edit `/etc/modprobe.d/vfio.conf` and add the IDs:
   ```bash
   sudo system-update  # This remounts root as RW
   sudo nano /etc/modprobe.d/vfio.conf
   # Add: options vfio-pci ids=10de:XXXX,10de:XXXX
   ```

3. Rebuild initramfs:
   ```bash
   sudo mkinitcpio -P
   ```

4. Reboot

## Multi-Monitor Setup

KDE Plasma handles multi-monitor configurations through:
- System Settings > Display Configuration (GUI)
- `kscreen-doctor` command-line tool

Or use the helper script:
```bash
setup-monitors
```

## Virtualization

### Start libvirtd
```bash
sudo systemctl start libvirtd
```

### Create a VM
```bash
virt-manager  # GUI tool
# or
virsh define vm-config.xml  # Command line
```

### VM Storage
Store VM disk images in `/data/vms/` for best performance and space.

## Snapshotting

Btrfs subvolumes are configured for easy snapshotting:

```bash
# Create snapshot
sudo btrfs subvolume snapshot / /.snapshots/root-$(date +%Y%m%d)

# List snapshots
sudo btrfs subvolume list /

# Restore from snapshot (requires remounting)
sudo mount -o remount,rw /
sudo btrfs subvolume delete /.snapshots/old-snapshot
```

## Troubleshooting

### Root is read-only
This is intentional. Use `system-update` for system changes, or manually:
```bash
sudo mount -o remount,rw /
# Make changes
sudo mount -o remount,ro /
```

### NVIDIA driver issues
```bash
sudo systemctl restart nvidia-persistenced
sudo modprobe nvidia
```

### Checking IOMMU groups
```bash
for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done
```
EOF

echo "Post-installation configuration complete!"
echo "The system will be configured with read-only root on first boot."
