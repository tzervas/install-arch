#!/bin/bash
# Install Arch Configuration Loader
# This script loads configuration from config.toml and local-config.toml
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
load_config "$PROJECT_ROOT/config.toml" "INSTALL_ARCH_"

# Load local configuration (overrides main config)
load_config "$PROJECT_ROOT/local-config.toml" "INSTALL_ARCH_"

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
export INSTALL_ARCH_ISO_DIR="${INSTALL_ARCH_ISO_DIR:-$PROJECT_ROOT/iso}"
export INSTALL_ARCH_CONFIG_DIR="${INSTALL_ARCH_CONFIG_DIR:-$PROJECT_ROOT/configs}"
export INSTALL_ARCH_USB_DEVICE="${INSTALL_ARCH_USB_DEVICE:-/dev/sdb}"

# Derived paths with version substitution
VENTOY_VERSION="${INSTALL_ARCH_VERSIONS_VENTOY_VERSION:-1.0.99}"
ARCH_ISO_VERSION="${INSTALL_ARCH_VERSIONS_ARCH_ISO_VERSION:-2025.12.01}"

export INSTALL_ARCH_VENTOY_EXTRACT_DIR="${INSTALL_ARCH_PATHS_VENTOY_EXTRACT_DIR:-ventoy-$VENTOY_VERSION-linux}"
export INSTALL_ARCH_ISO_FILENAME="${INSTALL_ARCH_PATHS_ISO_FILENAME:-archlinux-$ARCH_ISO_VERSION-x86_64.iso}"
export INSTALL_ARCH_ISO_PATH="${INSTALL_ARCH_ISO_DIR}/${INSTALL_ARCH_ISO_FILENAME}"

# Construct URLs
export INSTALL_ARCH_VENTOY_URL="${INSTALL_ARCH_URLS_VENTOY_BASE_URL:-https://github.com/ventoy/Ventoy/releases/download}/v${VENTOY_VERSION}/${INSTALL_ARCH_VENTOY_EXTRACT_DIR}.tar.gz"

# Export for backward compatibility
export ISO_DIR="${INSTALL_ARCH_ISO_DIR}"
export ISO_NAME="${INSTALL_ARCH_ISO_FILENAME}"
export ISO_PATH="${INSTALL_ARCH_ISO_PATH}"
export CONFIG_DIR="${INSTALL_ARCH_CONFIG_DIR}"
export USB_DEVICE="${INSTALL_ARCH_USB_DEVICE}"

echo "Configuration loaded successfully"