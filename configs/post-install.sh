#!/bin/bash
# Post-installation script to configure read-only root and other advanced features
# Run this after the base installation completes

set -e

echo "=== Post-Installation Configuration ==="
echo "Configuring read-only root filesystem and virtualization..."

# Mount point (adjust if needed for chroot environment)
ROOT_MOUNT="/mnt"

# Check if we're in the installer environment
if [ ! -d "$ROOT_MOUNT/etc" ]; then
    ROOT_MOUNT=""
fi

# Configure fstab for read-only root
echo "Configuring fstab for read-only root..."
sed -i 's|\(.*\s/\s.*btrfs\s.*\)|\1,ro|' "$ROOT_MOUNT/etc/fstab"

# Ensure /var/log is writable (already a subvolume)
if ! grep -q "/var/log" "$ROOT_MOUNT/etc/fstab"; then
    # Already should be there from btrfs subvolumes
    echo "Note: /var/log should be configured as a separate btrfs subvolume"
fi

# Create systemd tmpfiles for writable directories
cat > "$ROOT_MOUNT/etc/tmpfiles.d/var-rw.conf" << 'EOF'
# Writable directories needed for system operation
d /var/tmp 1777 root root -
d /var/cache 0755 root root -
d /var/lib 0755 root root -
d /var/spool 0755 root root -
EOF

# Configure NVIDIA for persistence
cat > "$ROOT_MOUNT/etc/modprobe.d/nvidia.conf" << 'EOF'
# Enable NVIDIA persistence mode
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF

# Configure IOMMU for virtualization
if [ -f "$ROOT_MOUNT/boot/loader/entries/arch.conf" ]; then
    echo "Configuring IOMMU for PCIe passthrough..."
    sed -i 's/options.*/& intel_iommu=on iommu=pt/' "$ROOT_MOUNT/boot/loader/entries/"*.conf
fi

# Configure libvirt for UEFI
echo "Configuring libvirt for UEFI and QEMU..."
mkdir -p "$ROOT_MOUNT/etc/libvirt"
cat > "$ROOT_MOUNT/etc/libvirt/qemu.conf" << 'EOF'
# QEMU configuration for UEFI
nvram = [
    "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd:/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
]

# User and group for QEMU processes
user = "kang"
group = "kvm"
EOF

# Configure KVM modules
cat > "$ROOT_MOUNT/etc/modprobe.d/kvm.conf" << 'EOF'
# KVM Configuration
options kvm ignore_msrs=1
options kvm report_ignored_msrs=0

# Intel specific
options kvm_intel nested=1
options kvm_intel enable_shadow_vmcs=1
options kvm_intel enable_apicv=1
options kvm_intel ept=1
EOF

# Enable nested virtualization
echo "options kvm_intel nested=1" > "$ROOT_MOUNT/etc/modprobe.d/kvm-nested.conf"

# Configure VFIO for GPU passthrough (placeholder - needs specific PCI IDs)
cat > "$ROOT_MOUNT/etc/modprobe.d/vfio.conf" << 'EOF'
# VFIO Configuration for GPU passthrough
# Uncomment and configure with your GPU's PCI IDs
# options vfio-pci ids=10de:XXXX,10de:XXXX
# softdep nvidia pre: vfio-pci
EOF

# Add helpful message
cat > "$ROOT_MOUNT/etc/motd" << 'EOF'
================================================================================
        Welcome to Kang's Arch Linux Virtualization Host
================================================================================

System Configuration:
  - Read-only root filesystem (security & stability)
  - LUKS encrypted partitions with BTRFS & zstd compression
  - Virtualization ready: KVM, QEMU, libvirt
  - NVIDIA GPU with proprietary drivers
  - Intel 14700K with IOMMU enabled

Important Commands:
  system-update          - Update system (handles read-only root)
  setup-monitors        - Configure multi-monitor setup
  virsh list --all      - List virtual machines
  virt-manager          - Launch VM manager (GUI)

