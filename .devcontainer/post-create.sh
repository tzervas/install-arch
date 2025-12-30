#!/bin/bash
set -euo pipefail

echo "Setting up development environment..."

# Handle repository setup based on mode
if [ "$MODE" = "clone" ]; then
    echo "Cloning repository in clone mode..."
    if [ "$DEPTH" = "shallow" ]; then
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" /workspaces/install-arch
    else
        git clone --branch "$BRANCH" "$REPO_URL" /workspaces/install-arch
    fi
    cd /workspaces/install-arch
elif [ "$MODE" = "user" ]; then
    echo "Setting up for user mode with version $VERSION..."
    mkdir -p /workspaces/install-arch
    cd /workspaces/install-arch
else
    echo "Using mounted workspace..."
    cd /workspaces/install-arch
fi

# uv should already be installed from the base image
if ! command -v uv &> /dev/null; then
    echo "Error: uv not found in base image"
    exit 1
fi
echo "Using uv $(uv --version) for Python package management"

# Install based on version
if [ "$VERSION" = "latest" ] && [ "$MODE" != "user" ]; then
    # Development mode
    echo "Creating Python virtual environment..."
    uv venv .venv
    source .venv/bin/activate
    echo "Installing package in development mode..."
    uv pip install -e .
else
    # Install released version
    echo "Installing install-arch version $VERSION..."
    uv pip install install-arch${VERSION:+==$VERSION}
fi

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
