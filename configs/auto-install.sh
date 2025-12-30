#!/bin/bash
# Auto-install script for Arch Linux
# Run this in the Arch live environment to start automated installation

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[AUTO-INSTALL]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if we're in Arch live environment
if [[ ! -f /usr/bin/archinstall ]]; then
    error "This script must be run in Arch Linux live environment"
    exit 1
fi

log "Starting automated Arch Linux installation..."
info "Test credentials configured:"
info "  LUKS password: testluks"
info "  User password: changeme123 (will be forced to change on first login)"

# Mount config partition (assuming it's the second partition on USB)
CONFIG_MOUNT="/tmp/archconfig"
mkdir -p "$CONFIG_MOUNT"

# Find the config partition (labeled CONFIGS)
CONFIG_PARTITION=""
for part in /dev/sd* /dev/nvme*n*p*; do
    if blkid "$part" 2>/dev/null | grep -q "CONFIGS"; then
        CONFIG_PARTITION="$part"
        break
    fi
done

if [[ -z "$CONFIG_PARTITION" ]]; then
    error "Could not find CONFIGS partition"
    error "Make sure the USB drive is inserted and partitioned correctly"
    exit 1
fi

log "Found config partition: $CONFIG_PARTITION"

# Mount config partition
if ! mount "$CONFIG_PARTITION" "$CONFIG_MOUNT"; then
    error "Failed to mount config partition"
    exit 1
fi

# Copy config files to working directory
WORK_DIR="/root/archinstall"
mkdir -p "$WORK_DIR"
cp -r "$CONFIG_MOUNT"/* "$WORK_DIR/"

log "Config files copied to $WORK_DIR"

# Change to working directory
cd "$WORK_DIR"

# Verify config file exists
if [[ ! -f "archinstall-config.json" ]]; then
    error "archinstall-config.json not found"
    exit 1
fi

log "Starting archinstall with automated configuration..."
warning "The installation will start automatically with the configured settings"
warning "LUKS encryption will be set up with password: testluks"
warning "User 'kang' will be created with password: changeme123"
echo
read -p "Press Enter to start installation or Ctrl+C to cancel..."

# Run archinstall
archinstall --config archinstall-config.json

log "Installation completed successfully!"
warning "System will reboot. Remove USB drive before boot."
warning "First login will require password change for security."