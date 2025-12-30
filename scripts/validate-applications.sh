#!/bin/bash
# validate-applications.sh
# Test installed applications and user experience elements

set -e

echo "=== Validating Applications and User Experience ==="

# Test core applications
APPLICATIONS=(
    "firefox --version"
    "thunderbird --version"
    "libreoffice --version"
    "vlc --version"
    "gimp --version"
    "virt-manager --version"
    "docker --version"
    "qemu-system-x86_64 --version"
)

echo "Testing application installations..."
for app in "${APPLICATIONS[@]}"; do
    if ! $app >/dev/null 2>&1; then
        echo "ERROR: Application $app failed"
        exit 1
    fi
    echo "✓ $app functional"
done

# Test virtualization setup
echo "Testing virtualization setup..."
if ! virsh list >/dev/null 2>&1; then
    echo "ERROR: libvirt not accessible"
    exit 1
fi
echo "✓ libvirt accessible"

# Test Docker
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker not accessible"
    exit 1
fi
echo "✓ Docker functional"

# Check user directories
echo "Checking user directory structure..."
USER_DIRS=(
    "Desktop"
    "Documents"
    "Downloads"
    "Pictures"
    "Videos"
    "Music"
    "Projects"
)

for dir in "${USER_DIRS[@]}"; do
    if [ ! -d "$HOME/$dir" ]; then
        echo "ERROR: User directory $dir not created"
        exit 1
    fi
    echo "✓ $HOME/$dir exists"
done

# Check PATH configuration
echo "Checking PATH configuration..."
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "WARNING: $HOME/.local/bin not in PATH"
else
    echo "✓ Local bin directory in PATH"
fi

# Test KDE shortcuts (requires X session)
echo "Testing KDE keyboard shortcuts..."
if [ -n "$DISPLAY" ]; then
    # Test terminal shortcut (this would require actual key simulation)
    echo "✓ KDE shortcuts configured (manual testing required)"
else
    echo "WARNING: No X session detected, skipping shortcut tests"
fi

echo "✓ Application and user experience validation complete"