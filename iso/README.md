# Arch Linux Installation Media

This directory contains Arch Linux installation media for the install-arch project.

## Required Files

To use this installer, you need to download the following files:

### Primary Installation Media
- **archlinux-2025.12.01-x86_64.iso** (1.5GB)
  - Download from: https://mirror.rackspace.com/archlinux/iso/2025.12.01/
  - Or any official Arch Linux mirror
  - Verify with: `sha256sum archlinux-2025.12.01-x86_64.iso`

### Bootstrap (Alternative)
- **archlinux-bootstrap-2025.12.01-x86_64.tar.zst** (36MB)
  - Download from: https://mirror.rackspace.com/archlinux/iso/2025.12.01/
  - Useful for chroot installations or minimal setups
  - Verify with: `sha256sum archlinux-bootstrap-2025.12.01-x86_64.tar.zst`

## Why Files Are Not Included

Due to GitHub's 100MB file size limit and repository size considerations, large installation media files are not stored in this repository. This follows best practices for:

- Reducing repository size
- Avoiding unnecessary downloads
- Ensuring users get the latest available versions
- Complying with GitHub's Large File Storage policies

## Download Script

Use the `prepare-usb.sh` script which will guide you through downloading and preparing the installation media.

## Verification

Always verify downloads using the provided checksums:
- SHA256: Available on official mirrors
- GPG signatures: Available for additional verification

## Alternative Storage

If you need to store these files in a git repository, consider:
- Git LFS (Large File Storage)
- Separate release assets
- External storage with download scripts