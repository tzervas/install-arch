#!/bin/bash
# Test VM for install-arch USB installer

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