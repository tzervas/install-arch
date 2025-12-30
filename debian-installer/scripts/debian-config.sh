#!/bin/bash
# Debian Installer Configuration Loader
# This script loads configuration from debian-config.toml and local-debian-config.toml
# and sets environment variables for use in other scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to load TOML configuration
load_config() {
    local config_file="$1"
    local prefix="${2:-}"

    if [[ ! -f "$config_file" ]]; then
        return
    fi

    # Simple TOML parsing using shell tools
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Clean up key and value - remove leading/trailing spaces
        key=$(echo "$key" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//" | sed 's/,$//')

        # Handle array values (remove brackets and quotes)
        if [[ $value =~ ^\[.*\]$ ]]; then
            value=$(echo "$value" | sed 's/^\[//' | sed 's/\]$//' | sed 's/"/ /g' | sed "s/'/ /g" | sed 's/,/ /g')
        fi

        if [[ -n "$key" && -n "$value" && ! "$key" =~ ^[[:space:]]*# ]]; then
            env_key="${prefix}$(echo "$key" | tr 'a-z.' 'A-Z_')"
            # Use eval to properly handle the export with spaces
            eval "export $env_key=\"$value\""
            echo "Loaded: $env_key=$value"
        fi
    done < <(grep -v '^#' "$config_file" | grep '=')
}

# Load main configuration
load_config "$PROJECT_ROOT/debian-installer/debian-config.toml" "INSTALL_DEBIAN_"

# Load local configuration (overrides main config)
load_config "$PROJECT_ROOT/debian-installer/local-debian-config.toml" "INSTALL_DEBIAN_"

# Load environment variables from .env file (highest priority)
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    echo "Loading environment variables from .env file..."
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Remove quotes from value if present
        value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")

        # Export the variable
        export "$key=$value"
        echo "Loaded from .env: $key=$value"
    done < <(grep -v '^#' "$PROJECT_ROOT/.env" | grep '=')
fi

# Set derived variables with fallbacks
export INSTALL_DEBIAN_ISO_DIR="${INSTALL_DEBIAN_ISO_DIR:-$PROJECT_ROOT/debian-installer/iso}"
export INSTALL_DEBIAN_CONFIG_DIR="${INSTALL_DEBIAN_CONFIG_DIR:-$PROJECT_ROOT/debian-installer/configs}"
export INSTALL_DEBIAN_USB_DEVICE="${INSTALL_DEBIAN_USB_DEVICE:-/dev/sdb}"

# Derived paths with version substitution
DEBIAN_VERSION="${INSTALL_DEBIAN_DEBIAN_VERSION:-13}"
DEBIAN_CODENAME="${INSTALL_DEBIAN_DEBIAN_CODENAME:-trixie}"

export INSTALL_DEBIAN_ISO_FILENAME="${INSTALL_DEBIAN_ISO_FILENAME:-debian-$DEBIAN_VERSION-amd64-netinst.iso}"
export INSTALL_DEBIAN_ISO_PATH="${INSTALL_DEBIAN_ISO_DIR}/${INSTALL_DEBIAN_ISO_FILENAME}"

# Construct URLs
export INSTALL_DEBIAN_ISO_URL="${INSTALL_DEBIAN_DEBIAN_CDIMAGE_URL:-https://deb.debian.org/debian-cdimage}/$DEBIAN_CODENAME/amd64/iso-cd/${INSTALL_DEBIAN_ISO_FILENAME}"

# Export for backward compatibility
export ISO_DIR="${INSTALL_DEBIAN_ISO_DIR}"
export ISO_NAME="${INSTALL_DEBIAN_ISO_FILENAME}"
export ISO_PATH="${INSTALL_DEBIAN_ISO_PATH}"
export CONFIG_DIR="${INSTALL_DEBIAN_CONFIG_DIR}"
export USB_DEVICE="${INSTALL_DEBIAN_USB_DEVICE}"

echo "Debian configuration loaded successfully"