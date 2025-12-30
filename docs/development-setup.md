# Development Environment Setup

This guide explains how to set up the development environment for the install-arch project with proper package management, filesystem operations, and guardrails compliance.

## Prerequisites

- VS Code with Dev Containers extension
- Docker
- Git

## Quick Start

1. **Open in Dev Container**:
   ```bash
   # Clone the repository
   git clone https://github.com/your-org/install-arch.git
   cd install-arch

   # Open in VS Code
   code .

   # When prompted, click "Reopen in Container" or use Command Palette:
   # "Dev Containers: Reopen in Container"
   ```

2. **The devcontainer will automatically**:
   - Install uv (fast Python package manager)
   - Create a virtual environment
   - Install project dependencies
   - Set up secure temporary directories
   - Install Arch Linux development tools

## Configuration

The development environment is configured via `dev-config.toml`:

```toml
[package_manager]
tool = "uv"  # Options: uv, pip, poetry, pipenv
venv_path = ".venv"
python_version = "3.11"

[filesystem]
use_git_ops = true
tmp_base_dir = "/tmp/install-arch-dev"
use_secure_tmp = true
```

## Package Management

All Python package management is handled through the configured tool:

### Using uv (default)
```bash
# Install dependencies
uv pip install -e .

# Install dev dependencies
uv pip install -e ".[dev]"

# Add a new dependency
uv add package-name
```

### Using the CLI tool
```bash
# Set up environment
install-arch-dev setup

# Check guardrails compliance
install-arch-dev check-guardrails

# Create secure temp directory
install-arch-dev temp-dir

# Stage files for commit
install-arch-dev stage file1.py file2.py

# Commit changes
install-arch-dev commit "Add new feature"
```

## Filesystem Operations

### Git-aware operations
When `use_git_ops = true`, file operations prefer git commands:

```bash
# Move files (uses git mv)
install-arch-dev mv old_name.py new_name.py

# Remove files (uses git rm)
install-arch-dev rm unwanted_file.py
```

### Secure Temporary Files
All temporary files use secure creation:

```bash
# Create secure temp directory
temp_dir=$(install-arch-dev temp-dir --prefix my-feature-)

# Create secure temp file
temp_file=$(install-arch-dev temp-file --suffix .log)

# Clean up when done
install-arch-dev clean-temp
```

## Guardrails Compliance

The project enforces baseline guardrails for:

- **Package Management**: Must use configured tool (uv by default)
- **Virtual Environments**: Must be tool-managed
- **Filesystem Operations**: Prefer git commands for tracked files
- **Temporary Files**: Must use secure creation methods
- **Development Environment**: Additional packages require devcontainer

### Checking Compliance
```bash
# Check current compliance status
install-arch-dev check-guardrails

# Enforce compliance (fails if violations found)
install-arch-dev enforce-guardrails
```

## Supported Package Managers

The system supports parameterization for different package managers:

### uv (recommended)
- Fast Python package installer
- Modern dependency resolver
- Virtual environment management

### pip
- Standard Python package installer
- Uses requirements.txt or pyproject.toml

### poetry
- Dependency management and packaging
- Virtual environment management

### pipenv
- Package management with Pipfile
- Virtual environment management

## Directory Structure

```
.devcontainer/          # Dev container configuration
├── devcontainer.json   # Container setup
└── post-create.sh      # Post-creation setup script

src/install_arch/       # Main package
├── cli.py             # Command-line interface
├── config.py          # Configuration management
├── filesystem.py      # Git-aware file operations
├── package_manager.py # Multi-tool package management
└── guardrails.py      # Compliance validation

.github/guardrails/     # Guardrails configuration
└── package-baseline.toml
```

## Troubleshooting

### Dev Container Issues
- Ensure Docker is running
- Check VS Code Dev Containers extension is installed
- Try "Dev Containers: Rebuild Container" from Command Palette

### Package Manager Issues
- Check `dev-config.toml` for correct tool configuration
- Run `install-arch-dev check-guardrails` to diagnose
- Ensure the tool is installed: `which uv` or `which poetry`

### Permission Issues
- Temporary directories are created with restrictive permissions (700)
- Ensure you're running in the devcontainer, not host system

## Contributing

1. Always work in the devcontainer
2. Check guardrails compliance before committing
3. Use the CLI tools for file operations and package management
4. Follow the configured package manager conventions