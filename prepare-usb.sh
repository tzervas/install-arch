#!/bin/bash
# USB Preparation Script for Arch Linux Automated Installer

set -e

# Configuration
ISO_DIR="/home/spooky/Documents/projects/install-arch/iso"
ISO_NAME="archlinux-2025.12.01-x86_64.iso"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"
ISO_URL="https://mirror.rackspace.com/archlinux/iso/2025.12.01/${ISO_NAME}"
CONFIG_DIR="/home/spooky/Documents/projects/install-arch/configs"
USB_DEVICE="/dev/sdb"
USB_PARTITION="${USB_DEVICE}1"

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
read -p "Are you absolutely sure? Type 'YES' to continue: " confirm

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

# Write ISO to USB
echo -e "${YELLOW}Writing ISO to USB (this will take 5-10 minutes)...${NC}"
dd if="$ISO_PATH" of="$USB_DEVICE" bs=4M status=progress oflag=sync conv=fsync

# Wait for kernel to recognize the new partition table
echo ""
echo -e "${YELLOW}Syncing and waiting for device...${NC}"
sync
sleep 3
partprobe "$USB_DEVICE" 2>/dev/null || true
sleep 2

# Find the partition label (Arch ISO creates multiple partitions)
echo -e "${YELLOW}Detecting ISO partitions...${NC}"
ARCH_PARTITION=$(lsblk -no PATH,LABEL "$USB_DEVICE" | grep -i "ARCH" | head -n1 | awk '{print $1}')

if [ -z "$ARCH_PARTITION" ]; then
    echo -e "${YELLOW}Could not find ARCH partition, trying first partition...${NC}"
    ARCH_PARTITION="${USB_DEVICE}1"
fi

echo -e "${GREEN}Using partition: $ARCH_PARTITION${NC}"

# Mount the USB
echo -e "${YELLOW}Mounting USB...${NC}"
MOUNT_POINT=$(mktemp -d)
sleep 2

# Try mounting
for i in {1..3}; do
    if mount "$ARCH_PARTITION" "$MOUNT_POINT" 2>/dev/null; then
        echo -e "${GREEN}Mounted successfully${NC}"
        break
    fi
    echo -e "${YELLOW}Mount attempt $i failed, retrying...${NC}"
    sleep 2
done

if ! mountpoint -q "$MOUNT_POINT"; then
    echo -e "${RED}Error: Failed to mount USB${NC}"
    rmdir "$MOUNT_POINT"
    exit 1
fi

# Create config directory on USB
echo -e "${YELLOW}Creating configuration directory...${NC}"
CONFIG_USB_DIR="$MOUNT_POINT/archinstall"
mkdir -p "$CONFIG_USB_DIR"

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
cp -v "$CONFIG_DIR/archinstall-config.json" "$CONFIG_USB_DIR/"
cp -v "$CONFIG_DIR/system-update" "$CONFIG_USB_DIR/"
cp -v "$CONFIG_DIR/force-password-change.sh" "$CONFIG_USB_DIR/"
cp -v "$CONFIG_DIR/first-login-setup" "$CONFIG_USB_DIR/"
cp -v "$CONFIG_DIR/post-install.sh" "$CONFIG_USB_DIR/"
cp -v "$CONFIG_DIR/README.md" "$CONFIG_USB_DIR/"

# Make scripts executable
echo -e "${YELLOW}Setting permissions...${NC}"
chmod -v +x "$CONFIG_USB_DIR"/*.sh
chmod -v +x "$CONFIG_USB_DIR/system-update"
chmod -v +x "$CONFIG_USB_DIR/first-login-setup"

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
   mount /dev/disk/by-label/ARCH_* /mnt
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
