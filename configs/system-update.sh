#!/bin/bash
# System Update Script for Read-Only Root with Btrfs Snapshots
# This script creates a snapshot, updates in a chroot, and swaps to the new snapshot

set -e

# Logging
LOG_FILE="/var/log/system-update.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Arch Linux System Update Script (Read-Only Root) ===${NC}"
echo -e "${YELLOW}This script uses Btrfs snapshots and chroot for safe updates${NC}"
echo "Log file: $LOG_FILE"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" 
   echo "Usage: sudo system-update"
   exit 1
fi

# Check if we're on Btrfs
if ! mount | grep -q " / btrfs"; then
    echo -e "${RED}Error: Root filesystem is not Btrfs. This script requires Btrfs.${NC}"
    exit 1
fi

# Get current subvolume
CURRENT_SUBVOL=$(btrfs subvolume show / | grep "Name:" | awk '{print $2}')
if [ -z "$CURRENT_SUBVOL" ]; then
    echo -e "${RED}Error: Could not determine current subvolume${NC}"
    exit 1
fi

echo -e "${GREEN}Current root subvolume: $CURRENT_SUBVOL${NC}"

# Create timestamp for snapshot
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_NAME="${CURRENT_SUBVOL}_update_${TIMESTAMP}"

# Create snapshot
echo -e "${YELLOW}Creating Btrfs snapshot: $SNAPSHOT_NAME${NC}"
btrfs subvolume snapshot / "$SNAPSHOT_NAME"
echo -e "${GREEN}Snapshot created successfully${NC}"

# Mount the snapshot read-write
MOUNT_POINT="/mnt/update"
mkdir -p "$MOUNT_POINT"

echo -e "${YELLOW}Mounting snapshot at $MOUNT_POINT${NC}"
mount -t btrfs -o subvol="$SNAPSHOT_NAME" /dev/mapper/root "$MOUNT_POINT"

# Bind mount necessary directories for chroot
echo -e "${YELLOW}Setting up chroot environment${NC}"
mount -t proc proc "$MOUNT_POINT/proc"
mount -t sysfs sys "$MOUNT_POINT/sys"
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /dev/pts "$MOUNT_POINT/dev/pts"
mount -t devpts devpts "$MOUNT_POINT/dev/pts"
mount -t tmpfs tmpfs "$MOUNT_POINT/dev/shm"
mount --bind /run "$MOUNT_POINT/run"

# Copy resolv.conf for network
cp /etc/resolv.conf "$MOUNT_POINT/etc/resolv.conf"

# Function to cleanup mounts
cleanup() {
    echo -e "${YELLOW}Cleaning up chroot environment...${NC}"
    umount -l "$MOUNT_POINT/dev/shm" 2>/dev/null || true
    umount -l "$MOUNT_POINT/dev/pts" 2>/dev/null || true
    umount -l "$MOUNT_POINT/dev" 2>/dev/null || true
    umount -l "$MOUNT_POINT/run" 2>/dev/null || true
    umount -l "$MOUNT_POINT/sys" 2>/dev/null || true
    umount -l "$MOUNT_POINT/proc" 2>/dev/null || true
    umount "$MOUNT_POINT" 2>/dev/null || true
    rmdir "$MOUNT_POINT" 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

echo -e "${GREEN}Chroot environment ready${NC}"
echo ""

# Perform update in chroot
echo -e "${BLUE}Entering chroot to perform system update...${NC}"
echo -e "${YELLOW}Commands to run in chroot:${NC}"
echo "  pacman -Sy"
echo "  pacman -Su"
echo "  paccache -rk 2  # Clean cache"
echo ""

# Run the update commands in chroot
chroot "$MOUNT_POINT" /bin/bash -c "
set -e
echo 'Syncing package databases...'
pacman -Sy
echo 'Performing system upgrade...'
pacman -Su --noconfirm
echo 'Cleaning package cache...'
paccache -rk 2
echo 'Update complete!'
"

echo -e "${GREEN}Update completed successfully in chroot${NC}"
echo ""

# Ask for confirmation before swapping
echo -e "${YELLOW}Update completed. Ready to swap to new snapshot.${NC}"
read -p "Swap to updated snapshot and reboot? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Update cancelled. Cleaning up...${NC}"
    # Delete the snapshot
    umount "$MOUNT_POINT" || true
    btrfs subvolume delete "$SNAPSHOT_NAME"
    echo -e "${GREEN}Snapshot deleted${NC}"
    exit 0
fi

# Set the new snapshot as default
echo -e "${YELLOW}Setting new snapshot as default subvolume${NC}"
btrfs subvolume set-default "$SNAPSHOT_NAME" /

# Rename subvolumes for clarity
OLD_NAME="${CURRENT_SUBVOL}_old_${TIMESTAMP}"
echo -e "${YELLOW}Renaming old subvolume to $OLD_NAME${NC}"
mv "$CURRENT_SUBVOL" "$OLD_NAME"

echo -e "${YELLOW}Renaming new snapshot to $CURRENT_SUBVOL${NC}"
mv "$SNAPSHOT_NAME" "$CURRENT_SUBVOL"

echo -e "${GREEN}Subvolume swap complete${NC}"
echo -e "${BLUE}Rebooting system...${NC}"

# Reboot
reboot
