# create-usb-installer

Create or update the USB installer script for Arch Linux automated installation:

- Use the latest Arch ISO from official mirrors
- Extract ISO contents to FAT32 partition (do not use dd to write to partition)
- Implement dual-partition scheme: bootable ISO partition + writable configs partition
- Mount ISO as loop device and copy contents to USB partition
- Verify bootloader files are present after extraction (/boot, /arch, EFI)
- Include comprehensive error handling and validation
- Document hardware requirements and compatibility
- Ensure security best practices (no hardcoded secrets)
- Include QUICKSTART.txt with installation instructions
- Test in isolated environment before deployment

Context files to reference:
#file:prepare-usb.sh
#file:configs/archinstall-config.json
#file:README.md

Hardware focus: Intel 14700K/RTX5080, E5-2665 v4
