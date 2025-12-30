#!/bin/bash
# validate-package-installation.sh
# Run during installation to verify package installation success

set -e

echo "=== Validating Package Installation ==="

# Core KDE packages
KDE_PACKAGES=(
    "plasma-desktop"
    "kde-applications-meta"
    "sddm"
    "konsole"
    "dolphin"
    "kdeconnect"
)

# System packages
SYSTEM_PACKAGES=(
    "networkmanager"
    "bluez"
    "cups"
    "docker"
    "libvirt"
    "qemu-full"
    "nvidia-dkms"
    "ufw"
    "openssh"
)

echo "Checking KDE packages..."
for pkg in "${KDE_PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "ERROR: Package $pkg not installed"
        exit 1
    fi
    echo "✓ $pkg installed"
done

echo "Checking system packages..."
for pkg in "${SYSTEM_PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "ERROR: Package $pkg not installed"
        exit 1
    fi
    echo "✓ $pkg installed"
done

echo "✓ All packages installed successfully"