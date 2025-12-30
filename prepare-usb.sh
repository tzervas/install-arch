#!/bin/bash
# USB Preparation Script for Arch Linux Automated Installer

set -e

# Cleanup function
cleanup() {
    local exit_code=$?
    echo -e "${YELLOW}Cleaning up...${NC}"
    # Unmount config partition if mounted
    if [ -d "${MOUNT_POINT:-}" ] && mountpoint -q "${MOUNT_POINT:-}"; then
        umount "${MOUNT_POINT:-}" || true
        rmdir "${MOUNT_POINT:-}" || true
    fi
    # Unmount ISO mount if it exists
    if [ -d "${ISO_MOUNT:-}" ] && mountpoint -q "${ISO_MOUNT:-}"; then
        umount "${ISO_MOUNT:-}" || true
        rmdir "${ISO_MOUNT:-}" || true
    fi
    # Unmount USB mount if it exists
    if [ -d "${USB_MOUNT:-}" ] && mountpoint -q "${USB_MOUNT:-}"; then
        umount "${USB_MOUNT:-}" || true
        rmdir "${USB_MOUNT:-}" || true
    fi
    # Unmount USB verify mount if it exists
    if [ -d "${USB_VERIFY_MOUNT:-}" ] && mountpoint -q "${USB_VERIFY_MOUNT:-}"; then
        umount "${USB_VERIFY_MOUNT:-}" || true
        rmdir "${USB_VERIFY_MOUNT:-}" || true
    fi
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Script failed with exit code $exit_code${NC}"
        echo -e "${YELLOW}Recovery suggestions:${NC}"
        echo "1. Check USB device: lsblk"
        echo "2. Re-run script after fixing issues"
        echo "3. Verify ISO integrity manually"
    fi
    exit $exit_code
}

trap cleanup EXIT

# Configuration
ISO_DIR="/home/spooky/Documents/projects/install-arch/iso"
ISO_NAME="archlinux-2025.12.01-x86_64.iso"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"
# Dynamic URL construction for checksum retrieval
ISO_BASE_URL="https://mirror.rackspace.com/archlinux/iso/2025.12.01"
ISO_URL="${ISO_BASE_URL}/${ISO_NAME}"
CONFIG_DIR="/home/spooky/Documents/projects/install-arch/configs"
USB_DEVICE="/dev/sdb"
ISO_PARTITION_SIZE_MB=2560  # 2.5GB for ISO contents

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Arch Linux USB Installer Preparation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   echo "Usage: sudo $0"
   exit 1
fi

# Check and download ISO if needed
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${YELLOW}ISO file not found. Downloading from Arch Linux mirror...${NC}"
    mkdir -p "$ISO_DIR"
    if command -v wget >/dev/null 2>&1; then
        wget -O "$ISO_PATH" "$ISO_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -o "$ISO_PATH" "$ISO_URL"
    else
        echo -e "${RED}Error: Neither wget nor curl found. Please install one to download the ISO.${NC}"
        exit 1
    fi

    if [ ! -f "$ISO_PATH" ]; then
        echo -e "${RED}Error: Failed to download ISO${NC}"
        exit 1
    fi
    echo -e "${GREEN}ISO downloaded successfully${NC}"
else
    echo -e "${GREEN}Using existing ISO: $ISO_PATH${NC}"
fi

# Verify ISO integrity with dynamic checksum retrieval
echo -e "${YELLOW}Verifying ISO integrity...${NC}"

