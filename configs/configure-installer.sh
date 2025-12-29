#!/bin/bash
# Interactive configuration script
# Sets up archinstall-config.json with user-provided passwords

CONFIG_FILE="archinstall-config.json"

echo "==========================================="
echo "  Arch Linux Installer Configuration"
echo "==========================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found in current directory"
    exit 1
fi

echo "This script will configure your installation settings."
echo ""

# Get LUKS encryption password
while true; do
    echo "Enter LUKS encryption password (for disk encryption):"
    read -s LUKS_PASS1
    echo ""
    echo "Confirm LUKS encryption password:"
    read -s LUKS_PASS2
    echo ""
    
    if [ "$LUKS_PASS1" != "$LUKS_PASS2" ]; then
        echo "Passwords do not match. Please try again."
        echo ""
    elif [ ${#LUKS_PASS1} -lt 8 ]; then
        echo "Password must be at least 8 characters. Please try again."
        echo ""
    else
        LUKS_PASSWORD="$LUKS_PASS1"
        break
    fi
done

echo "Password set successfully!"
echo ""

# Optional: Set timezone
echo "Enter your timezone (default: America/Los_Angeles):"
echo "Examples: America/New_York, Europe/London, Asia/Tokyo"
read -p "Timezone: " TIMEZONE
TIMEZONE=${TIMEZONE:-America/Los_Angeles}

# Optional: Hostname
read -p "Enter hostname (default: kang-virt-host): " HOSTNAME
HOSTNAME=${HOSTNAME:-kang-virt-host}

# Create backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Update the JSON file
# This uses jq if available, otherwise sed
if command -v jq &> /dev/null; then
    echo "Using jq to update configuration..."
    
    # Update using jq
    jq --arg pass "$LUKS_PASSWORD" \
       --arg tz "$TIMEZONE" \
       --arg host "$HOSTNAME" '
       .disk_config.device_modifications[0].partitions[1].btrfs_encryption.password = $pass |
       .disk_config.device_modifications[0].partitions[2].btrfs_encryption.password = $pass |
       .timezone = $tz |
       .hostname = $host
    ' "${CONFIG_FILE}.backup" > "$CONFIG_FILE"
    
else
    echo "jq not found, using sed (basic method)..."
    
    # Escape special characters in password for sed
    ESCAPED_PASS=$(echo "$LUKS_PASSWORD" | sed 's/[&/\]/\\&/g')
    
    # Update using sed
    sed -i "s/\"password\": \"\"/\"password\": \"$ESCAPED_PASS\"/g" "$CONFIG_FILE"
    sed -i "s/\"timezone\": \"America\/Los_Angeles\"/\"timezone\": \"$TIMEZONE\"/g" "$CONFIG_FILE"
    sed -i "s/\"hostname\": \"kang-virt-host\"/\"hostname\": \"$HOSTNAME\"/g" "$CONFIG_FILE"
fi

echo ""
echo "Configuration updated successfully!"
echo ""
echo "Settings:"
echo "  Hostname: $HOSTNAME"
echo "  Timezone: $TIMEZONE"
echo "  LUKS Password: [SET]"
echo ""
echo "Backup saved to: ${CONFIG_FILE}.backup"
echo ""
echo "You can now run the installer with:"
echo "  archinstall --config $CONFIG_FILE"
echo ""