Data Partition: /data (large, encrypted, read-write)
User Data: /home/kang (encrypted, read-write)

Documentation: See /usr/share/doc/arch-setup/README.md

================================================================================
EOF

# Create documentation directory
mkdir -p "$ROOT_MOUNT/usr/share/doc/arch-setup"

cat > "$ROOT_MOUNT/usr/share/doc/arch-setup/README.md" << 'EOF'
# Arch Linux Virtualization Host Setup Guide

## System Overview

This system is configured as a virtualization host with the following features:

- **Read-Only Root**: The root filesystem is mounted read-only for stability and security
- **Encrypted Storage**: LUKS encryption on all data partitions
- **BTRFS**: Modern filesystem with compression and snapshot support
- **KVM/QEMU**: Full virtualization support with PCIe passthrough capability

## Important Locations

- `/data` - Large data partition for VMs, containers, and general storage (1.8TB)
- `/home/kang` - User home directory (encrypted)
- `/boot` - Unencrypted EFI boot partition (ext4)

## System Updates

To update the system, use the provided script:

```bash
sudo system-update
```

This script:
1. Temporarily remounts root as read-write
2. Performs system update with pacman
3. Automatically remounts root as read-only

## GPU Passthrough Configuration

The system has IOMMU enabled. To configure GPU passthrough:

1. Find your GPU's PCI IDs:
   ```bash
   lspci -nn | grep -i nvidia
   ```

2. Edit `/etc/modprobe.d/vfio.conf` and add the IDs:
   ```bash
   sudo system-update  # This remounts root as RW
   sudo nano /etc/modprobe.d/vfio.conf
   # Add: options vfio-pci ids=10de:XXXX,10de:XXXX
   ```

3. Rebuild initramfs:
   ```bash
   sudo mkinitcpio -P
   ```

4. Reboot

## Multi-Monitor Setup

KDE Plasma handles multi-monitor configurations through:
- System Settings > Display Configuration (GUI)
- `kscreen-doctor` command-line tool

Or use the helper script:
```bash
setup-monitors
```

## Virtualization

### Start libvirtd
```bash
sudo systemctl start libvirtd
```

### Create a VM
```bash
virt-manager  # GUI tool
# or
virsh define vm-config.xml  # Command line
```

### VM Storage
Store VM disk images in `/data/vms/` for best performance and space.

## Snapshotting

Btrfs subvolumes are configured for easy snapshotting:

```bash
# Create snapshot
sudo btrfs subvolume snapshot / /.snapshots/root-$(date +%Y%m%d)

# List snapshots
sudo btrfs subvolume list /

# Restore from snapshot (requires remounting)
sudo mount -o remount,rw /
sudo btrfs subvolume delete /.snapshots/old-snapshot
```

## Troubleshooting

### Root is read-only
This is intentional. Use `system-update` for system changes, or manually:
```bash
sudo mount -o remount,rw /
# Make changes
sudo mount -o remount,ro /
```

### NVIDIA driver issues
```bash
sudo systemctl restart nvidia-persistenced
sudo modprobe nvidia
```

### Checking IOMMU groups
```bash
for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done
```
EOF

# Create systemd service to ensure root is read-only after boot
cat > "$ROOT_MOUNT/etc/systemd/system/remount-root-ro.service" << 'EOF'
[Unit]
Description=Remount root filesystem read-only
After=sysinit.target
Before=systemd-tmpfiles-setup.service

[Service]
Type=oneshot
ExecStart=/bin/mount -o remount,ro /
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
ln -sf "$ROOT_MOUNT/etc/systemd/system/remount-root-ro.service" "$ROOT_MOUNT/etc/systemd/system/sysinit.target.wants/remount-root-ro.service"

echo "=== Blackwell Station Custom Configuration ==="
echo "Applying E5-2665 v4 server specific settings..."

# Configure network bridge for virtualization
cat > "$ROOT_MOUNT/etc/netctl/bridge-br0" << 'EOF'
Description='Bridge for virtualization'
Interface=br0
Connection=bridge
BindsToInterfaces=(enp1s0)  # Adjust interface name as needed
IP=dhcp
EOF

