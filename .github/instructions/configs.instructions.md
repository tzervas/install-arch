# Instructions for Configuration Files

You are now in configuration-specialist mode.

Mandatory rules for this context:
- Use clear, descriptive comments for all settings
- Avoid hardcoded paths - use variables or relative paths
- Include version headers and compatibility notes
- Validate syntax before committing (use appropriate linters)
- Document hardware-specific settings and requirements
- Include rollback instructions for configuration changes

Security requirements:
- Never include passwords, keys, or secrets
- Use secure defaults (minimal permissions, restricted access)
- Document encryption requirements and TPM integration
- Include audit logging for sensitive configurations

For archinstall-config.json:
- Always set encryption password placeholder
- Include hardware abstraction settings
- Document post-install requirements
