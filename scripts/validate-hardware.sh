#!/bin/bash
# validate-hardware.sh
# Test hardware detection and driver functionality

set -e

echo "=== Validating Hardware and Drivers ==="

# Check NVIDIA drivers
echo "Checking NVIDIA drivers..."
if ! nvidia-smi >/dev/null 2>&1; then
    echo "ERROR: NVIDIA drivers not functional"
    exit 1
fi

gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)
echo "✓ NVIDIA GPU detected: $gpu_info"

# Check Intel graphics
echo "Checking Intel graphics..."
if ! glxinfo | grep -q "Intel"; then
    echo "WARNING: Intel graphics not detected"
else
    echo "✓ Intel graphics detected"
fi

# Check Bluetooth
echo "Checking Bluetooth..."
if ! systemctl is-active bluetooth >/dev/null 2>&1; then
    echo "WARNING: Bluetooth service not active"
else
    echo "✓ Bluetooth service active"
fi

# Check network
echo "Checking network connectivity..."
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "ERROR: No internet connectivity"
    exit 1
fi
echo "✓ Internet connectivity confirmed"

# Check audio
echo "Checking audio system..."
if ! pactl info >/dev/null 2>&1; then
    echo "WARNING: PulseAudio not accessible"
else
    echo "✓ PulseAudio functional"
fi

# Check printing system
echo "Checking printing system..."
if ! systemctl is-active cups >/dev/null 2>&1; then
    echo "WARNING: CUPS printing service not active"
else
    echo "✓ CUPS printing service active"
fi

echo "✓ Hardware and driver validation complete"