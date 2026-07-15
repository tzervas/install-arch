# Packer Configuration for Arch Linux VM Images

This directory contains Packer configurations for building KVM-compatible qcow2 images.

## Structure
- `arch/` - Arch Linux image configurations
- `debian/` - Debian image configurations
- `ubuntu/` - Ubuntu image configurations
- `fedora/` - Fedora image configurations
- `shared/` - Common variables and scripts

## Build Process
1. Install Packer
2. Validate configuration: `packer validate arch/`
3. Build image: `packer build arch/`
4. Test image: `qemu-system-x86_64 -hda output/image.qcow2`

## Variables
- `vm_name`: Name of the VM
- `vm_cpus`: Number of CPUs
- `vm_memory`: Memory in MB
- `vm_disk_size`: Disk size in GB
- `desktop_env`: KDE, GNOME, XFCE, i3
- `access_method`: spice, ssh, console

## Security
- LUKS encryption enabled
- SSH keys configured
- Firewall active
- SELinux/AppArmor enabled

## Optimization
- BTRFS filesystem
- zstd compression
- Deduplication enabled
- Sparse file handling</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/packer/README.md