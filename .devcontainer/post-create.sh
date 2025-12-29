#!/bin/bash
set -euo pipefail

echo "Setting up development environment..."

# Install uv for fast Python package management
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

# Create uv-managed virtual environment and install dependencies
cd /workspaces/install-arch
uv venv .venv
source .venv/bin/activate

# Install the package in development mode
uv pip install -e .

# Install additional tools for Arch Linux development
apt-get update && apt-get install -y \
    qemu-system-x86 \
    ovmf \
    parted \
    dosfstools \
    btrfs-progs \
    cryptsetup \
    lvm2 \
    openssh-client \
    rsync

# Set up secure temporary directory structure
install-arch-dev temp-dir --prefix dev-setup-

echo "Development environment setup complete!"
echo "Activate the virtual environment with: source .venv/bin/activate"
echo "Use install-arch-dev command for development operations"