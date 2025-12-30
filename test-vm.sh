#!/bin/bash
# Test VM for install-arch USB installer
# SAFETY: This script includes checks to prevent accidental use on production systems

set -euo pipefail

# Function to detect if running in a VM environment
detect_vm_environment() {
    local is_vm=false
    local vm_type=""
    
    # Check systemd-detect-virt if available
    if command -v systemd-detect-virt &> /dev/null; then
        local virt_output
        virt_output=$(systemd-detect-virt 2>/dev/null || echo "none")
        if [[ "$virt_output" != "none" ]]; then
            is_vm=true
            vm_type="$virt_output"
        fi
    fi
    
    # Check /sys/class/dmi/id/product_name for VM indicators
    if [[ -r /sys/class/dmi/id/product_name ]]; then
        local product_name
        product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
        if [[ "$product_name" =~ (QEMU|KVM|VirtualBox|VMware|Xen) ]]; then
            is_vm=true
            vm_type="${vm_type:+$vm_type/}${BASH_REMATCH[1]}"
        fi
    fi
    
    # Check for hypervisor CPU flag
    if grep -q "^flags.*hypervisor" /proc/cpuinfo 2>/dev/null; then
        is_vm=true
        vm_type="${vm_type:-hypervisor}"
    fi
    
    if [[ "$is_vm" == "true" ]]; then
        echo "VM:$vm_type"
        return 0
    else
        echo "BARE_METAL"
        return 1
    fi
}

# Function to validate this is a safe test environment
validate_safe_environment() {
    echo "=== VM Environment Safety Check ==="
    echo
    
    local env_check
    env_check=$(detect_vm_environment)
    
    if [[ "$env_check" == "BARE_METAL" ]]; then
        echo "⚠️  WARNING: This script is designed to run in a VM environment only!"
        echo "⚠️  Detection indicates you are running on BARE METAL hardware."
        echo
        echo "This script will pass a physical USB device directly to QEMU."
        echo "Running this on a production system could lead to:"
        echo "  - Data loss on the USB device"
        echo "  - System instability"
        echo "  - Unintended hardware access"
        echo
        echo "If you are certain this is a test system and want to proceed,"
        echo "you must explicitly confirm by setting the environment variable:"
        echo "  export INSTALL_ARCH_ALLOW_BARE_METAL=1"
        echo
        
        if [[ "${INSTALL_ARCH_ALLOW_BARE_METAL:-0}" != "1" ]]; then
            echo "❌ Aborting for safety. Set INSTALL_ARCH_ALLOW_BARE_METAL=1 to override."
            exit 1
        else
            echo "⚠️  Override enabled. Proceeding with EXTREME CAUTION."
            echo
        fi
    else
        echo "✓ VM environment detected: ${env_check#VM:}"
        echo "✓ Safe to proceed with USB device passthrough"
        echo
    fi
}

USB_DEVICE="${1:-}"

if [[ -z "$USB_DEVICE" ]]; then
    echo "Usage: $0 <usb_device>"
    echo "Example: $0 /dev/sdb"
    echo
    echo "Available USB devices:"
    lsblk -d -o NAME,SIZE,MODEL | grep sd || true
    exit 1
fi

if [[ ! -b "$USB_DEVICE" ]]; then
    echo "Error: USB device $USB_DEVICE not found"
    exit 1
fi

# Validate we're in a safe VM environment before proceeding
validate_safe_environment

echo "Testing install-arch USB installer in VM"
echo "========================================"
echo
echo "USB Device: $USB_DEVICE"
echo "VM Memory: 4096MB"
echo "VM CPUs: 2"
echo "Virtual NVMe: 20GB"
echo
echo "Expected behavior:"
echo "1. VM boots from USB (Ventoy bootloader)"
echo "2. Automatically loads Arch Linux ISO"
echo "3. Boots to live environment"
echo "4. You need to run the auto-install script manually:"
echo
echo "   In the VM terminal, run:"
echo "   /mnt/configs/auto-install.sh"
echo
echo "   (The USB configs partition will be auto-mounted at /mnt)"
echo
echo "Test credentials:"
echo "  LUKS password: testluks"
echo "  User password: changeme123"
echo
echo "Starting VM... (Ctrl+A, X to exit QEMU)"
echo

# Create test disk if it doesn't exist
TEST_DISK="/tmp/install-arch-test-nvme.qcow2"
if [[ ! -f "$TEST_DISK" ]]; then
    echo "Creating virtual NVMe disk..."
    qemu-img create -f qcow2 "$TEST_DISK" 20G
fi

# Start VM
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -cpu host \
    -device usb-ehci,id=usb \
    -drive "file=$TEST_DISK,if=none,id=nvme0,format=qcow2" \
    -device "nvme,drive=nvme0,serial=testnvme" \
    -drive "file=$USB_DEVICE,if=none,id=usb0,format=raw" \
    -device "usb-storage,drive=usb0,bus=usb.0" \
    -boot order=d,menu=off \
    -vga std \
    -net nic,model=virtio \
    -net user \
    -serial stdio