# Security Hardening Guide

This guide covers security configurations and TPM integration for the install-arch system.

## TPM 2.0 Integration

### Prerequisites
- TPM 2.0 module enabled in BIOS
- `tpm2-tools` package installed
- `tpm2-tss` systemd service enabled

### LUKS with TPM
```bash
# Seal LUKS key with TPM
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+4+7 /dev/nvme0n1p2

# Verify TPM enrollment
systemd-cryptenroll /dev/nvme0n1p2
```

### PCR Policy Configuration
- PCR 0: BIOS code
- PCR 2: UEFI drivers
- PCR 4: Boot loader code
- PCR 7: Secure boot state

## Security Audit Checklist

### Boot Security
- [ ] Secure Boot enabled
- [ ] TPM measured boot
- [ ] LUKS encryption with TPM binding
- [ ] systemd-boot integrity verified

### System Hardening
- [ ] Read-only root filesystem
- [ ] AppArmor profiles enabled
- [ ] SELinux in enforcing mode (if applicable)
- [ ] Firewall configured (ufw/firewalld)
- [ ] SSH hardened (key-only auth, no root login)

### Access Control
- [ ] sudo configured with no password for wheel group
- [ ] Password policies enforced
- [ ] User accounts locked after failed attempts
- [ ] Audit logging enabled

### Network Security
- [ ] NetworkManager configured securely
- [ ] DNS over HTTPS enabled
- [ ] VPN recommended for remote access

## Recovery Procedures

### TPM Lockout Recovery
1. Boot from USB in recovery mode
2. Clear TPM: `tpm2_clear`
3. Re-enroll LUKS: `systemd-cryptenroll --wipe-slot=tpm2 /dev/mapper/root`

### Password Reset
1. Boot from USB
2. Mount encrypted root: `cryptsetup luksOpen /dev/nvme0n1p2 root`
3. Reset password: `passwd root`

## Monitoring

### Log Review
```bash
# Check security logs
journalctl -t audit
journalctl -u tpm2-tss
```

### TPM Status
```bash
# Verify TPM functionality
tpm2_getrandom 8
tpm2_pcrread
```