# Enable network bridge
ln -sf "$ROOT_MOUNT/etc/netctl/bridge-br0" "$ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/netctl@bridge-br0.service"

# Configure libvirt hooks for GPU passthrough (placeholder)
mkdir -p "$ROOT_MOUNT/etc/libvirt/hooks"
cat > "$ROOT_MOUNT/etc/libvirt/hooks/qemu" << 'EOF'
#!/bin/bash
# Libvirt hook for GPU passthrough
# This will be customized based on specific GPU configuration

OBJECT="$1"
OPERATION="$2"

if [ "$OBJECT" = "prepare" ] && [ "$OPERATION" = "begin" ]; then
    # Unbind GPU from host driver
    echo "Preparing GPU passthrough..."
    # Add GPU unbind commands here when ready
fi

if [ "$OBJECT" = "release" ] && [ "$OPERATION" = "end" ]; then
    # Rebind GPU to host driver
    echo "Releasing GPU passthrough..."
    # Add GPU rebind commands here when ready
fi
EOF
chmod +x "$ROOT_MOUNT/etc/libvirt/hooks/qemu"

# Configure systemd for better virtualization support
cat > "$ROOT_MOUNT/etc/systemd/system/libvirtd.service.d/override.conf" << 'EOF'
[Service]
LimitNOFILE=4096
EOF

# Set up basic monitoring (placeholder)
cat > "$ROOT_MOUNT/etc/systemd/system/system-monitor.service" << 'EOF'
[Unit]
Description=Basic System Monitoring
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/journalctl -f -n 50
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Blackwell Station configuration applied successfully!"

echo "=== Security Hardening Configuration ==="
echo "Implementing security recommendations..."

# UFW Firewall Configuration
echo "Configuring UFW firewall with basic rules..."
if command -v ufw >/dev/null 2>&1; then
    systemctl enable ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw --force enable
else
    echo "UFW not installed, skipping firewall configuration"
fi

# SSH Hardening
echo "Hardening SSH configuration..."
if [ -f "$ROOT_MOUNT/etc/ssh/sshd_config" ]; then
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$ROOT_MOUNT/etc/ssh/sshd_config"
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' "$ROOT_MOUNT/etc/ssh/sshd_config"
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' "$ROOT_MOUNT/etc/ssh/sshd_config"
    systemctl enable sshd
else
    echo "SSH config not found, skipping SSH hardening"
fi

# Docker Security Configuration
echo "Configuring Docker security settings..."
if command -v docker >/dev/null 2>&1; then
    mkdir -p "$ROOT_MOUNT/etc/docker"
    cat > "$ROOT_MOUNT/etc/docker/daemon.json" << 'EOF'
{
    "userns-remap": "default",
    "icc": false
}
EOF
    systemctl enable docker
else
    echo "Docker not installed, skipping Docker security configuration"
fi

# Disable Unnecessary Services
echo "Disabling unnecessary services (bluetooth, cups)..."
systemctl disable bluetooth.service 2>/dev/null || true
systemctl disable cups.service 2>/dev/null || true

echo "Security hardening configuration complete!"

echo "=== KDE Plasma Desktop Enhancements ==="
echo "Configuring KDE Plasma for better desktop experience..."

# KDE Plasma configuration directory
KDE_CONFIG_DIR="$ROOT_MOUNT/home/kang/.config"
mkdir -p "$KDE_CONFIG_DIR"

# Set up KDE globals configuration
cat > "$KDE_CONFIG_DIR/kdeglobals" << 'EOF'
[General]
TerminalApplication=konsole
BrowserApplication=firefox.desktop
XftHintStyle=hintslight
XftSubPixel=none

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
SingleClick=false
ShowDeleteCommand=false

[Icons]
Theme=breeze-dark

[Toolbar style]
ToolButtonStyle=TextBesideIcon
EOF

