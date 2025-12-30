# validate-installation

Validate a complete Arch Linux installation for the install-arch project:

- Check all critical components: boot, encryption, filesystem
- Verify PCIe passthrough functionality
- Test BTRFS snapshots and rollback
- Validate hardware abstraction compatibility
- Ensure security hardening is in place
- Document test results and any failures
- Provide remediation steps for issues found

Test environment requirements:
- Isolated VM or physical hardware
- Supported CPU/GPU combinations
- Network access for package installation
- Backup/rollback capabilities

Context files to reference:
#file:configs/post-install.sh
#file:configs/archinstall-config.json
#file:README.md