# Enhanced checksum verification with dynamic retrieval
verify_iso_checksum() {
    local iso_path="$1"
    local local_checksum_file="$2"
    local iso_name="$3"
    local iso_url="$4"

    echo -e "${BLUE}Performing multi-source checksum verification...${NC}"

    # Calculate actual checksum
    local actual_checksum
    actual_checksum=$(sha256sum "$iso_path" | awk '{print $1}')
    echo -e "${BLUE}Calculated checksum: ${actual_checksum}${NC}"

    # Check local checksum file first
    local local_checksum=""
    if [ -f "$local_checksum_file" ]; then
        local_checksum=$(grep "$iso_name" "$local_checksum_file" | awk '{print $1}' | head -1)
        if [ -n "$local_checksum" ]; then
            echo -e "${BLUE}Found local checksum: ${local_checksum}${NC}"
            if [ "$local_checksum" = "$actual_checksum" ]; then
                echo -e "${GREEN}✓ Local checksum verification passed${NC}"
            else
                echo -e "${RED}✗ Local checksum verification failed!${NC}"
                echo -e "${YELLOW}Expected: $local_checksum${NC}"
                return 1
            fi
        fi
    fi

    # Try to download official checksums from Arch Linux
    echo -e "${BLUE}Attempting to download official checksums...${NC}"
    local official_checksum=""
    local checksum_url="${iso_url%/*}/sha256sums.txt"

    # Try multiple mirrors in case one fails
    local mirrors=(
        "https://mirror.rackspace.com/archlinux/iso/2025.12.01"
        "https://geo.mirror.pkgbuild.com/iso/2025.12.01"
        "https://mirrors.kernel.org/archlinux/iso/2025.12.01"
    )

    for mirror in "${mirrors[@]}"; do
        local mirror_checksum_url="${mirror%/*}/sha256sums.txt"
        echo -e "${BLUE}Trying mirror: ${mirror_checksum_url}${NC}"

        if curl -s --max-time 10 "$mirror_checksum_url" -o /tmp/arch-checksums.txt 2>/dev/null; then
            official_checksum=$(grep "$iso_name" /tmp/arch-checksums.txt | awk '{print $1}' | head -1)
            if [ -n "$official_checksum" ]; then
                echo -e "${GREEN}✓ Downloaded official checksum: ${official_checksum}${NC}"
                break
            fi
        fi
    done

    # Clean up temp file
    rm -f /tmp/arch-checksums.txt

    # Verify against official checksum if available
    if [ -n "$official_checksum" ]; then
        if [ "$official_checksum" = "$actual_checksum" ]; then
            echo -e "${GREEN}✓ Official checksum verification passed${NC}"
            return 0
        else
            echo -e "${RED}✗ Official checksum verification failed!${NC}"
            echo -e "${YELLOW}Official: $official_checksum${NC}"
            echo -e "${YELLOW}Actual:   $actual_checksum${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ Could not download official checksums${NC}"
        if [ -n "$local_checksum" ]; then
            echo -e "${YELLOW}⚠ Falling back to local checksum verification only${NC}"
            return 0
        else
            echo -e "${RED}✗ No checksum verification possible!${NC}"
            return 1
        fi
    fi
}

if ! verify_iso_checksum "$ISO_PATH" "$ISO_DIR/sha256sums.txt" "$ISO_NAME" "$ISO_URL"; then
    exit 1
fi
#     echo -e "${RED}Error: ISO verification failed${NC}"
#     exit 1
# fi
echo -e "${YELLOW}Warning: No automatic ISO checksum verification was performed.${NC}"
echo -e "${YELLOW}Please verify the ISO manually (for example: sha256sum \"$ISO_PATH\").${NC}"
# Verify config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}Error: Config directory not found at $CONFIG_DIR${NC}"
    exit 1
fi

# Check USB device
if [ ! -b "$USB_DEVICE" ]; then
    echo -e "${RED}Error: USB device $USB_DEVICE not found${NC}"
    echo "Available devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    exit 1
fi

# Show USB device info
echo -e "${YELLOW}Target USB device:${NC}"
lsblk "$USB_DEVICE"
echo ""

# Final warning
echo -e "${RED}WARNING: This will COMPLETELY ERASE $USB_DEVICE!${NC}"
echo -e "${RED}All data on this device will be permanently lost!${NC}"
echo ""
read -r -p "Are you absolutely sure? Type 'YES' to continue: " confirm

