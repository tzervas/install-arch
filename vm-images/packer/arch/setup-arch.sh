#!/bin/bash
set -euo pipefail

# Arch Linux VM Setup Script
# Configures the system for development and testing

echo "Setting up Arch Linux VM..."

# Set timezone
timedatectl set-timezone UTC

# Configure pacman
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf

# Update system
pacman -Syu --noconfirm

# Install base packages
pacman -S --noconfirm \
    base-devel \
    git \
    vim \
    htop \
    curl \
    wget \
    sudo \
    openssh \
    networkmanager \
    btrfs-progs \
    cryptsetup \
    lvm2

# Configure sudo
echo 'packer ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Configure SSH
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl enable sshd

# Configure NetworkManager
systemctl enable NetworkManager

# Install desktop environment based on variable
if [ "${DESKTOP_ENV:-kde}" = "kde" ]; then
    pacman -S --noconfirm \
        plasma \
        kde-applications \
        sddm \
        xorg
    systemctl enable sddm
elif [ "${DESKTOP_ENV:-kde}" = "gnome" ]; then
    pacman -S --noconfirm \
        gnome \
        gdm \
        xorg
    systemctl enable gdm
elif [ "${DESKTOP_ENV:-kde}" = "xfce" ]; then
    pacman -S --noconfirm \
        xfce4 \
        lightdm \
        lightdm-gtk-greeter \
        xorg
    systemctl enable lightdm
elif [ "${DESKTOP_ENV:-kde}" = "i3" ]; then
    pacman -S --noconfirm \
        i3 \
        lightdm \
        lightdm-gtk-greeter \
        xorg \
        dmenu \
        rxvt-unicode
    systemctl enable lightdm
fi

# Configure access method
if [ "${ACCESS_METHOD:-spice}" = "spice" ]; then
    pacman -S --noconfirm spice-vdagent
elif [ "${ACCESS_METHOD:-spice}" = "ssh" ]; then
    # SSH already configured
    echo "SSH access configured"
fi

# Security hardening
# Configure firewall
pacman -S --noconfirm ufw
ufw enable
ufw allow ssh

# Set up read-only root (simplified for VM)
# In production, this would be more complex

# Clean up
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*

echo "Arch Linux VM setup complete!"</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/packer/arch/scripts/setup-arch.sh