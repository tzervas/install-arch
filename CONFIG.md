# Configuration System

The install-arch project uses a hierarchical configuration system that allows for flexible customization while maintaining security and avoiding hardcoded values.

## Configuration Hierarchy

Configuration values are loaded in the following order (later sources override earlier ones):

1. **Default values** (built into the code)
2. **`config.toml`** (main project configuration)
3. **`local-config.toml`** (user-specific overrides, gitignored)
4. **Environment variables** (highest priority)
5. **`.env` file** (environment variable overrides, gitignored)

## Configuration Files

### config.toml

The main configuration file containing all default project settings. This file is version-controlled and contains safe defaults.

### local-config.toml

User-specific configuration that overrides main config. This file is gitignored and can contain sensitive or machine-specific settings.

### .env

Environment variable overrides. This file is gitignored and allows setting environment variables without modifying system environment.

## Configuration Sections

### [application]
Basic application metadata.

### [urls]
External URLs for downloads and installations:
- `uv_install_url`: URL for uv package manager installation
- `poetry_install_url`: URL for Poetry package manager installation
- `arch_mirrors`: List of Arch Linux mirror URLs
- `ventoy_base_url`: Base URL for Ventoy downloads

### [versions]
Version numbers for external tools:
- `arch_iso_version`: Arch Linux ISO version
- `ventoy_version`: Ventoy bootloader version
- `python_min_version`: Minimum Python version required

### [paths]
File system paths:
- `workspace_dir`: Development workspace directory
- `temp_base_dir`: Base directory for temporary files
- `iso_filename`: ISO filename template
- `ventoy_extract_dir`: Ventoy extraction directory template

### [network]
Network-related settings:
- `dns_test_ip`: IP address for connectivity testing
- `docker_registry_url`: Docker registry URL for connectivity checks

### [virtualization]
QEMU/KVM settings:
- `qemu_monitor_port`: QEMU monitor port
- `qemu_qmp_port`: QEMU QMP port
- `qemu_host_ip`: Host IP for QEMU connections

### [security]
Security-related settings:
- `secure_temp_enabled`: Enable secure temporary directories
- `validate_checksums`: Enable checksum validation
- `require_encryption`: Require encryption for sensitive operations

## Environment Variables

All configuration values can be overridden using environment variables with the format:

```
INSTALL_ARCH_{SECTION}_{KEY}={value}
```

Examples:
```bash
export INSTALL_ARCH_VERSIONS_ARCH_ISO_VERSION=2025.12.01
export INSTALL_ARCH_URLS_ARCH_MIRRORS="https://custom.mirror.com/archlinux/iso https://backup.mirror.com/archlinux/iso"
export INSTALL_ARCH_SECURITY_VALIDATE_CHECKSUMS=false
```

## Usage in Code

### Python

```python
from install_arch.config import Config

config = Config()
iso_version = config.arch_iso_version
mirrors = config.arch_mirrors
```

### Shell Scripts

```bash
# Load configuration
source scripts/config.sh

# Use configuration variables
echo "Using ISO version: $INSTALL_ARCH_VERSIONS_ARCH_ISO_VERSION"
echo "Mirrors: $INSTALL_ARCH_URLS_ARCH_MIRRORS"
```

## Security Considerations

- Never commit sensitive information to `config.toml`
- Use `local-config.toml` or `.env` for sensitive/machine-specific values
- The `.env` and `local-config.toml` files are gitignored
- Environment variables take highest priority for runtime overrides

## Examples

### Custom Mirror Configuration

In `local-config.toml`:
```toml
[urls]
arch_mirrors = [
    "https://custom.mirror.com/archlinux/iso",
    "https://backup.mirror.com/archlinux/iso"
]
```

Or via environment:
```bash
export INSTALL_ARCH_URLS_ARCH_MIRRORS="https://custom.mirror.com/archlinux/iso https://backup.mirror.com/archlinux/iso"
```

### Development Environment Override

In `.env`:
```bash
INSTALL_ARCH_VERSIONS_ARCH_ISO_VERSION=latest
INSTALL_ARCH_SECURITY_VALIDATE_CHECKSUMS=false
```