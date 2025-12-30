#!/bin/bash
# Test script for Arch Linux VM images
# Validates boot, services, and basic functionality

set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_ROOT/scripts/config.sh"

IMAGE_PATH="$1"
VM_NAME="${2:-test-arch}"

echo "Testing VM image: $IMAGE_PATH"

# Start VM in background
qemu-system-x86_64 \
    -name "$VM_NAME" \
    -machine q35 \
    -cpu host \
    -enable-kvm \
    -m 2048 \
    -drive file="$IMAGE_PATH",format=qcow2,if=virtio \
    -net nic,model=virtio -net user \
    -nographic \
    -serial mon:stdio \
    -monitor telnet:${INSTALL_ARCH_VIRTUALIZATION_QEMU_HOST_IP}:${INSTALL_ARCH_VIRTUALIZATION_QEMU_MONITOR_PORT},server,nowait \
    -qmp tcp:${INSTALL_ARCH_VIRTUALIZATION_QEMU_HOST_IP}:${INSTALL_ARCH_VIRTUALIZATION_QEMU_QMP_PORT},server,nowait \
    > vm.log 2>&1 &
VM_PID=$!

echo "VM started with PID: $VM_PID"

# Wait for boot
sleep 30

# Check if VM is running
if kill -0 $VM_PID 2>/dev/null; then
    echo "✅ VM is running"
else
    echo "❌ VM failed to start"
    cat vm.log
    exit 1
fi

# Test SSH connection
echo "Testing SSH connection..."
for i in {1..10}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 packer@localhost -p 2222 "echo 'SSH working'"; then
        echo "✅ SSH connection successful"
        break
    fi
    sleep 5
done

# Test services
echo "Testing services..."
ssh -o StrictHostKeyChecking=no packer@localhost -p 2222 << 'EOF'
    # Check systemd
    systemctl is-system running && echo "✅ systemd running"

    # Check network
    ping -c 1 ${INSTALL_ARCH_NETWORK_DNS_TEST_IP} && echo "✅ network working"

    # Check packages
    pacman -Q | head -5 && echo "✅ pacman working"

    # Check desktop environment
    if command -v startplasma-x11 >/dev/null 2>&1; then
        echo "✅ KDE Plasma installed"
    fi
EOF

# Stop VM
echo "Stopping VM..."
echo "quit" | nc ${INSTALL_ARCH_VIRTUALIZATION_QEMU_HOST_IP} ${INSTALL_ARCH_VIRTUALIZATION_QEMU_QMP_PORT} || true
sleep 5
kill $VM_PID 2>/dev/null || true

echo "✅ VM testing complete"</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/test-vm.sh