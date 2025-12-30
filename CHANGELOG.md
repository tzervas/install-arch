# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Ventoy Bootloader Integration**: Switched USB preparation to use Ventoy universal bootloader for improved bootability across UEFI and legacy BIOS systems
- **Enhanced Checksum Verification**: Added dynamic official mirror retrieval with graceful fallback to local checksums
- **Blackwell Station Customizations**: Added E5-2665 v4 server-specific configurations including user environment setup, SSH key management, libvirt hooks, and network bridge configuration
- **Automated Release Workflow**: Implemented semantic versioning with GitHub Actions for automatic version bumping and release creation on merge to main

### Changed
- **USB Preparation Workflow**: Updated to use Ventoy instead of manual ISO extraction, with configuration files moved to `/configs/` directory
- **Documentation**: Updated installation instructions to reflect new Ventoy-based workflow

### Fixed
- **Bootability Issues**: Resolved USB boot detection problems by implementing Ventoy bootloader

## [1.0.0] - 2024-12-01

### Added
- **Unified Development Tooling**: Migrated from Black/isort/flake8 to Ruff for 10x faster linting, formatting, and import sorting
- **Comprehensive Guardrails System**: Implemented automated validation and security checks with package-baseline.toml
- **Enhanced CI/CD Pipeline**: Complete rewrite with comprehensive testing, validation, and security scanning
- **Devcontainer Support**: Added containerized development environment with .devcontainer/devcontainer.json
- **Security Hardening**: Read-only root implementation and advanced security features
- **Virtualization Features**: KVM/QEMU/libvirt integration with PCIe passthrough support
- **Agent System**: Comprehensive AI agent framework for development, testing, and deployment automation
- **Hardware Emulation**: Support for hardware abstraction and emulation configurations
- **Network Configuration**: Advanced networking setup with GitOps domain management
- **Package Management**: Parameterized package installation with baseline validation

### Changed
- **Python Version**: Updated to Python 3.13.7 with UV package manager
- **Build System**: Migrated to modern Python packaging with pyproject.toml
- **CI/CD**: Complete rewrite using GitHub Actions with comprehensive validation
- **Code Quality**: Unified tooling with Ruff replacing Black, isort, and flake8
- **Testing**: Enhanced test coverage to 84% with comprehensive test suite
- **Documentation**: Added comprehensive development and deployment guides

### Technical Improvements
- **Performance**: 10x faster code quality checks with Ruff
- **Type Safety**: MyPy integration for static type checking
- **Automation**: Pre-commit hooks with automated formatting and validation
- **Containerization**: Devcontainer support for consistent development environments
- **Security**: Guardrails system with automated security validation
- **Virtualization**: Advanced KVM/QEMU configuration with hardware passthrough

### Breaking Changes
- **Tooling Migration**: Black/isort/flake8 replaced by Ruff
- **Configuration**: Updated pyproject.toml with new dependency groups and build system
- **CI Workflows**: Complete rewrite of GitHub Actions pipelines
- **Package Baseline**: New package-baseline.toml for security validation

### Fixed
- **USB Installer**: Fixed read-only ISO mounting issues
- **Error Handling**: Improved bash script error handling with proper traps
- **Import Issues**: Resolved circular import problems in guardrails system
- **Test Coverage**: Improved test coverage from ~75% to 84%

### Security
- **Read-only Root**: Implementation of read-only root filesystem
- **Package Validation**: Automated package baseline checking
- **Dependency Scanning**: Security vulnerability scanning in CI/CD
- **Access Controls**: Enhanced user and system access controls

### Testing
- **Coverage**: Achieved 84% test coverage across all modules
- **Integration Tests**: Added comprehensive integration testing
- **Security Tests**: Automated security validation tests
- **Performance Tests**: Added performance benchmarking

### Documentation
- **Development Setup**: Comprehensive development environment setup guide
- **Security Hardening**: Security implementation and hardening procedures
- **Testing Procedures**: Detailed testing and validation procedures
- **API Documentation**: Complete API documentation for all modules

### Infrastructure
- **CI/CD Pipeline**: Modern GitHub Actions with matrix testing
- **Container Registry**: Automated container building and publishing
- **Artifact Management**: Comprehensive artifact management and versioning
- **Release Automation**: Automated release creation and publishing

## [0.1.0] - 2024-11-01

### Added
- Initial Arch Linux installation automation framework
- Basic CLI interface for installation management
- Core filesystem and package management modules
- Initial configuration system
- Basic testing framework

### Changed
- Initial project structure and organization

### Fixed
- Initial bug fixes and stability improvements