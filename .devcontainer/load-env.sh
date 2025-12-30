#!/bin/bash
# Load devcontainer environment variables from .env file
# This script is run during devcontainer initialization

set -euo pipefail

ENV_FILE=".devcontainer/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Warning: $ENV_FILE not found. Using default values."
    exit 0
fi

# Load environment variables from .env file
# Only export variables that start with DEVCONTAINER_
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    # Remove quotes from value if present
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")

    # Only export DEVCONTAINER_ prefixed variables to avoid conflicts
    if [[ $key == DEVCONTAINER_* ]]; then
        export "$key=$value"
        echo "Loaded: $key=$value"
    fi
done < "$ENV_FILE"

echo "Devcontainer environment variables loaded successfully"