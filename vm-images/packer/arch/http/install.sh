#!/bin/bash
set -euo pipefail

# Automated Arch Linux installation for Packer
# This runs during the initial boot

echo "Starting automated Arch installation..."

# Set up disk
DISK="/dev/vda"
BOOT_PART="${DISK}1"
ROOT_PART="${DISK}2"

# Partition disk
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary 513MiB 100%

# Format partitions
mkfs.fat -F32 $BOOT_PART
mkfs.btrfs $ROOT_PART

# Mount
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $BOOT_PART /mnt/boot

# Install base system
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "arch-vm" > /etc/hostname

# Initramfs
mkinitcpio -P

# Bootloader
bootctl install
cat > /boot/loader/loader.conf <<BOOTLOADER
default arch
timeout 0
BOOTLOADER

cat > /boot/loader/entries/arch.conf <<ENTRY
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value $ROOT_PART) rw
ENTRY

# Root password
echo "root:packer" | chpasswd

# Create packer user
useradd -m -G wheel packer
echo "packer:packer" | chpasswd
echo "packer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Enable services
systemctl enable systemd-networkd
systemctl enable systemd-resolved

EOF

# Unmount
umount -R /mnt

echo "Installation complete. Rebooting..."
reboot</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/packer/arch/http/install.sh