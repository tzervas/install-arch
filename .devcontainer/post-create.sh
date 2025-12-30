#!/bin/bash
set -euo pipefail

echo "Setting up development environment..."

# uv should already be installed from the base image
if ! command -v uv &> /dev/null; then
    echo "Error: uv not found in base image"
    exit 1
fi
echo "Using uv $(uv --version) for Python package management"

# Create uv-managed virtual environment and install dependencies
cd /workspaces/install-arch
echo "Creating Python virtual environment..."
uv venv .venv
source .venv/bin/activate

# Install the package in development mode
echo "Installing package in development mode..."
uv pip install -e .

# Install additional essential tools if needed (Debian packages)
echo "Installing additional development tools..."
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    parted \
    dosfstools \
    btrfs-progs \
    cryptsetup \
    lvm2 \
    openssh-client \
    rsync \
    || echo "Some packages may not be available, continuing..."

# Clean up
sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# Set up secure temporary directory structure
install-arch-dev temp-dir --prefix dev-setup-

echo "Development environment setup complete!"
echo "Activate the virtual environment with: source .venv/bin/activate"
echo "Use install-arch-dev command for development operations"
