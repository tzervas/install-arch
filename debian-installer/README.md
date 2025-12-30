# Debian 13 Automated Installer

This directory contains the automated installer for Debian 13 (Trixie) with security-first configurations, similar to the Arch Linux installer but for Debian-based systems.

## Features

- **Automated Installation**: Preseed-based fully automated Debian 13 installation
- **Security Hardening**: UFW firewall, fail2ban, AppArmor, SSH hardening
- **Virtualization Ready**: QEMU/KVM, libvirt, Virt-Manager pre-configured
- **BTRFS Support**: Modern filesystem with snapshots and subvolumes
- **Desktop Environments**: KDE Plasma, GNOME, or minimal server options
- **Docker Integration**: Docker and Docker Compose pre-installed
- **USB Boot Support**: Hybrid ISO creation for direct USB booting

## Quick Start

### 1. Configure Environment

Copy and edit the environment configuration:

```bash
cp .env.example .env
nano .env
```

Set your passwords and configuration in `.env`:
```bash
INSTALL_DEBIAN_LUKS_PASSWORD=your_strong_luks_password
INSTALL_DEBIAN_USER_PASSWORD=your_initial_user_password
```

### 2. Prepare USB Drive

Run the USB preparation script:

```bash
sudo ./debian-installer/scripts/prepare-debian-usb.sh
```

This will:
- Download the Debian 13 netinst ISO
- Create a hybrid USB bootable drive
- Inject the preseed configuration

### 3. Boot and Install

1. Insert USB into target machine
2. Boot from USB (enable USB boot in BIOS)
3. Select "Automated Install (Preseed)" from boot menu
4. Debian installs automatically with your configuration

### 4. Post-Installation

After installation, the system will automatically run post-install setup, or you can run it manually:

```bash
sudo ./debian-installer/scripts/post-install.sh
```

## Configuration Files

### Main Configuration
- `debian-config.toml` - Main configuration file
- `local-debian-config.toml` - Local overrides (hostname, hardware-specific settings)

### Preseed Configuration
- `configs/debian-preseed.cfg` - Debian preseed answers for automated installation

### Scripts
- `scripts/debian-config.sh` - Configuration loader
- `scripts/prepare-debian-usb.sh` - USB preparation script
- `scripts/post-install.sh` - Post-installation setup

## Environment Variables

The installer uses environment variables prefixed with `INSTALL_DEBIAN_`:

### Required Secrets
- `INSTALL_DEBIAN_LUKS_PASSWORD` - LUKS encryption password
- `INSTALL_DEBIAN_USER_PASSWORD` - Initial user password

### Configuration Overrides
- `INSTALL_DEBIAN_NETWORK_HOSTNAME` - System hostname
- `INSTALL_DEBIAN_USER_NAME` - Username
- `INSTALL_DEBIAN_DISK_DEVICE` - Target disk (/dev/nvme0n1)
- `INSTALL_DEBIAN_DESKTOP_ENVIRONMENT` - Desktop (kde/gnome/xfce/none)

## Security Features

- **Full Disk Encryption**: LUKS encryption for all partitions
- **Firewall**: UFW with SSH and web ports open
- **Intrusion Prevention**: fail2ban for SSH protection
- **Mandatory Access Control**: AppArmor enabled
- **SSH Hardening**: Root login disabled, password authentication enabled
- **Automatic Updates**: Unattended security updates
- **Password Policy**: Forced password change on first login

## Hardware Support

Tested and configured for:
- **CPU**: Intel Xeon E5-2665 v4 (Broadwell)
- **Memory**: 64GB DDR4
- **Storage**: NVMe SSD with BTRFS
- **GPU**: NVIDIA RTX 5080 with Intel UHD Graphics
- **Network**: Gigabit Ethernet with DHCP

## Differences from Arch Installer

| Feature | Debian | Arch |
|---------|--------|------|
| Package Manager | apt | pacman |
| Init System | systemd | systemd |
| Configuration | preseed | archinstall JSON |
| Boot Method | ISOLINUX | Ventoy |
| Desktop | KDE Plasma | KDE Plasma |
| Security | AppArmor | SELinux (optional) |
| Updates | unattended-upgrades | manual |

## Troubleshooting

### USB Boot Issues
- Ensure USB is formatted as FAT32
- Check BIOS boot order
- Try different USB ports
- Verify ISO integrity

### Installation Failures
- Check preseed syntax
- Verify disk partitioning
- Ensure network connectivity
- Check logs in `/var/log/installer/`

### Post-Install Issues
- Run post-install script manually
- Check service status: `systemctl status <service>`
- Verify package installation: `dpkg -l | grep <package>`

## Development

To modify the installer:

1. Edit configuration in `debian-config.toml`
2. Update preseed file in `configs/debian-preseed.cfg`
3. Modify scripts in `scripts/` directory
4. Test with virtual machines

## License

This Debian installer is part of the install-arch project and follows the same licensing terms.