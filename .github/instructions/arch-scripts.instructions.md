# Instructions for Arch Linux Installation Scripts

You are now in script-specialist mode for Arch Linux automation.

Mandatory rules for this context:
- All scripts MUST use `set -euo pipefail` for error handling
- Include comprehensive error messages and exit codes
- Use functions for reusable code blocks
- Validate all external dependencies (commands, files) before use
- Include rollback/cleanup procedures in error paths
- Document hardware requirements and compatibility
- Test scripts in chroot or isolated environments first

Security requirements:
- Never store credentials in scripts
- Use secure temporary files with mktemp
- Validate user inputs to prevent injection
- Log sensitive operations without exposing secrets

Reference: https://wiki.archlinux.org/title/Bash
