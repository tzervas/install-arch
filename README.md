# Arch Linux Automated Installer

This project contains a complete automated installation system for Arch Linux configured as a high-performance virtualization host.

## Project Structure

```
install-arch/
├── configs/                    # Installation configuration files
│   ├── archinstall-config.json # Main archinstall configuration
│   ├── system-update          # Read-only root update script
│   ├── post-install.sh        # Post-installation setup
│   ├── force-password-change.sh # Security enforcement
│   ├── first-login-setup      # User environment setup
│   ├── configure-installer.sh # Interactive configuration helper
│   └── README.md              # Configuration documentation
├── iso/                       # Arch Linux installation media
│   └── archlinux-2025.12.01-x86_64.iso
├── prepare-usb.sh             # USB preparation script
└── GETTING_STARTED.md         # Complete installation guide
```

## Quick Start

1. **Prepare USB Drive**:
   ```bash
   sudo ./prepare-usb.sh
   ```

2. **Configure BIOS** on target PC:
   - Enable VT-x, VT-d, IOMMU
   - Enable Above 4G Decoding
   - Boot from USB

3. **Boot and Install**:
   ```bash
   # In Arch live environment
   mkdir -p /root/archconfig
   mount /dev/disk/by-label/ARCH_* /mnt
   cp -r /mnt/archinstall /root/archconfig
   umount /mnt

   cd /root/archconfig/archinstall
   ./configure-installer.sh  # Set LUKS password

   archinstall --config archinstall-config.json
   ```

## System Specifications

- **Hardware**: Intel 14700K, ASUS Z790 TUF, RTX 5080, 48GB DDR5, 2TB NVMe
- **Filesystem**: BTRFS with LUKS encryption and zstd compression
- **Bootloader**: systemd-boot (reliable with LUKS/BTRFS)
- **Desktop**: KDE Plasma with multi-monitor support
- **Virtualization**: KVM/QEMU with PCIe passthrough ready
- **Security**: Read-only root filesystem, forced password change

## Features

- ✅ Automated partitioning and encryption
- ✅ Read-only root for stability
- ✅ KVM virtualization with IOMMU
- ✅ NVIDIA GPU drivers and passthrough
- ✅ KDE Plasma desktop environment
- ✅ Development tools and Docker
- ✅ Multi-monitor configuration
- ✅ System update automation

## Documentation

See [GETTING_STARTED.md](GETTING_STARTED.md) for complete installation and usage instructions.

## Requirements

- USB drive (8GB+)
- Target PC with supported hardware
- BIOS configured for virtualization
- Internet connection for package downloads

## License

Configuration files are provided as-is for personal use.