if [ "$confirm" != "YES" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting USB preparation...${NC}"
echo ""

# Unmount any mounted partitions
echo -e "${YELLOW}Unmounting USB device...${NC}"
umount ${USB_DEVICE}* 2>/dev/null || true
sleep 1

# Partition the USB device
echo -e "${YELLOW}Partitioning USB device...${NC}"
parted -s "$USB_DEVICE" mklabel msdos
if ! parted -s "$USB_DEVICE" mkpart primary fat32 1MiB ${ISO_PARTITION_SIZE_MB}MiB; then
    echo -e "${RED}Error: Failed to create ISO partition${NC}"
    exit 1
fi
if ! parted -s "$USB_DEVICE" mkpart primary fat32 ${ISO_PARTITION_SIZE_MB}MiB 100%; then
    echo -e "${RED}Error: Failed to create config partition${NC}"
    exit 1
fi
if ! parted -s "$USB_DEVICE" set 1 boot on; then
    echo -e "${RED}Error: Failed to set boot flag${NC}"
    exit 1
fi

# Wait for partitions to be recognized
echo -e "${YELLOW}Syncing and waiting for partitions...${NC}"
sync
sleep 3
partprobe "$USB_DEVICE" 2>/dev/null || true
sleep 2

# Format the ISO partition
echo -e "${YELLOW}Formatting ISO partition as FAT32...${NC}"
if ! mkfs.vfat -F 32 "${USB_DEVICE}1" -n ARCHISO; then
    echo -e "${RED}Error: Failed to format ISO partition${NC}"
    exit 1
fi

# Wait for formatting to complete
sync
sleep 2

# Mount the ISO partition and extract contents
echo -e "${YELLOW}Extracting ISO contents to USB partition (this will take 5-10 minutes)...${NC}"
ISO_MOUNT=$(mktemp -d)
USB_MOUNT=$(mktemp -d)

# Mount the ISO
if ! mount -o loop,ro "$ISO_PATH" "$ISO_MOUNT"; then
    echo -e "${RED}Error: Failed to mount ISO${NC}"
    rmdir "$ISO_MOUNT" "$USB_MOUNT"
    exit 1
fi

# Mount the USB partition
sleep 2
partprobe "$USB_DEVICE" 2>/dev/null || true
sleep 1
if ! mount "${USB_DEVICE}1" "$USB_MOUNT"; then
    echo -e "${RED}Error: Failed to mount USB partition${NC}"
    umount "$ISO_MOUNT" || true
    rmdir "$ISO_MOUNT" "$USB_MOUNT"
    exit 1
fi

# Copy all files from ISO to USB
echo -e "${YELLOW}Copying files (this may take several minutes)...${NC}"
if ! cp -a "$ISO_MOUNT/"* "$USB_MOUNT/"; then
    echo -e "${RED}Error: Failed to copy ISO contents${NC}"
    umount "$ISO_MOUNT" "$USB_MOUNT" || true
    rmdir "$ISO_MOUNT" "$USB_MOUNT"
    exit 1
fi

# Unmount and clean up
echo -e "${YELLOW}Syncing data...${NC}"
sync
umount "$ISO_MOUNT"
umount "$USB_MOUNT"
rmdir "$ISO_MOUNT" "$USB_MOUNT"

# Verify bootloader files were copied
echo -e "${YELLOW}Verifying bootloader files...${NC}"
USB_VERIFY_MOUNT=$(mktemp -d)
if ! mount "${USB_DEVICE}1" "$USB_VERIFY_MOUNT"; then
    echo -e "${RED}Warning: Could not verify ISO partition contents${NC}"
else
    # Check for essential boot files (Arch ISO structure)
    # The Arch ISO typically has /arch (boot files) and either:
    # - /boot/syslinux (for BIOS boot)
    # - /EFI (for UEFI boot)
    # - /loader (for systemd-boot)
    BOOT_FILES_OK=true
    if [ ! -d "$USB_VERIFY_MOUNT/arch" ]; then
        echo -e "${RED}Error: Missing /arch directory (core Arch ISO files)${NC}"
        BOOT_FILES_OK=false
    fi
    if [ ! -d "$USB_VERIFY_MOUNT/boot" ] && [ ! -d "$USB_VERIFY_MOUNT/EFI" ]; then
        echo -e "${RED}Error: Missing both /boot and /EFI directories${NC}"
        BOOT_FILES_OK=false
    fi
    # Check for at least one bootloader configuration
    if [ ! -f "$USB_VERIFY_MOUNT/boot/syslinux/syslinux.cfg" ] && \
       [ ! -d "$USB_VERIFY_MOUNT/EFI" ] && \
       [ ! -d "$USB_VERIFY_MOUNT/loader" ]; then
        echo -e "${YELLOW}Warning: No recognized bootloader configuration found${NC}"
        echo -e "${YELLOW}Expected: syslinux.cfg, EFI/, or loader/ directory${NC}"
    fi

    if [ "$BOOT_FILES_OK" = true ]; then
        echo -e "${GREEN}Bootloader files verified successfully${NC}"
    else
        umount "$USB_VERIFY_MOUNT"
        rmdir "$USB_VERIFY_MOUNT"
        echo -e "${RED}Error: USB may not be bootable - essential files missing${NC}"
        exit 1
    fi

    umount "$USB_VERIFY_MOUNT"
    rmdir "$USB_VERIFY_MOUNT"
fi

# Wait for kernel to recognize the filesystem
echo ""
echo -e "${YELLOW}Syncing and waiting for device...${NC}"
sync
sleep 3
partprobe "$USB_DEVICE" 2>/dev/null || true
sleep 2

# Format the config partition
echo -e "${YELLOW}Formatting config partition as FAT...${NC}"
if ! mkfs.vfat "${USB_DEVICE}2" -n CONFIGS; then
    echo -e "${RED}Error: Failed to format config partition${NC}"
    exit 1
fi

# Wait for formatting to complete
sync
sleep 2

# Mount the config partition
CONFIG_PARTITION="${USB_DEVICE}2"
echo -e "${GREEN}Using config partition: $CONFIG_PARTITION${NC}"

echo -e "${YELLOW}Mounting config partition...${NC}"
MOUNT_POINT=$(mktemp -d)
sleep 2

# Try mounting with retries
for i in {1..5}; do
    if mount "$CONFIG_PARTITION" "$MOUNT_POINT" 2>/dev/null; then
        echo -e "${GREEN}Mounted successfully on attempt $i${NC}"
        break
    fi
    echo -e "${YELLOW}Mount attempt $i failed, retrying...${NC}"
    sleep 2
    partprobe "$USB_DEVICE" 2>/dev/null || true
    sleep 1
done

if ! mountpoint -q "$MOUNT_POINT"; then
    echo -e "${RED}Error: Failed to mount config partition after 5 attempts${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "1. Check partition table: fdisk -l $USB_DEVICE"
    echo "2. Verify filesystem: fsck.vfat $CONFIG_PARTITION"
    echo "3. Try manual mount: mount $CONFIG_PARTITION /mnt"
    exit 1
fi

echo -e "${GREEN}Mounted successfully${NC}"

# Create config directory on USB
echo -e "${YELLOW}Creating configuration directory...${NC}"
CONFIG_USB_DIR="$MOUNT_POINT/archinstall"
mkdir -p "$CONFIG_USB_DIR"

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
for file in "$CONFIG_DIR"/*; do
    if [[ -f "$file" && "$(basename "$file")" != "debian_preseed.txt" ]]; then
        cp -v "$file" "$CONFIG_USB_DIR"/
    fi
done

# Make scripts executable
echo -e "${YELLOW}Setting permissions...${NC}"
chmod -v +x "$CONFIG_USB_DIR"/*.sh
if [[ -f "$CONFIG_USB_DIR/system-update.sh" ]]; then
    chmod -v +x "$CONFIG_USB_DIR/system-update.sh"
fi
if [[ -f "$CONFIG_USB_DIR/first-login-setup.sh" ]]; then
    chmod -v +x "$CONFIG_USB_DIR/first-login-setup.sh"
fi

# Verify files
echo ""
echo -e "${GREEN}Files on USB:${NC}"
ls -lh "$CONFIG_USB_DIR"

# Create a quick start guide
cat > "$CONFIG_USB_DIR/QUICKSTART.txt" << 'EOF'
ARCH LINUX AUTOMATED INSTALLER - QUICK START
==============================================

1. Boot from this USB drive
2. Once in the Arch live environment, run:

   mkdir -p /root/archconfig
   mount /dev/disk/by-label/CONFIGS /mnt
   cp /mnt/archinstall/* /root/archconfig/
   umount /mnt

   # IMPORTANT: Edit config to set encryption password
   nano /root/archconfig/archinstall-config.json
   # Search for "password": "" and add your password

   # Run installer
   archinstall --config /root/archconfig/archinstall-config.json

3. After installation and reboot:
   - Login as: kang
   - Password: changeme123 (you'll be forced to change it)

4. Complete post-installation:
   sudo bash /path/to/usb/archinstall/post-install.sh

5. Read README.md for full documentation

==============================================
EOF

# Sync and unmount
echo ""
echo -e "${YELLOW}Syncing data (please wait)...${NC}"
sync
sleep 2

echo -e "${YELLOW}Unmounting USB...${NC}"
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  USB Drive Preparation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Insert USB into target PC"
echo "2. Enable VT-x, VT-d, and IOMMU in BIOS"
echo "3. Boot from USB"
echo "4. Follow instructions in QUICKSTART.txt"
echo ""
echo -e "${YELLOW}IMPORTANT: You must edit the archinstall-config.json${NC}"
echo -e "${YELLOW}to set your LUKS encryption password before running!${NC}"
echo ""
