# Virtualization Tasks for Next Phase

## Overview
Create KVM-compatible qcow2 images for various Linux distros with pre-configured environments for Arch installation development.

## Distros and Environments
- **Arch Linux**: Rolling release, CLI/TUI, WM (i3), DE (KDE/Plasma)
- **Debian**: Stable (Bookworm), Testing (Trixie), CLI/TUI, WM, DE
- **Ubuntu**: LTS (24.04), Rolling (unstable), CLI/TUI, WM, DE
- **Fedora**: Latest stable, CLI/TUI, WM, DE

## Access Methods
- Terminal/SSH
- SPICE (remote desktop)
- Direct console

## Build Process
- Use Packer for automation
- Pin base versions, update during build
- Vet for stability before pinning
- Store manifests for legacy rebuilds, not full images
- Automate checking, building, testing, patching
- Minor/patch releases until major, then archive older

## Storage Optimization
- Keep version ranges (e.g., last 3 major, last 5 minor)
- Automate archiving of sub-releases

## Hardware Abstraction
- Focus on Intel/AMD CPUs, NVIDIA/AMD GPUs
- VFIO passthrough configs
- Libvirt integration

## Security
- Encrypted images where possible
- Minimal attack surface
- TPM integration