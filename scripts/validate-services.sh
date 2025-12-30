#!/bin/bash
# validate-services.sh
# Check systemd service status and configuration

set -e

echo "=== Validating System Services ==="

# Services that should be enabled
ENABLED_SERVICES=(
    "sddm.service"
    "NetworkManager.service"
    "libvirtd.service"
    "docker.service"
    "sshd.service"
    "bluetooth.service"
    "cups.service"
    "cronie.service"
)

echo "Checking enabled services..."
for service in "${ENABLED_SERVICES[@]}"; do
    if ! systemctl is-enabled "$service" >/dev/null 2>&1; then
        echo "ERROR: Service $service not enabled"
        exit 1
    fi
    echo "✓ $service enabled"
done

echo "Checking service status..."
for service in "${ENABLED_SERVICES[@]}"; do
    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        echo "WARNING: Service $service not active (may start on next boot)"
    else
        echo "✓ $service active"
    fi
done

echo "✓ Service validation complete"