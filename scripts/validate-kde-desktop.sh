#!/bin/bash
# validate-kde-desktop.sh
# Test KDE Plasma desktop environment functionality

set -e

echo "=== Validating KDE Plasma Desktop ==="

# Check if running in KDE
if [ -z "$XDG_CURRENT_DESKTOP" ] || [[ ! "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    echo "ERROR: Not running in KDE Plasma environment"
    echo "Current desktop: $XDG_CURRENT_DESKTOP"
    exit 1
fi

echo "✓ Running in KDE Plasma environment"

# Check KDE processes
KDE_PROCESSES=(
    "plasmashell"
    "kded5"
    "ksmserver"
    "kwin_x11"
)

echo "Checking KDE processes..."
for proc in "${KDE_PROCESSES[@]}"; do
    if ! pgrep -f "$proc" >/dev/null; then
        echo "ERROR: KDE process $proc not running"
        exit 1
    fi
    echo "✓ $proc running"
done

# Test KDE applications
echo "Testing KDE applications..."
kde_apps=(
    "konsole --version"
    "dolphin --version"
    "systemsettings --version"
)

for app in "${kde_apps[@]}"; do
    if ! $app >/dev/null 2>&1; then
        echo "ERROR: KDE application $app failed to run"
        exit 1
    fi
    echo "✓ $app functional"
done

# Check KDE configuration files
KDE_CONFIGS=(
    "$HOME/.config/kdeglobals"
    "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    "$HOME/.config/kglobalshortcutsrc"
)

echo "Checking KDE configuration files..."
for config in "${KDE_CONFIGS[@]}"; do
    if [ ! -f "$config" ]; then
        echo "WARNING: KDE config file $config not found"
    else
        echo "✓ $config exists"
    fi
done

echo "✓ KDE desktop validation complete"