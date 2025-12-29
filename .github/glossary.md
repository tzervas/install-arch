# Project Glossary

This glossary defines key terms, acronyms, and concepts used throughout the install-arch project, with a focus on Arch Linux, virtualization, and hardware-specific configurations.

## A

**Arch Linux**: A lightweight, rolling-release Linux distribution that emphasizes simplicity, modernity, and user choice. This project automates Arch installation for virtualization hosts.

**archinstall**: The official Arch Linux installer tool that uses JSON configuration files for automated, unattended installations.

## B

**BTRFS (B-Tree File System)**: A modern Linux filesystem with advanced features like copy-on-write, snapshots, subvolumes, compression, and RAID support. Used for encrypted partitions with zstd compression.

**BTRFS Snapshots**: Point-in-time copies of BTRFS subvolumes that enable rollback and backup capabilities. Used for system stability and data protection.

**BTRFS Subvolumes**: Separate filesystem trees within a BTRFS partition, allowing independent mounting and snapshotting. Configured for root, home, snapshots, log, and data partitions.

**Bridge Interface**: A network bridge (e.g., br0) that connects virtual machines directly to the physical network, enabling DHCP and full network access.

## C

**Cloud-init**: A multi-distribution package for handling early initialization of cloud instances. Used in VM configurations for automated guest setup.

**Copy-on-Write (CoW)**: A filesystem feature where data is not duplicated until modified. BTRFS uses CoW for efficient snapshots and storage.

## D

**DHCP (Dynamic Host Configuration Protocol)**: Network protocol for automatic IP address assignment. VMs use DHCP on bridged networks for connectivity.

**DNSMASQ**: A lightweight DHCP and DNS server used by libvirt for virtual network management.

## E

**EFI (Extensible Firmware Interface)**: Modern firmware interface replacing BIOS. Used with systemd-boot for reliable booting on encrypted systems.

**EPT (Extended Page Tables)**: Intel VT-x feature for hardware-assisted virtualization, improving VM performance.

**ESP (EFI System Partition)**: FAT32 partition containing EFI bootloaders and kernels. Unencrypted for maximum compatibility.

## F

**fstab**: Linux file containing filesystem mount information. Modified for read-only root and BTRFS subvolumes.

## G

**GPU Passthrough**: Technique allowing a physical GPU to be directly assigned to a virtual machine using IOMMU and VFIO. Enables high-performance graphics in VMs.

## H

**Hardware Abstraction**: Design approach supporting multiple hardware configurations (e.g., Intel 14700K/RTX5080 vs E5-2665 v4) through variable-based configurations.

**Hugepages**: Large memory pages (2MB/1GB) that improve virtualization performance by reducing TLB misses.

**Hyper-V Enlightenments**: Microsoft Hyper-V features implemented in KVM for improved Windows guest performance.

## I

**IOMMU (Input-Output Memory Management Unit)**: Hardware feature enabling direct device assignment to VMs. Required for PCIe passthrough.

**IOMMU Groups**: Groups of PCI devices that must be assigned together due to hardware limitations. Critical for GPU passthrough planning.

**Intel VT-x/VT-d**: Intel virtualization extensions for CPU and I/O virtualization support.

## K

**KDE Plasma**: Qt-based desktop environment providing a modern, customizable user interface with multi-monitor support.

**KVM (Kernel-based Virtual Machine)**: Linux kernel module providing hardware-assisted virtualization.

## L

**libvirt**: Toolkit for managing virtualization platforms including QEMU/KVM. Provides virsh command-line tool and virt-manager GUI.

**LUKS (Linux Unified Key Setup)**: Standard Linux disk encryption. Used to encrypt BTRFS partitions with AES-XTS.

**LUKS2**: Latest LUKS format with improved features like authenticated encryption and better metadata handling.

## M

**mkinitcpio**: Arch Linux tool for creating initial ramdisks. Used to include encryption and VFIO modules.

## N

**Nested Virtualization**: Running virtual machines inside other virtual machines. Enabled for testing VM configurations.

**NetworkManager**: Linux network management daemon providing automatic network configuration and management.

**NVIDIA Persistence Mode**: Keeps NVIDIA GPU initialized even when no applications are using it, improving passthrough reliability.

## O

**OVMF (Open Virtual Machine Firmware)**: UEFI firmware for virtual machines, required for secure boot and modern OS support.

## P

**pacman**: Arch Linux package manager used for software installation and system updates.

**PCIe Passthrough**: See GPU Passthrough.

**Phased Approach**: Development methodology using progressive hardware configurations (no-GPU → emulated GPU → real GPU) for reliable deployment.

**Pinning (CPU Pinning)**: Assigning specific CPU cores/threads to virtual machines for performance isolation.

## Q

**Q35 Machine Type**: Modern QEMU machine type providing better hardware compatibility and performance than legacy PC types.

**QEMU (Quick Emulator)**: Open-source machine emulator and virtualizer. Core component of KVM virtualization.

## R

**Read-Only Root**: Mounting the root filesystem as read-only for security and stability. Writable directories managed via tmpfiles.

**Rolling Release**: Distribution model where updates are continuous rather than version-based. Arch Linux uses this approach.

## S

**SDDM (Simple Desktop Display Manager)**: Qt-based display manager for KDE Plasma login.

**Secure Boot**: UEFI feature requiring signed bootloaders. Not used due to complexity with custom kernels.

**Snapper**: BTRFS snapshot management tool providing automated snapshot creation and cleanup.

**systemd-boot**: Simple UEFI bootloader from systemd. Preferred for BTRFS/LUKS compatibility.

**systemd-tmpfiles**: Creates and manages volatile and temporary files/directories. Used for writable directories on read-only root.

## T

**TLB (Translation Lookaside Buffer)**: CPU cache for virtual-to-physical address translation. Hugepages reduce TLB pressure.

## U

**UEFI (Unified Extensible Firmware Interface)**: Modern firmware replacing BIOS with better security and features.

## V

**VFIO (Virtual Function I/O)**: Linux kernel framework for device assignment to VMs. Core component of GPU passthrough.

**VFIO-PCI**: VFIO driver for PCI devices, enabling direct hardware access from VMs.

**virt-manager**: GTK-based GUI for managing virtual machines via libvirt.

**Virtualization Host**: Physical machine running virtualization software to host multiple virtual machines.

**VM (Virtual Machine)**: Emulated computer system running as software on a host machine.

## W

**Wipe**: Complete erasure of disk contents before partitioning. Ensures clean installation.

## Z

**zstd**: Fast compression algorithm used by BTRFS for efficient storage and performance.

## Hardware-Specific Terms

**Intel 14700K**: Target CPU with 20 cores (8P+12E), 28 threads, supporting VT-x/VT-d and PCIe 5.0.

**RTX 5080**: Target GPU with PCIe passthrough support for high-performance VM graphics.

**E5-2665 v4**: Alternative server CPU (8 cores, 16 threads) with Broadwell architecture.

**ASUS Z790 TUF**: Target motherboard with robust PCIe and storage support.

**2TB NVMe SSD**: Target storage device partitioned into boot (1GB), root (200GB), and data (~1.8TB) volumes.

## Project-Specific Concepts

**Hardware Emulation Phases**: Three-phase approach (no-GPU baseline → GPU emulation → production GPU) for reliable deployment.

**Mock GPU Testing**: Software simulation of GPU passthrough for compatibility validation without hardware.

**BTRFS-LUKS**: Combined filesystem and encryption providing secure, compressed storage with snapshot capabilities.

**Read-Only Root with tmpfiles**: Stability-focused design where root is read-only but essential directories remain writable via systemd management.
