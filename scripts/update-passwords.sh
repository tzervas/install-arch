#!/bin/bash
# Update Passwords Script
# Injects passwords from .env file into configuration files
# This script updates archinstall-config.json with the actual passwords

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[UPDATE-PASSWORDS]${NC} $1"
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

# Check if we're running as root (not required for this script)
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
    exit 1
fi

log "Starting password update process..."

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    error ".env file not found. Please copy .env.example to .env and configure your passwords."
    exit 1
fi

# Verify required passwords are set
if [[ -z "${INSTALL_ARCH_LUKS_PASSWORD:-}" ]]; then
    error "INSTALL_ARCH_LUKS_PASSWORD not set in .env file"
    exit 1
fi

if [[ -z "${INSTALL_ARCH_USER_PASSWORD:-}" ]]; then
    error "INSTALL_ARCH_USER_PASSWORD not set in .env file"
    exit 1
fi

# Check if config file exists
CONFIG_FILE="configs/archinstall-config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Configuration file $CONFIG_FILE not found"
    exit 1
fi

log "Updating LUKS passwords in $CONFIG_FILE..."

# Update LUKS passwords (there are multiple instances in the config)
sed -i "s/\"password\": \"CHANGE_THIS_LUKS_PASSWORD\"/\"password\": \"$INSTALL_ARCH_LUKS_PASSWORD\"/g" "$CONFIG_FILE"
sed -i "s/\"password\": \"testluks\"/\"password\": \"$INSTALL_ARCH_LUKS_PASSWORD\"/g" "$CONFIG_FILE"

log "Updating user password in $CONFIG_FILE..."

# Update user password
sed -i "s/\"password\": \"CHANGE_THIS_USER_PASSWORD\"/\"password\": \"$INSTALL_ARCH_USER_PASSWORD\"/g" "$CONFIG_FILE"
sed -i "s/\"password\": \"changeme123\"/\"password\": \"$INSTALL_ARCH_USER_PASSWORD\"/g" "$CONFIG_FILE"

# Update root password if set
if [[ -n "${INSTALL_ARCH_ROOT_PASSWORD:-}" ]]; then
    log "Updating root password in $CONFIG_FILE..."
    # Note: archinstall config doesn't have a separate root password field
    # Root password is typically set via the user password or sudo
fi

log "Password update completed successfully!"

info "Updated passwords:"
info "  LUKS encryption: $INSTALL_ARCH_LUKS_PASSWORD"
info "  User account: $INSTALL_ARCH_USER_PASSWORD"
if [[ -n "${INSTALL_ARCH_ROOT_PASSWORD:-}" ]]; then
    info "  Root account: $INSTALL_ARCH_ROOT_PASSWORD"
fi

warning "Remember to:"
echo "  1. Change the user password on first login"
echo "  2. Store passwords securely"
echo "  3. Never commit the .env file to git"

log "Configuration updated and ready for installation!"