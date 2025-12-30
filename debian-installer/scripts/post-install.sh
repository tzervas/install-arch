#!/bin/bash
# Debian 13 Post-Installation Script
# Run this after Debian installation to complete the setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[POST-INSTALL]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
    echo "Usage: sudo $0"
    exit 1
fi

log "Starting Debian 13 post-installation setup..."

# Update package list
log "Updating package lists..."
apt update

# Upgrade system
log "Upgrading system packages..."
apt upgrade -y

# Install additional packages
log "Installing additional packages..."
apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tmux \
    openssh-server \
    sudo \
    ufw \
    fail2ban \
    apparmor \
    apparmor-profiles \
    docker.io \
    docker-compose \
    qemu-kvm \
    libvirt-daemon-system \
    virt-manager \
    bridge-utils \
    dnsmasq \
    iptables \
    btrfs-progs \
    snapper \
    linux-headers-amd64 \
    firmware-linux \
    firmware-misc-nonfree

# Configure UFW firewall
log "Configuring UFW firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp

# Configure fail2ban
log "Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Configure Docker
log "Configuring Docker..."
systemctl enable docker
systemctl start docker

# Add user to docker group
log "Adding user to docker group..."
usermod -aG docker debian

# Configure libvirt
log "Configuring libvirt..."
systemctl enable libvirtd
systemctl start libvirtd
usermod -aG kvm,libvirt debian

# Configure BTRFS snapshots
log "Configuring BTRFS snapshots..."
snapper --no-dbus -c root create-config /

# Configure GRUB for BTRFS
log "Configuring GRUB for BTRFS..."
apt install -y grub-btrfs
systemctl enable grub-btrfsd

# Install KDE desktop if selected
if [[ "${INSTALL_DEBIAN_DESKTOP_ENVIRONMENT:-kde}" == "kde" ]]; then
    log "Installing KDE Plasma desktop..."
    apt install -y \
        kde-standard \
        kde-plasma-desktop \
        sddm \
        firefox-esr \
        chromium \
        vlc \
        gimp \
        libreoffice \
        thunderbird \
        keepassxc \
        synaptic \
        gparted
fi

# Configure SSH
log "Configuring SSH..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

# Set up automatic security updates
log "Configuring automatic security updates..."
apt install -y unattended-upgrades apt-listchanges
dpkg-reconfigure -f noninteractive unattended-upgrades

# Clean up
log "Cleaning up..."
apt autoremove -y
apt autoclean

# Force password change on first login
log "Setting up forced password change..."
chage -d 0 debian

# Create post-install completion marker
touch /root/.debian-postinstall-complete

log "Post-installation setup completed successfully!"
warning "IMPORTANT: Change the default password immediately!"
warning "Run: passwd debian"
echo ""
info "System will reboot in 10 seconds..."
info "Press Ctrl+C to cancel reboot"

sleep 10
reboot