#!/bin/bash
# USB Preparation Script for Arch Linux Automated Installer

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Cleanup function
cleanup() {
    local exit_code=$?
    echo -e "${YELLOW}Cleaning up...${NC}"
    # Unmount Ventoy mount if mounted
    if [ -d "${VENTOY_MOUNT:-}" ] && mountpoint -q "${VENTOY_MOUNT:-}"; then
        umount "${VENTOY_MOUNT:-}" || true
        rmdir "${VENTOY_MOUNT:-}" || true
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

# Configuration (loaded from config.sh)
ISO_DIR="${INSTALL_ARCH_ISO_DIR}"
ISO_NAME="${INSTALL_ARCH_ISO_FILENAME}"
ISO_PATH="${INSTALL_ARCH_ISO_PATH}"
CONFIG_DIR="${INSTALL_ARCH_CONFIG_DIR}"
USB_DEVICE="${INSTALL_ARCH_USB_DEVICE}"

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

# Download Ventoy if needed
VENTOY_VERSION="${INSTALL_ARCH_VERSIONS_VENTOY_VERSION}"
VENTOY_TAR="${INSTALL_ARCH_VENTOY_EXTRACT_DIR}.tar.gz"
VENTOY_URL="${INSTALL_ARCH_VENTOY_URL}"
VENTOY_DIR="${INSTALL_ARCH_VENTOY_EXTRACT_DIR}"

if [ ! -d "$VENTOY_DIR" ]; then
    echo -e "${YELLOW}Downloading Ventoy...${NC}"
    if command -v wget >/dev/null 2>&1; then
        wget "$VENTOY_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$VENTOY_TAR" "$VENTOY_URL"
    else
        echo -e "${RED}Error: Neither wget nor curl found. Please install one to download Ventoy.${NC}"
        exit 1
    fi

    if [ ! -f "$VENTOY_TAR" ]; then
        echo -e "${RED}Error: Failed to download Ventoy${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Extracting Ventoy...${NC}"
    tar -xzf "$VENTOY_TAR"
    echo -e "${GREEN}Ventoy downloaded and extracted${NC}"
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
    local mirrors=($INSTALL_ARCH_URLS_ARCH_MIRRORS)
    # Append version to each mirror
    local version_mirrors=()
    for mirror in "${mirrors[@]}"; do
        version_mirrors+=("${mirror}/${INSTALL_ARCH_VERSIONS_ARCH_ISO_VERSION}")
    done

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

# Install Ventoy on USB
echo -e "${YELLOW}Installing Ventoy on USB...${NC}"
cd "$VENTOY_DIR"
if ! ./Ventoy2Disk.sh -i "$USB_DEVICE"; then
    echo -e "${RED}Error: Failed to install Ventoy${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}Ventoy installed successfully${NC}"

# Wait for partitions to be recognized
echo -e "${YELLOW}Syncing and waiting for partitions...${NC}"
sync
sleep 3
partprobe "$USB_DEVICE" 2>/dev/null || true
sleep 2

# Mount Ventoy data partition (usually the larger one)
VENTOY_PARTITION="${USB_DEVICE}1"
echo -e "${GREEN}Using Ventoy data partition: $VENTOY_PARTITION${NC}"

echo -e "${YELLOW}Mounting Ventoy partition...${NC}"
VENTOY_MOUNT=$(mktemp -d)
sleep 2

# Try mounting with retries
for i in {1..5}; do
    if mount "$VENTOY_PARTITION" "$VENTOY_MOUNT" 2>/dev/null; then
        echo -e "${GREEN}Mounted successfully on attempt $i${NC}"
        break
    fi
    echo -e "${YELLOW}Mount attempt $i failed, retrying...${NC}"
    sleep 2
    partprobe "$USB_DEVICE" 2>/dev/null || true
    sleep 1
done

if ! mountpoint -q "$VENTOY_MOUNT"; then
    echo -e "${RED}Error: Failed to mount Ventoy partition after 5 attempts${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "1. Check partition table: fdisk -l $USB_DEVICE"
    echo "2. Verify filesystem: fsck.exfat $VENTOY_PARTITION"
    echo "3. Try manual mount: mount $VENTOY_PARTITION /mnt"
    exit 1
fi

echo -e "${GREEN}Mounted successfully${NC}"

# Copy ISO to Ventoy partition
echo -e "${YELLOW}Copying ISO to Ventoy partition...${NC}"
if ! cp "$ISO_PATH" "$VENTOY_MOUNT/"; then
    echo -e "${RED}Error: Failed to copy ISO${NC}"
    umount "$VENTOY_MOUNT" || true
    rmdir "$VENTOY_MOUNT"
    exit 1
fi

# Create config directory on USB
echo -e "${YELLOW}Creating configuration directory...${NC}"
CONFIG_USB_DIR="$VENTOY_MOUNT/configs"
mkdir -p "$CONFIG_USB_DIR"

# Copy configuration files
echo -e "${YELLOW}Copying configuration files...${NC}"
for file in "$CONFIG_DIR"/*; do
    if [[ -f "$file" && "$(basename "$file")" != "debian_preseed.txt" ]]; then
        cp -v "$file" "$CONFIG_USB_DIR"/
    fi
done

# Copy local config if exists
if [ -f "local-config.toml" ]; then
    cp -v "local-config.toml" "$CONFIG_USB_DIR"/
fi

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

1. Boot from this USB drive (Ventoy menu will appear)
2. Select the Arch Linux ISO
3. Once in the Arch live environment, run:

   mkdir -p /root/archconfig
   mount /dev/sdb1 /mnt  # Mount the Ventoy data partition
   cp /mnt/configs/* /root/archconfig/
   umount /mnt

   # IMPORTANT: Edit config to set encryption password
   nano /root/archconfig/archinstall-config.json
   # Search for "password": "" and add your password

   # Run installer
   archinstall --config /root/archconfig/archinstall-config.json

4. After installation and reboot:
   - Login as: kang
   - Password: changeme123 (you'll be forced to change it)

5. Complete post-installation:
   sudo bash /path/to/configs/post-install.sh

6. Read configs/README.md for full documentation

==============================================
EOF

# Sync and unmount
echo ""
echo -e "${YELLOW}Syncing data (please wait)...${NC}"
sync
sleep 2

echo -e "${YELLOW}Unmounting USB...${NC}"
umount "$VENTOY_MOUNT"
rmdir "$VENTOY_MOUNT"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  USB Drive Preparation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Insert USB into target PC"
echo "2. Enable VT-x, VT-d, and IOMMU in BIOS"
echo "3. Boot from USB (Ventoy menu will appear)"
echo "4. Select the Arch Linux ISO"
echo "5. Follow instructions in configs/QUICKSTART.txt"
echo ""
echo -e "${YELLOW}IMPORTANT: You must edit the archinstall-config.json${NC}"
echo -e "${YELLOW}to set your LUKS encryption password before running!${NC}"
echo ""
