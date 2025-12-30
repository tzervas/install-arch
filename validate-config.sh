#!/bin/bash
# Simple validation of install-arch configuration

echo "Validating install-arch configuration..."
echo

# Check LUKS passwords
if grep -q '"password": "testluks"' configs/archinstall-config.json; then
    echo "✓ LUKS password set to 'testluks'"
else
    echo "✗ LUKS password not configured"
    exit 1
fi

# Check user password
if grep -q '"password": "changeme123"' configs/archinstall-config.json; then
    echo "✓ User password set to 'changeme123'"
else
    echo "✗ User password not configured"
    exit 1
fi

echo
echo "✓ Configuration validation passed!"
echo "Ready for VM testing with dummy credentials:"
echo "  LUKS password: testluks"
echo "  User password: changeme123"