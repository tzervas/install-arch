# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-29

### Added
- **Unified Code Quality Tooling**: Replaced black, isort, flake8 with Ruff for faster, unified linting, formatting, and import sorting
- **Comprehensive Guardrails System**: Automated validation system for package management, environment security, and development standards
- **Devcontainer Support**: Full development environment containerization with VS Code integration
- **Read-Only Root Implementation**: Btrfs snapshot-based read-only root filesystem with secure updates
- **Hardware Compatibility Matrix**: Support for Intel 14700K/RTX5080 and E5-2665 v4 CPU configurations
- **Enhanced CI/CD Pipeline**: GitHub Actions with comprehensive testing, coverage reporting, and automated quality checks
- **Local CI Command**: `install-arch local-ci` for comprehensive local validation
- **Security Hardening Documentation**: Comprehensive security configuration guides and procedures
- **Testing Procedures**: Detailed testing frameworks and validation procedures
- **Pre-commit Hooks**: Automated code quality enforcement with Ruff integration
- **Package Baseline System**: Version pinning and dependency validation for reproducible builds

### Changed
- **Development Workflow**: Streamlined with unified tooling and automated guardrails
- **CI Pipeline**: Modernized to use Ruff instead of fragmented black/isort/flake8 tools
- **Dependency Management**: Enhanced with UV package manager and comprehensive validation
- **Error Handling**: Improved throughout the codebase with proper exception handling
- **Documentation**: Expanded with development setup, security hardening, and testing procedures

### Fixed
- **USB Installer Script**: Fixed read-only ISO mounting and partition creation issues
- **Btrfs Snapshot Logic**: Corrected mounting and cleanup procedures for read-only root
- **Test Coverage**: Improved from ~75% to 84% with comprehensive test suites
- **Import Organization**: Automated import sorting and validation with Ruff
- **Code Formatting**: Consistent formatting across entire codebase with Ruff

### Security
- **Guardrails Enforcement**: Automated security policy validation
- **Secure Temporary Files**: Enhanced temporary file handling with proper cleanup
- **Environment Isolation**: Devcontainer-based development environment isolation
- **Dependency Validation**: Package baseline enforcement for security

### Developer Experience
- **Unified Tooling**: Single Ruff command for linting, formatting, and import sorting
- **Local CI**: Comprehensive local validation before commits
- **Pre-commit Hooks**: Automated quality checks on commit
- **Development Container**: Consistent development environment across machines
- **Enhanced CLI**: Rich command-line interface with comprehensive subcommands

### Infrastructure
- **GitHub Actions**: Complete CI/CD pipeline with testing, linting, and coverage
- **Pre-commit Configuration**: Automated code quality enforcement
- **UV Package Manager**: Fast, reliable Python package management
- **Devcontainer**: Containerized development environment
- **Branch Strategy**: Clean separation of main (stable) and dev (integration) branches

## [0.1.0] - 2025-01-01

### Added
- Initial automated Arch Linux installer
- Basic GitHub Copilot integration
- Core installation scripts and configurations
- Initial project structure and documentation

[1.0.0]: https://github.com/tzervas/install-arch/compare/v0.1.0...v1.0.0