# Configure KDE appearance (Breeze Dark theme)
mkdir -p "$KDE_CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc"
cat > "$KDE_CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc" << 'EOF'
[Containments][1][General]
icon=/usr/share/icons/breeze-dark/apps/48/system-file-manager.svg
plugin=org.kde.plasma.folder
EOF

# Set up default applications
cat > "$ROOT_MOUNT/usr/share/applications/defaults.list" << 'EOF'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/ftp=firefox.desktop
x-scheme-handler/chrome=firefox.desktop
application/x-extension-htm=firefox.desktop
application/x-extension-html=firefox.desktop
application/x-extension-shtml=firefox.desktop
application/xhtml+xml=firefox.desktop
application/x-extension-xhtml=firefox.desktop
application/x-extension-xht=firefox.desktop
audio/*=vlc.desktop
video/*=vlc.desktop
application/ogg=vlc.desktop
application/x-ogg=vlc.desktop
application/mxf=vlc.desktop
application/sdp=vlc.desktop
application/smil=vlc.desktop
application/x-smil=vlc.desktop
application/streamingmedia=vlc.desktop
application/x-streamingmedia=vlc.desktop
application/vnd.rn-realmedia=vlc.desktop
application/vnd.rn-realmedia-vbr=vlc.desktop
audio/aac=vlc.desktop
audio/x-aac=vlc.desktop
audio/vnd.dolby.heaac.1=vlc.desktop
audio/vnd.dolby.heaac.2=vlc.desktop
audio/aiff=vlc.desktop
audio/x-aiff=vlc.desktop
audio/amr=vlc.desktop
audio/amr-wb=vlc.desktop
audio/basic=vlc.desktop
audio/x-basic=vlc.desktop
EOF

# Configure KDE services (enable useful ones, disable resource-intensive)
cat > "$KDE_CONFIG_DIR/kded5rc" << 'EOF'
[Module-device_automounter]
autoload=true

[Module-freespacenotifier]
autoload=true

[Module-kded_accounts]
autoload=true

[Module-kded_touchpad]
autoload=true

[Module-ksysguard]
autoload=false

[Module-plasma-nm]
autoload=true

[Module-printmanager]
autoload=true

[Module-remotenotifier]
autoload=false

[Module-statusnotifierwatcher]
autoload=true
EOF

# Configure power management for desktop use
cat > "$KDE_CONFIG_DIR/powermanagementprofilesrc" << 'EOF'
[AC][DimDisplay]
idleTime=300000

[AC][HandleButtonEvents]
lidAction=1
powerButtonAction=16
triggerLidActionWhenExternalMonitorPresent=false

[AC][SuspendSession]
idleTime=600000
suspendType=1

[Battery][DimDisplay]
idleTime=120000

[Battery][HandleButtonEvents]
lidAction=1
powerButtonAction=16
triggerLidActionWhenExternalMonitorPresent=false

[Battery][SuspendSession]
idleTime=300000
suspendType=1

[LowBattery][Brightness]
value=30

[LowBattery][DimDisplay]
idleTime=60000

[LowBattery][HandleButtonEvents]
lidAction=1
powerButtonAction=16
triggerLidActionWhenExternalMonitorPresent=false

[LowBattery][SuspendSession]
idleTime=120000
suspendType=1
EOF

# Configure keyboard shortcuts for common tasks
cat > "$KDE_CONFIG_DIR/kglobalshortcutsrc" << 'EOF'
[ksmserver]
Lock Session=Ctrl+Alt+L,none,Lock Session

[kwin]
Show Desktop=Meta+D,none,Show Desktop
Window Close=Alt+F4,none,Close Window
Window Maximize=Meta+Up,none,Maximize Window
Window Minimize=Meta+Down,none,Minimize Window
Window Quick Tile Bottom=Meta+Down,none,Quick Tile Window to the Bottom
Window Quick Tile Left=Meta+Left,none,Quick Tile Window to the Left
Window Quick Tile Right=Meta+Right,none,Quick Tile Window to the Right
Window Quick Tile Top=Meta+Up,none,Quick Tile Window to the Top

[plasma-desktop]
activate task manager entry 1=Meta+1,none,Activate Task Manager Entry 1
activate task manager entry 2=Meta+2,none,Activate Task Manager Entry 2
activate task manager entry 3=Meta+3,none,Activate Task Manager Entry 3
activate task manager entry 4=Meta+4,none,Activate Task Manager Entry 4
activate task manager entry 5=Meta+5,none,Activate Task Manager Entry 5
EOF

# Configure notifications
cat > "$KDE_CONFIG_DIR/plasmanotifyrc" << 'EOF'
[Applications][firefox]
ShowPopups=true
ShowInHistory=true
ConfigureEvents=true

[Applications][vlc]
ShowPopups=true
ShowInHistory=true
ConfigureEvents=true

[Applications][virt-manager]
ShowPopups=true
ShowInHistory=true
ConfigureEvents=true

[Applications][systemsettings]
ShowPopups=false
ShowInHistory=false
ConfigureEvents=false
EOF

# Set up desktop effects (enable useful ones, disable heavy ones)
cat > "$KDE_CONFIG_DIR/kwinrc" << 'EOF'
[Compositing]
Enabled=true
OpenGLIsUnsafe=false
XRenderSmoothScale=false

[Effect-overview]
BorderActivate=9

[Effect-presentwindows]
BorderActivate=9

[Effect-windowview]
BorderActivate=9

[Plugins]
blurEnabled=true
contrastEnabled=false
dashboardEnabled=false
desktopgridEnabled=true
diminactiveEnabled=true
dimscreenEnabled=false
flipswitchEnabled=false
glideEnabled=false
kwin4_effect_fadeEnabled=true
kwin4_effect_fadedesktopEnabled=false
kwin4_effect_fadeinEnabled=true
kwin4_effect_fadetoopaqueEnabled=false
kwin4_effect_loginEnabled=false
kwin4_effect_logoutEnabled=false
kwin4_effect_maximizeEnabled=false
kwin4_effect_morphingpopupsEnabled=false
kwin4_effect_scaleEnabled=false
kwin4_effect_squashEnabled=false
kwin4_effect_startupfeedbackEnabled=true
kwin4_effect_translucencyEnabled=false
kwin4_effect_windowapertureEnabled=false
magnifierEnabled=false
minimizeanimationEnabled=true
mouseclickEnabled=false
mousemarkEnabled=false
overviewEnabled=true
presentwindowsEnabled=true
screenedgeEnabled=true
screenshotEnabled=false
sheetEnabled=false
showfpsEnabled=false
showpaintEnabled=false
slideEnabled=false
slidingpopupsEnabled=true
snaphelperEnabled=true
thumbnailasideEnabled=false
trackmouseEnabled=false
wobblywindowsEnabled=false
zoomEnabled=false
EOF

# Configure Dolphin file manager defaults
cat > "$KDE_CONFIG_DIR/dolphinrc" << 'EOF'
[General]
BrowseThroughArchives=false
ConfirmClosingMultipleTabs=false
RememberOpenedTabs=false
ShowFullPath=true
ShowSelectionToggle=true
Version=4

[MainWindow]
MenuBar=Disabled
ToolBarsMovable=Disabled

[PreviewSettings]
Plugins=desktop,audiothumbnail,imagethumbnail,jpegthumbnail,svgthumbnail,textthumbnail,windowsexethumbnail,comicsimagethumbnail,directorythumbnail,opendocumentthumbnail

[ViewPropertiesDialog]
dir=/home/kang
EOF

# Set proper ownership for KDE config files
if [ -n "$ROOT_MOUNT" ]; then
    chown -R 1000:1000 "$ROOT_MOUNT/home/kang/.config" 2>/dev/null || true
fi

echo "KDE Plasma desktop enhancements configured!"

echo "Post-installation configuration complete!"
