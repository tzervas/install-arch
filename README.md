# Arch Linux Automated Installer

This project contains a complete automated installation system for Arch Linux configured as a high-performance virtualization host.

## Development Workflow

This project uses automated quality checks to ensure code consistency and catch issues early.

### Pre-commit Hooks

Pre-commit hooks run automatically on every commit to enforce:
- Guardrails compliance
- Test execution
- Code quality (ruff)
- Type checking (mypy)

```bash
# Install pre-commit hooks
pre-commit install

# Run all checks manually
pre-commit run --all-files
```

### Local CI Checks

Run the same checks that execute in CI pipelines locally:

```bash
# Using the CLI command
uv run python -m install_arch.cli local-ci

# Or using the script
./scripts/run-local-ci.sh

# Quick test run only
uv run pytest tests/ -x --tb=short
```

### Development Environment

For development work requiring additional packages or tools, use the devcontainer environment:

```bash
# Open in VS Code devcontainer
code .
# Click "Reopen in Container" when prompted
```

#### Dev Container Automation

The project includes comprehensive automation for managing the Dev Container environment:

```bash
# Using Make commands
make build          # Build the Dev Container image
make rebuild        # Rebuild without cache
make clean          # Clean up unused resources
make update         # Update dependencies inside container
make status         # Show container status

# Using the CLI tool
uv run devcontainer-build
uv run devcontainer-rebuild
uv run devcontainer-clean
uv run devcontainer-status

# Using the management script
./scripts/devcontainer.sh build
./scripts/devcontainer.sh rebuild
./scripts/devcontainer.sh clean
./scripts/devcontainer.sh update
./scripts/devcontainer.sh status
```

See [Development Setup](docs/development-setup.md) for detailed instructions on:
- Package management with uv/poetry/pip/pipenv
- Secure filesystem operations
- Guardrails compliance
- Multi-tool parameterization

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
   mount /dev/disk/by-label/CONFIGS /mnt
   cp /mnt/archinstall/* /root/archconfig/
   umount /mnt

   cd /root/archconfig
   ./configure-installer.sh  # Set LUKS password

   archinstall --config archinstall-config.json
   ```

## Testing

Test the installation in a virtual machine before deploying to hardware:

1. **Validate Configuration**:
   ```bash
   ./validate-config.sh
   ```

2. **Test in VM** (requires prepared USB):
   ```bash
   sudo ./test-vm.sh /dev/sdX  # Replace /dev/sdX with your USB device
   ```

   **Test Credentials**:
   - LUKS encryption password: `testluks`
   - User password: `changeme123` (will be forced to change on first login)

3. **Expected VM Behavior**:
   - Boots from USB via Ventoy
   - Loads Arch Linux installer
   - Prompts for LUKS password during partitioning
   - Creates encrypted BTRFS filesystem
   - Installs system with KDE Plasma
   - Reboots into installed system

See [Testing Procedures](docs/testing-procedures.md) for comprehensive validation steps.

## System Specifications

- **Hardware**: Intel 14700K, ASUS Z790 TUF, RTX 5080, 48GB DDR5, 2TB NVMe
- **Filesystem**: BTRFS with LUKS encryption and zstd compression
- **Bootloader**: systemd-boot (reliable with LUKS/BTRFS)
- **Desktop**: KDE Plasma with multi-monitor support
- **Virtualization**: KVM/QEMU with PCIe passthrough ready
- **Security**: Read-only root filesystem, forced password change

## Hardware Compatibility Matrix

| CPU Model | GPU Model | Status | Notes |
|-----------|-----------|--------|-------|
| Intel 14700K | RTX 5080 | ✅ Fully Supported | Primary development platform |
| Intel 14700K | RTX 4070 | ✅ Supported | Tested passthrough configuration |
| E5-2665 v4 | RTX 5080 | ⚠️ Limited Support | Requires kernel parameter adjustments |
| E5-2665 v4 | Quadro P4000 | ✅ Supported | Enterprise GPU configuration |

**Compatibility Notes**:
- All configurations require VT-x/VT-d and IOMMU enabled in BIOS
- TPM 2.0 integration available for supported CPUs
- PCIe passthrough tested on all listed combinations
- BTRFS snapshots verified on all hardware

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

## Copilot Integration

This project includes comprehensive GitHub Copilot customization for enhanced development experience:

- **Repository Instructions** (`.github/copilot-instructions.md`): Global coding guidelines
- **Path-Specific Instructions** (`.github/instructions/`): Context-aware rules for scripts/configs
- **Custom Agents** (`.github/agents/`): Specialized assistants for different tasks
- **Reusable Prompts** (`.github/prompts/`): Task-specific prompt templates

**Agent Model Configuration**: Agents specify `model: grok-code-fast-1` but this field is ignored on github.com. Select Grok Code Fast 1 in your IDE's model picker to use it with custom agents.

**Available Agents**:
- `@project-manager`: Planning and milestone tracking
- `@orchestrator`: Task coordination and execution
- `@linux-sysadmin`: System administration tasks
- `@security`: Security configurations and hardening
- `@testing`: Installation validation and testing
- `@documentation`: Documentation maintenance
- `@evaluator`: Code quality assessment
- `@pr-review`: Quality control gatekeeping

## Requirements

- USB drive (8GB+)
- Target PC with supported hardware
- BIOS configured for virtualization
- Internet connection for package downloads

## License

Configuration files are provided as-is for personal use.