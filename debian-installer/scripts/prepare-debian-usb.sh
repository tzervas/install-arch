#!/bin/bash
# Debian USB Preparation Script for Debian 13 Automated Installer

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/debian-config.sh"

# Cleanup function
cleanup() {
    local exit_code=$?
    echo -e "${YELLOW}Cleaning up...${NC}"
    # Unmount any mounted partitions
    if mountpoint -q /mnt/debian-iso 2>/dev/null; then
        umount /mnt/debian-iso || true
    fi
    if mountpoint -q /mnt/debian-usb 2>/dev/null; then
        umount /mnt/debian-usb || true
    fi
    rmdir /mnt/debian-iso /mnt/debian-usb 2>/dev/null || true
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

# Configuration (loaded from debian-config.sh)
ISO_DIR="${INSTALL_DEBIAN_ISO_DIR}"
ISO_NAME="${INSTALL_DEBIAN_ISO_FILENAME}"
ISO_PATH="${INSTALL_DEBIAN_ISO_PATH}"
ISO_URL="${INSTALL_DEBIAN_ISO_URL}"
CONFIG_DIR="${INSTALL_DEBIAN_CONFIG_DIR}"
USB_DEVICE="${INSTALL_DEBIAN_USB_DEVICE}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Debian 13 USB Installer Preparation${NC}"
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
    echo -e "${YELLOW}ISO file not found. Downloading from Debian mirror...${NC}"
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

# Verify ISO integrity (basic size check)
ISO_SIZE=$(stat -c%s "$ISO_PATH" 2>/dev/null || stat -f%z "$ISO_PATH" 2>/dev/null)
if [ "$ISO_SIZE" -lt 100000000 ]; then  # Less than 100MB
    echo -e "${RED}Error: ISO file seems too small ($ISO_SIZE bytes). Download may have failed.${NC}"
    exit 1
fi
echo -e "${GREEN}ISO size check passed: $ISO_SIZE bytes${NC}"

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

# Create hybrid ISO that can be written directly to USB
echo -e "${YELLOW}Preparing Debian ISO for USB boot...${NC}"

# Mount the ISO
mkdir -p /mnt/debian-iso
mount -o loop,ro "$ISO_PATH" /mnt/debian-iso

# Copy ISO contents to USB
echo -e "${YELLOW}Copying Debian ISO to USB...${NC}"
dd if="$ISO_PATH" of="$USB_DEVICE" bs=4M status=progress
sync

echo -e "${GREEN}ISO written to USB successfully${NC}"

# Mount the USB to add preseed config
echo -e "${YELLOW}Mounting USB to add preseed configuration...${NC}"
mkdir -p /mnt/debian-usb
mount "${USB_DEVICE}1" /mnt/debian-usb 2>/dev/null || mount "${USB_DEVICE}" /mnt/debian-usb

# Copy preseed configuration
echo -e "${YELLOW}Copying preseed configuration...${NC}"
cp "$CONFIG_DIR/debian-preseed.cfg" /mnt/debian-usb/preseed.cfg

# Create a simple boot menu entry for preseed
cat > /mnt/debian-usb/isolinux/preseed.cfg << 'EOF'
label install
    menu label ^Automated Install (Preseed)
    menu default
    kernel /install.amd/vmlinuz
    append vga=788 initrd=/install.amd/initrd.gz preseed/file=/cdrom/preseed.cfg locale=en_US.UTF-8 keymap=us hostname=debian domain=local ---
EOF

# Update the main menu to include preseed option
if [ -f /mnt/debian-usb/isolinux/menu.cfg ]; then
    sed -i 's/default install/default preseed/' /mnt/debian-usb/isolinux/menu.cfg
fi

# Sync and unmount
echo -e "${YELLOW}Syncing data (please wait)...${NC}"
sync
sleep 2

echo -e "${YELLOW}Unmounting USB...${NC}"
umount /mnt/debian-usb
umount /mnt/debian-iso
rmdir /mnt/debian-iso /mnt/debian-usb

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Debian USB Drive Preparation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Insert USB into target PC"
echo "2. Boot from USB (select 'Automated Install (Preseed)' from boot menu)"
echo "3. Debian will install automatically with your preseed configuration"
echo ""
echo -e "${YELLOW}IMPORTANT: The preseed file contains default passwords.${NC}"
echo -e "${YELLOW}Change them immediately after installation!${NC}"
echo ""

# Show preseed info
echo -e "${BLUE}Preseed Configuration:${NC}"
echo "  LUKS password: ${INSTALL_DEBIAN_LUKS_PASSWORD:-testluks}"
echo "  User password: ${INSTALL_DEBIAN_USER_PASSWORD:-changeme123}"
echo "  Hostname: ${INSTALL_DEBIAN_NETWORK_HOSTNAME:-debian-host}"