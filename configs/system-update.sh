#!/bin/bash
# System Update Script for Read-Only Root with Btrfs Snapshots
# This script creates a snapshot, updates in a chroot, and swaps to the new snapshot

set -euo pipefail

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

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}DRY RUN MODE: No changes will be made${NC}"
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
    shift
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" 
   echo "Usage: sudo system-update"
   exit 1
fi

# Get root device dynamically
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
if [ -z "$ROOT_DEVICE" ]; then
    echo -e "${RED}Error: Could not determine root device${NC}"
    exit 1
fi

echo -e "${GREEN}Root device: $ROOT_DEVICE${NC}"

# Check filesystem type
FS_TYPE=$(findmnt -n -o FSTYPE /)
if [ "$FS_TYPE" != "btrfs" ]; then
    echo -e "${RED}Error: Read-only root updates require Btrfs filesystem${NC}"
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
if [ "$DRY_RUN" = false ]; then
    btrfs subvolume snapshot / "$SNAPSHOT_NAME"
    echo -e "${GREEN}Snapshot created successfully${NC}"
else
    echo -e "${BLUE}[DRY RUN] Would create snapshot: $SNAPSHOT_NAME${NC}"
fi

# Mount the snapshot read-write
MOUNT_POINT="/mnt/update"
mkdir -p "$MOUNT_POINT"

# Function to cleanup mounts
cleanup() {
    echo -e "${YELLOW}Cleaning up mounts...${NC}"
    umount "$MOUNT_POINT/dev/shm" 2>/dev/null || true
    umount "$MOUNT_POINT/dev/pts" 2>/dev/null || true
    umount "$MOUNT_POINT/dev" 2>/dev/null || true
    umount "$MOUNT_POINT/run" 2>/dev/null || true
    umount "$MOUNT_POINT/sys" 2>/dev/null || true
    umount "$MOUNT_POINT/proc" 2>/dev/null || true
    umount "$MOUNT_POINT" 2>/dev/null || true
    rmdir "$MOUNT_POINT" 2>/dev/null || true
}

# Function to rollback on failure
rollback() {
    echo -e "${RED}Update failed. Rolling back...${NC}"
    cleanup
    if [ -n "$SNAPSHOT_NAME" ] && btrfs subvolume show "$SNAPSHOT_NAME" >/dev/null 2>&1; then
        echo -e "${YELLOW}Deleting failed snapshot: $SNAPSHOT_NAME${NC}"
        btrfs subvolume delete "$SNAPSHOT_NAME" 2>/dev/null || true
    fi
    echo -e "${GREEN}Rollback complete${NC}"
}

# Set trap for rollback and cleanup
trap rollback EXIT INT TERM

echo -e "${YELLOW}Mounting snapshot at $MOUNT_POINT${NC}"
if [ "$DRY_RUN" = false ]; then
    mount -t btrfs -o subvol="$SNAPSHOT_NAME" "$ROOT_DEVICE" "$MOUNT_POINT"
else
    echo -e "${BLUE}[DRY RUN] Would mount snapshot${NC}"
fi

# Validate snapshot integrity
echo -e "${YELLOW}Validating snapshot integrity...${NC}"
if [ "$DRY_RUN" = false ]; then
    if [ ! -f "$MOUNT_POINT/bin/bash" ] || [ ! -f "$MOUNT_POINT/usr/bin/pacman" ] || [ ! -d "$MOUNT_POINT/etc" ]; then
        echo -e "${RED}Error: Snapshot appears corrupted or incomplete${NC}"
        exit 1
    fi
    echo -e "${GREEN}Snapshot validation passed${NC}"
else
    echo -e "${BLUE}[DRY RUN] Would validate snapshot${NC}"
fi

# Bind mount necessary directories for chroot
echo -e "${YELLOW}Setting up chroot environment${NC}"
if [ "$DRY_RUN" = false ]; then
    mount -t proc proc "$MOUNT_POINT/proc"
    mount -t sysfs sys "$MOUNT_POINT/sys"
    mount --bind /dev "$MOUNT_POINT/dev"
    mount --bind /dev/pts "$MOUNT_POINT/dev/pts"
    mount -t devpts devpts "$MOUNT_POINT/dev/pts"
    mount -t tmpfs tmpfs "$MOUNT_POINT/dev/shm"
    mount --bind /run "$MOUNT_POINT/run"

    # Copy resolv.conf for network
    cp /etc/resolv.conf "$MOUNT_POINT/etc/resolv.conf"
    echo -e "${GREEN}Chroot environment ready${NC}"
else
    echo -e "${BLUE}[DRY RUN] Would setup chroot environment${NC}"
fi
echo ""

# Perform update in chroot
echo -e "${BLUE}Entering chroot to perform system update...${NC}"
echo -e "${YELLOW}Commands to run in chroot:${NC}"
echo "  pacman -Sy"
echo "  pacman -Su"
echo "  paccache -rk 2  # Clean cache"
echo ""

if [ "$DRY_RUN" = false ]; then
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
    " 2>&1 | tee -a "$LOG_FILE"
    echo -e "${GREEN}Update completed successfully in chroot${NC}"
else
    echo -e "${BLUE}[DRY RUN] Would perform update in chroot${NC}"
fi
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
if [ "$DRY_RUN" = false ]; then
    btrfs subvolume set-default "$SNAPSHOT_NAME" /
else
    echo -e "${BLUE}[DRY RUN] Would set default to: $SNAPSHOT_NAME${NC}"
fi

# Rename subvolumes for clarity
OLD_NAME="${CURRENT_SUBVOL}_old_${TIMESTAMP}"
echo -e "${YELLOW}Renaming old subvolume to $OLD_NAME${NC}"
if [ "$DRY_RUN" = false ]; then
    mv "$CURRENT_SUBVOL" "$OLD_NAME"
else
    echo -e "${BLUE}[DRY RUN] Would rename $CURRENT_SUBVOL to $OLD_NAME${NC}"
fi

echo -e "${YELLOW}Renaming new snapshot to $CURRENT_SUBVOL${NC}"
if [ "$DRY_RUN" = false ]; then
    mv "$SNAPSHOT_NAME" "$CURRENT_SUBVOL"
else
    echo -e "${BLUE}[DRY RUN] Would rename $SNAPSHOT_NAME to $CURRENT_SUBVOL${NC}"
fi

echo -e "${GREEN}Subvolume swap complete${NC}"
echo -e "${BLUE}Rebooting system...${NC}"

if [ "$DRY_RUN" = false ]; then
    reboot
else
    echo -e "${BLUE}[DRY RUN] Would reboot system${NC}"
fi
