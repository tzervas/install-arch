#!/bin/bash
# Simple validation of install-arch configuration

echo "Validating install-arch configuration..."
echo

# Check LUKS passwords
if grep -q "\"password\": \"${INSTALL_ARCH_LUKS_PASSWORD:-testluks}\"" configs/archinstall-config.json; then
    echo "✓ LUKS password set to '${INSTALL_ARCH_LUKS_PASSWORD:-testluks}'"
else
    echo "✗ LUKS password not configured"
    exit 1
fi

# Check user password
if grep -q "\"password\": \"${INSTALL_ARCH_USER_PASSWORD:-changeme123}\"" configs/archinstall-config.json; then
    echo "✓ User password set to '${INSTALL_ARCH_USER_PASSWORD:-changeme123}'"
else
    echo "✗ User password not configured"
    exit 1
fi

echo
echo "✓ Configuration validation passed!"
echo "Ready for VM testing with dummy credentials:"
echo "  LUKS password: ${INSTALL_ARCH_LUKS_PASSWORD:-testluks}"
echo "  User password: ${INSTALL_ARCH_USER_PASSWORD:-changeme123}"