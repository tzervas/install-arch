#!/bin/bash
# validate-security.sh
# Validate security configurations
# 
# Usage: validate-security.sh [username]
#   If username is not provided, uses $SUDO_USER or current user

set -e

# Determine username to validate
# Priority: command-line arg > SUDO_USER env var > current user
USERNAME="${1:-${SUDO_USER:-$(whoami)}}"

echo "=== Validating Security Configuration ==="
echo "Validating for user: $USERNAME"

# Check firewall status
echo "Checking UFW firewall..."
if ! systemctl is-active ufw >/dev/null 2>&1; then
    echo "ERROR: UFW firewall not active"
    exit 1
fi

ufw_status=$(ufw status | grep -c "Status: active")
if [ "$ufw_status" -eq 0 ]; then
    echo "ERROR: UFW firewall not active"
    exit 1
fi
echo "✓ UFW firewall active"

# Check SSH hardening
echo "Checking SSH configuration..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "ERROR: SSH config file not found"
    exit 1
fi

# Check for security settings
ssh_checks=(
    "PermitRootLogin no"
    "PasswordAuthentication yes"
    "X11Forwarding no"
)

for check in "${ssh_checks[@]}"; do
    if ! grep -q "^$check" "$SSH_CONFIG"; then
        echo "WARNING: SSH setting '$check' not configured"
    else
        echo "✓ SSH: $check"
    fi
done

# Check password policies
echo "Checking password policies..."
if ! passwd -S "$USERNAME" | grep -q "Password must be changed"; then
    echo "WARNING: Password change not enforced for user $USERNAME"
else
    echo "✓ Password change enforced for user $USERNAME"
fi

# Check sudo configuration
echo "Checking sudo configuration..."
if ! sudo -l | grep -q "(ALL : ALL) ALL"; then
    echo "ERROR: User not in sudo group or sudo not configured"
    exit 1
fi
echo "✓ Sudo access configured"

# Check read-only root
echo "Checking read-only root configuration..."
root_mount=$(mount | grep "on / " | grep -o "ro," || true)
if [ -z "$root_mount" ]; then
    echo "WARNING: Root filesystem not mounted read-only"
else
    echo "✓ Root filesystem mounted read-only"
fi

echo "✓ Security validation complete"