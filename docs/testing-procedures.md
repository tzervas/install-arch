# Testing Procedures for Install-Arch

This document outlines comprehensive testing procedures for validating the install-arch automated installation system.

## Hardware Testing Matrix

### Intel 14700K + RTX 5080 (Primary)
- **Boot Test**: Verify systemd-boot loads with LUKS prompt
- **Encryption**: Confirm LUKS decryption works with TPM integration
- **Filesystem**: Test BTRFS subvolumes and snapshot creation
- **PCIe Passthrough**: Validate IOMMU groups and VFIO binding
- **GPU Drivers**: Confirm NVIDIA drivers load correctly
- **Virtualization**: Test KVM/QEMU with GPU passthrough

### Intel 14700K + RTX 4070 (Secondary)
- **Boot Test**: Same as primary
- **Passthrough**: Verify different GPU model compatibility
- **Performance**: Compare virtualization performance

### E5-2665 v4 + RTX 5080 (Limited)
- **Boot Test**: May require additional kernel parameters
- **IOMMU**: Test older CPU IOMMU compatibility
- **Stability**: Monitor for hardware-specific issues

### E5-2665 v4 + Quadro P4000 (Enterprise)
- **Boot Test**: Verify enterprise hardware compatibility
- **Passthrough**: Test professional GPU passthrough
- **Stability**: Ensure long-term reliability

## Automated Testing Scripts

### USB Preparation Test
```bash
# Test USB creation without actual hardware
# Verify ISO extraction process
./test-usb-prep.sh
```

Key validations:
- ISO contents properly extracted to partition
- Bootloader files present (syslinux.cfg or EFI directory)
- Config partition accessible and writable
- All configuration files copied correctly

### Configuration Validation
```bash
# Validate all config files
./validate-configs.sh
```

### Hardware Simulation
```bash
# Simulate hardware configurations
./simulate-hardware.sh --cpu 14700K --gpu RTX5080
```

## Manual Testing Checklist

- [ ] USB boots on target hardware (UEFI and BIOS modes)
- [ ] ISO partition contains bootloader files (/boot, /arch directories)
- [ ] Config partition is accessible from live environment
- [ ] LUKS encryption setup completes
- [ ] BTRFS filesystem mounts correctly
- [ ] System updates run without errors
- [ ] KDE Plasma desktop loads
- [ ] Virtualization host configured
- [ ] PCIe passthrough functional
- [ ] Network configuration works
- [ ] Security hardening applied

## Error Recovery Testing

1. **Failed USB Creation**: Verify cleanup and retry mechanisms (mount point cleanup)
2. **ISO Extraction Failures**: Test fallback and error messages
3. **Boot Failures**: Test fallback boot options (UEFI vs BIOS)
3. **Encryption Issues**: Validate recovery procedures
4. **Filesystem Corruption**: Test BTRFS repair tools

## Performance Benchmarks

- Boot time: < 30 seconds
- Installation time: < 15 minutes
- Virtualization startup: < 10 seconds
- GPU passthrough latency: < 5ms

## Reporting

All test results should be documented with:
- Hardware configuration
- Test date and environment
- Pass/fail status
- Performance metrics
- Issues encountered and resolutions
