#!/bin/bash
# Store VM image manifest for rebuild capability

set -euo pipefail

IMAGE_PATH="$1"
DISTRO="${2:-arch}"
DESKTOP="${3:-kde}"
VERSION="${4:-latest}"

MANIFEST_DIR="vm-images/manifests"
MANIFEST_FILE="$MANIFEST_DIR/${DISTRO}-${DESKTOP}-${VERSION}.json"

echo "Storing manifest for $IMAGE_PATH"

# Calculate checksums
MD5=$(md5sum "$IMAGE_PATH" | cut -d' ' -f1)
SHA256=$(sha256sum "$IMAGE_PATH" | cut -d' ' -f1)
SIZE=$(stat -c%s "$IMAGE_PATH")

# Get build info
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PACKER_VERSION=$(packer version 2>/dev/null | head -1 || echo "unknown")

# Create manifest
cat > "$MANIFEST_FILE" << EOF
{
  "image": {
    "path": "$IMAGE_PATH",
    "size": $SIZE,
    "md5": "$MD5",
    "sha256": "$SHA256"
  },
  "build": {
    "distro": "$DISTRO",
    "desktop": "$DESKTOP",
    "version": "$VERSION",
    "date": "$BUILD_DATE",
    "packer_version": "$PACKER_VERSION",
    "builder": "qemu"
  },
  "config": {
    "packer_file": "packer/arch/arch-${DESKTOP}.pkr.hcl",
    "variables": {
      "vm_name": "${DISTRO}-${DESKTOP}",
      "desktop_env": "$DESKTOP",
      "access_method": "spice"
    }
  },
  "rebuild": {
    "command": "packer build -var 'vm_name=${DISTRO}-${DESKTOP}' -var 'desktop_env=${DESKTOP}' packer/arch/arch-${DESKTOP}.pkr.hcl",
    "dependencies": [
      "packer/arch/setup-arch.sh",
      "packer/arch/http/install.sh"
    ]
  }
}
EOF

echo "✅ Manifest stored: $MANIFEST_FILE"

# Archive old versions (keep last 3)
ARCHIVE_DIR="$MANIFEST_DIR/archive"
mkdir -p "$ARCHIVE_DIR"

# Find old manifests
find "$MANIFEST_DIR" -name "${DISTRO}-${DESKTOP}-*.json" -type f | sort -r | tail -n +4 | while read -r old_file; do
    mv "$old_file" "$ARCHIVE_DIR/"
    echo "📦 Archived old manifest: $(basename "$old_file")"
done

echo "✅ Manifest management complete"</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/scripts/store-manifest.sh