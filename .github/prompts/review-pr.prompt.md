# review-pr

Conduct a comprehensive PR review for the install-arch project following quality control standards:

- Analyze all changed files for security vulnerabilities and best practices
- Verify hardware abstraction compatibility and PCIe passthrough correctness
- Check bash scripts for proper error handling and POSIX compliance
- Validate configuration files for security and maintainability
- Ensure testing evidence and documentation updates are present
- Assess overall code quality and adherence to project standards
- Provide specific recommendations for improvements or fixes

Review criteria:
- Security: No hardcoded secrets, proper encryption, access controls
- Quality: Error handling, code style, documentation
- Compatibility: Hardware support, Arch Linux best practices
- Testing: Evidence of validation, edge case coverage
- Documentation: README updates, troubleshooting guides

Context files to reference:
#file:README.md
#file:.github/copilot-instructions.md
#file:configs/archinstall-config.json

Blockers for approval:
- Security vulnerabilities
- Unstable or untested changes
- Incompatible hardware configurations
- Missing documentation
- Poor code quality
