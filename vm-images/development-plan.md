# VM Images Development Plan

## Overview
Develop KVM-compatible qcow2 images for testing Arch Linux installations with various desktop environments and access methods.

## Target Distros & Environments
- **Arch Linux**: Base distro with KDE Plasma, CLI/TUI, WM (i3), DE (KDE/GNOME)
- **Debian**: Bookworm stable with XFCE, CLI/TUI, WM, DE
- **Ubuntu**: 24.04 LTS with GNOME, CLI/TUI, WM, DE
- **Fedora**: Latest with KDE, CLI/TUI, WM, DE

## Access Methods
- **Terminal/SSH**: Headless CLI access
- **SPICE**: Remote desktop protocol
- **Direct Console**: Local QEMU console

## Hardware Targets
- Intel 14700K + RTX 5080 (primary)
- E5-2665 v4 + Quadro P4000 (enterprise)
- AMD Ryzen + Radeon (future)

## Development Phases
1. **Phase 1: No GPU** - Base functionality, no passthrough
2. **Phase 2: Emulated GPU** - Virtual GPU for testing
3. **Phase 3: Real GPU** - Full PCIe passthrough

## Build Process
- Use Packer for automation
- Store manifests for rebuilds
- Optimize storage with BTRFS deduplication
- Archive legacy versions

## Security Requirements
- LUKS encryption for all images
- Read-only root filesystem
- Force password changes
- Minimal attack surface

## Quality Assurance
- Boot testing in QEMU
- Hardware compatibility validation
- Performance benchmarking
- Security auditing

## Branching Strategy
- Feature branches from dev
- PRs to testing for integration
- Documentation updates required
- Conventional commits enforced

## Agent Coordination
- **Project Manager**: Milestone planning and tracking
- **Orchestrator**: Task sequencing and execution
- **SWE**: Automation script development
- **Linux Sysadmin**: Distro-specific configurations
- **Virtualization**: KVM/qcow2 setup and passthrough
- **Security**: Encryption and hardening
- **Testing**: Validation and QA
- **Evaluator**: Quality assessment
- **PR Review**: Gatekeeping and approval
- **Documentation**: Guide creation and updates</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/README.md