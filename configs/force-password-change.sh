#!/bin/bash
# Force password change on first login

if [ "$(id -u)" -eq 0 ]; then
    # Don't apply to root
    return 0
fi

# Check if password needs to be changed
if passwd -S "$USER" 2>/dev/null | grep -q "Password must be changed"; then
    echo "=========================================="
    echo "  FIRST LOGIN - PASSWORD CHANGE REQUIRED"
    echo "=========================================="
    echo ""
    echo "For security reasons, you must change your password."
    echo ""
    
    # Force password change
    passwd
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "Password changed successfully!"
        echo "Please log out and log back in."
        echo ""
        sleep 2
        # Kill the session to force re-login
        pkill -KILL -u "$USER"
    fi
fi
