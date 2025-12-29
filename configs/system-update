#!/bin/bash
# System Update Script for Read-Only Root
# This script handles system updates by temporarily mounting root as read-write

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Arch Linux System Update Script ===${NC}"
echo -e "${YELLOW}This script will temporarily remount root as read-write for updates${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" 
   echo "Usage: sudo system-update"
   exit 1
fi

# Check if root is mounted read-only
if grep -qs ' / ' /proc/mounts && grep -qs 'ro,' /proc/mounts | grep -q ' / '; then
    ROOT_IS_RO=true
    echo -e "${GREEN}Root filesystem is currently read-only${NC}"
else
    ROOT_IS_RO=false
    echo -e "${YELLOW}Root filesystem is already read-write${NC}"
fi

# Function to cleanup on exit
cleanup() {
    if [ "$ROOT_IS_RO" = true ]; then
        echo ""
        echo -e "${YELLOW}Remounting root as read-only...${NC}"
        mount -o remount,ro /
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Root filesystem remounted as read-only${NC}"
        else
            echo -e "${RED}Failed to remount root as read-only!${NC}"
            echo -e "${RED}Please manually run: sudo mount -o remount,ro /${NC}"
        fi
    fi
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Remount root as read-write if needed
if [ "$ROOT_IS_RO" = true ]; then
    echo -e "${YELLOW}Remounting root as read-write...${NC}"
    mount -o remount,rw /
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to remount root as read-write${NC}"
        exit 1
    fi
    echo -e "${GREEN}Root filesystem is now read-write${NC}"
    echo ""
fi

# Update the system
echo -e "${GREEN}Starting system update...${NC}"
echo ""

# Sync package databases
pacman -Sy

# Perform the update
echo ""
echo -e "${YELLOW}Running pacman -Su (system upgrade)${NC}"
pacman -Su

# Clean package cache (optional)
echo ""
read -p "Clean package cache? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    paccache -rk 2
fi

echo ""
echo -e "${GREEN}System update complete!${NC}"

# Cleanup will be called automatically via trap
