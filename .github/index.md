# Project Index and Reference

This document provides a comprehensive index of all components in the install-arch project, organized by category with descriptions, purposes, and relationships.

## Project Overview

The install-arch project creates an automated Arch Linux installation system for a high-performance virtualization host with read-only root filesystem, LUKS encryption, BTRFS compression, and PCIe GPU passthrough capabilities.

## Directory Structure

```bash
install-arch/
├── configs/                    # Installation configuration files
├── iso/                       # Arch Linux installation media
├── prepare-usb.sh             # USB preparation script
├── GETTING_STARTED.md         # Quick start guide
├── README.md                  # Main project documentation
└── .github/                   # GitHub Copilot integration (created)
    ├── agents/                # Specialized AI agents
    ├── prompts/               # Common development prompts
    └── instructions/          # Path-specific instructions
```

## Key Components

### Configuration Files (`configs/`)

| File | Purpose | Key Features | Dependencies |
| ---- | ------- | ------------ | ------------ |
| `archinstall-config.json` | Main archinstall configuration | Automated partitioning, package installation, user setup | `archinstall` tool |
| `config.yaml` | Hardware and network configuration | Target system specs, VM defaults, security settings | Used by automation scripts |
| `hardware-emulation.yaml` | Virtualization hardware phases | Phased GPU passthrough setup, IOMMU/VFIO configs | `libvirt`, `qemu` |
| `post-install.sh` | Post-installation setup | Read-only root, IOMMU, libvirt configuration | Runs after base install |
| `system-update` | System update wrapper | Handles read-only root remounting | `pacman`, `mount` |
| `first-login-setup` | User environment setup | Directory creation, Git config, monitor setup | Runs on first login |
| `force-password-change.sh` | Security enforcement | Forces password change from default | PAM/profile integration |
| `configure-installer.sh` | Interactive config helper | Sets LUKS password, hostname, timezone | Modifies `archinstall-config.json` |
| `debian_preseed.txt` | Debian preseed config | Alternative Debian installation | Not used in Arch setup |
| `user-data.yaml` | Cloud-init user data | VM guest configuration | For Ubuntu VMs |
| `network-config.yaml` | Network configuration | DHCP setup for VMs | `netplan` |
| `gitops-domains.yaml` | Domain mapping | GitOps service domains | For GitLab/Grafana stack |
| `secret_allowlist.txt` | Secret scanning exceptions | Placeholder credentials | For security scanning |
| `README.md` | Configuration documentation | Detailed setup guides | References all configs |

### Scripts (`/` root level)

| File | Purpose | Key Features | Dependencies |
| ---- | ------- | ------------ | ------------ |
| `prepare-usb.sh` | USB drive preparation | ISO extraction, config copying, verification | `mount`, `cp`, `lsblk`, `parted` |
| `GETTING_STARTED.md` | Quick start guide | Step-by-step installation | References all components |
| `README.md` | Project documentation | Overview, features, usage | Comprehensive guide |

### ISO Files (`iso/`)

| File | Purpose | Key Features |
| ---- | ------- | ------------ |
| `archlinux-2025.12.01-x86_64.iso` | Arch Linux installer ISO | Official Arch Linux media |
| `sha256sums.txt`, `b2sums.txt` | Integrity verification | Checksums for ISO validation |
| `archlinux-bootstrap-*.tar.zst` | Bootstrap tarball | Minimal Arch system for chroot |

## Component Relationships

### Installation Flow

1. `prepare-usb.sh` → Extracts ISO contents and copies configs to USB partitions
2. Boot from USB → `archinstall-config.json` drives automated install
3. Post-install → `post-install.sh` configures advanced features
4. First boot → `first-login-setup` and `force-password-change.sh` run
5. Ongoing → `system-update` for system maintenance

### Virtualization Setup

- `hardware-emulation.yaml` → Defines VM configurations by phase
- `archinstall-config.json` → Installs KVM, QEMU, libvirt packages
- `post-install.sh` → Configures IOMMU, VFIO, libvirt
- `config.yaml` → Hardware specs for VM defaults

### Security & Stability

- `archinstall-config.json` → LUKS encryption, BTRFS subvolumes
- `post-install.sh` → Read-only root, tmpfiles for writable dirs
- `system-update` → Safe update process for read-only root
- `force-password-change.sh` → Enforces password changes

## Hardware Support

### Primary Target

- CPU: Intel 14700K (20 cores, 28 threads)
- GPU: NVIDIA RTX 5080
- Storage: 2TB NVMe SSD
- Memory: 48GB+ DDR5

### Alternative Configurations

- E5-2665 v4 server (8 cores, 16 threads) - via `hardware-emulation.yaml`
- Hardware abstraction in agents/prompts supports variations

## Key Technologies

- **Filesystem**: BTRFS with zstd compression, LUKS encryption, read-only root
- **Bootloader**: systemd-boot (reliable with BTRFS/LUKS)
- **Virtualization**: KVM/QEMU with libvirt, PCIe passthrough, VFIO
- **Desktop**: KDE Plasma with multi-monitor support
- **Security**: Read-only root, forced password changes, encrypted partitions
- **Automation**: Bash scripts, JSON configs, YAML specifications

## Development Workflow

1. Modify configs in `configs/` directory
2. Test with `prepare-usb.sh` on USB drive
3. Install on target hardware
4. Use `post-install.sh` for advanced setup
5. Maintain with `system-update` script

## GitHub Copilot Integration

The `.github/` directory contains:

- **agents/**: Specialized agents for evaluation, orchestration, project management, etc.
- **prompts/**: Common prompts for debugging, hardware abstraction, PCIe passthrough
- **instructions/**: Path-specific instructions for config files and scripts

These enable automated assistance for development, testing, and maintenance of the Arch Linux installation system.
