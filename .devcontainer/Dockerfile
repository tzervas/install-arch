# Build development environment from Debian 13 (Trixie) slim base
FROM debian:trixie-slim

# Build arguments for configuration
ARG MODE=mount
ARG BRANCH=main
ARG DEPTH=full
ARG VERSION=latest
ARG REPO_URL=https://github.com/tzervas/install-arch.git

# Set environment variables for runtime
ENV MODE=$MODE
ENV BRANCH=$BRANCH
ENV DEPTH=$DEPTH
ENV VERSION=$VERSION
ENV REPO_URL=$REPO_URL

# Install system requirements and essential tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    rustc \
    cargo \
    git \
    build-essential \
    sudo \
    bash \
    qemu-system-x86 \
    ovmf \
    libvirt-daemon-system \
    virt-manager \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install uv for Python package management
RUN pip3 install --break-system-packages uv

# Create vscode user
RUN useradd -m -s /bin/bash -u 1000 vscode && \
    echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/vscode && \
    chown -R vscode:vscode /home/vscode

# Create workspace directory
RUN mkdir -p /workspaces/install-arch && \
    chown vscode:vscode /workspaces/install-arch

# Clean up to minimize image size
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apt/archives/* && \
    find /usr/share -type f \( -name "*.gz" -o -name "*.txt" \) -delete 2>/dev/null || true && \
    find /usr/share -type d -empty -delete 2>/dev/null || true

WORKDIR /workspaces/install-arch
USER vscode

# Set minimal environment
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    LANG=C.UTF-8
