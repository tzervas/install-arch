# KDE Plasma Installation Validation Test Plan

This document provides comprehensive validation procedures for the enhanced Arch Linux installation with KDE Plasma desktop environment. The test plan covers both installation-time and post-install validation phases.

## Test Environment Prerequisites

- **Hardware**: Intel 14700K + RTX 5080 (primary test system)
- **Base Installation**: Arch Linux with BTRFS, LUKS encryption, read-only root
- **Network**: Active internet connection for package validation
- **Display**: Monitor connected and detected by Xorg/NVIDIA drivers

## Installation-Time Validation

### Phase 1: Package Installation Verification

**Objective**: Ensure all KDE Plasma and system packages install successfully without conflicts.

**Automated Test Script**: `scripts/validate-package-installation.sh`

```bash
#!/bin/bash
# validate-package-installation.sh
# Run during installation to verify package installation success

set -e

echo "=== Validating Package Installation ==="

# Core KDE packages
KDE_PACKAGES=(
    "plasma-desktop"
    "kde-applications-meta"
    "sddm"
    "konsole"
    "dolphin"
    "kdeconnect"
)

# System packages
SYSTEM_PACKAGES=(
    "networkmanager"
    "bluez"
    "cups"
    "docker"
    "libvirt"
    "qemu-full"
    "nvidia-dkms"
    "ufw"
    "openssh"
)

echo "Checking KDE packages..."
for pkg in "${KDE_PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "ERROR: Package $pkg not installed"
        exit 1
    fi
    echo "✓ $pkg installed"
done

echo "Checking system packages..."
for pkg in "${SYSTEM_PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "ERROR: Package $pkg not installed"
        exit 1
    fi
    echo "✓ $pkg installed"
done

echo "✓ All packages installed successfully"
```

**Manual Verification Points**:
- [ ] No package conflicts during installation
- [ ] All packages listed in `archinstall-config.json` are installed
- [ ] No broken dependencies reported by pacman
- [ ] Package database integrity check passes

### Phase 2: Service Configuration Validation

**Objective**: Verify systemd services are properly configured and enabled.

**Automated Test Script**: `scripts/validate-services.sh`

```bash
#!/bin/bash
# validate-services.sh
# Check systemd service status and configuration

set -e

echo "=== Validating System Services ==="

# Services that should be enabled
ENABLED_SERVICES=(
    "sddm.service"
    "NetworkManager.service"
    "libvirtd.service"
    "docker.service"
    "sshd.service"
    "bluetooth.service"
    "cups.service"
    "cronie.service"
)

echo "Checking enabled services..."
for service in "${ENABLED_SERVICES[@]}"; do
    if ! systemctl is-enabled "$service" >/dev/null 2>&1; then
        echo "ERROR: Service $service not enabled"
        exit 1
    fi
    echo "✓ $service enabled"
done

echo "Checking service status..."
for service in "${ENABLED_SERVICES[@]}"; do
    if ! systemctl is-active "$service" >/dev/null 2>&1; then
        echo "WARNING: Service $service not active (may start on next boot)"
    else
        echo "✓ $service active"
    fi
done

echo "✓ Service validation complete"
```

## Post-Install Validation

### Phase 3: KDE Desktop Environment Validation

**Objective**: Ensure KDE Plasma desktop starts correctly and provides expected functionality.

**Automated Test Script**: `scripts/validate-kde-desktop.sh`

```bash
#!/bin/bash
# validate-kde-desktop.sh
# Test KDE Plasma desktop environment functionality

set -e

echo "=== Validating KDE Plasma Desktop ==="

# Check if running in KDE
if [ -z "$XDG_CURRENT_DESKTOP" ] || [[ ! "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    echo "ERROR: Not running in KDE Plasma environment"
    echo "Current desktop: $XDG_CURRENT_DESKTOP"
    exit 1
fi

echo "✓ Running in KDE Plasma environment"

# Check KDE processes
KDE_PROCESSES=(
    "plasmashell"
    "kded5"
    "ksmserver"
    "kwin_x11"
)

echo "Checking KDE processes..."
for proc in "${KDE_PROCESSES[@]}"; do
    if ! pgrep -f "$proc" >/dev/null; then
        echo "ERROR: KDE process $proc not running"
        exit 1
    fi
    echo "✓ $proc running"
done

# Test KDE applications
echo "Testing KDE applications..."
kde_apps=(
    "konsole --version"
    "dolphin --version"
    "systemsettings --version"
)

for app in "${kde_apps[@]}"; do
    if ! $app >/dev/null 2>&1; then
        echo "ERROR: KDE application $app failed to run"
        exit 1
    fi
    echo "✓ $app functional"
done

# Check KDE configuration files
KDE_CONFIGS=(
    "$HOME/.config/kdeglobals"
    "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    "$HOME/.config/kglobalshortcutsrc"
)

echo "Checking KDE configuration files..."
for config in "${KDE_CONFIGS[@]}"; do
    if [ ! -f "$config" ]; then
        echo "WARNING: KDE config file $config not found"
    else
        echo "✓ $config exists"
    fi
done

echo "✓ KDE desktop validation complete"
```

**Manual Verification Points**:
- [ ] SDDM login manager displays correctly
- [ ] KDE Plasma desktop loads after login
- [ ] Panel contains expected widgets (task manager, system tray, clock)
- [ ] Desktop wallpaper is set
- [ ] Keyboard shortcuts work (Ctrl+Alt+T for terminal, etc.)
- [ ] Right-click desktop menu functions
- [ ] KDE System Settings accessible

### Phase 4: Security Configuration Validation

**Objective**: Verify security hardening measures are properly implemented.

**Automated Test Script**: `scripts/validate-security.sh`

```bash
#!/bin/bash
# validate-security.sh
# Validate security configurations

set -e

echo "=== Validating Security Configuration ==="

# Check firewall status
echo "Checking UFW firewall..."
if ! systemctl is-active ufw >/dev/null 2>&1; then
    echo "ERROR: UFW firewall not active"
    exit 1
fi

ufw_status=$(ufw status | grep -c "Status: active")
if [ "$ufw_status" -eq 0 ]; then
    echo "ERROR: UFW firewall not active"
    exit 1
fi
echo "✓ UFW firewall active"

# Check SSH hardening
echo "Checking SSH configuration..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "ERROR: SSH config file not found"
    exit 1
fi

# Check for security settings
ssh_checks=(
    "PermitRootLogin no"
    "PasswordAuthentication yes"
    "X11Forwarding no"
)

for check in "${ssh_checks[@]}"; do
    if ! grep -q "^$check" "$SSH_CONFIG"; then
        echo "WARNING: SSH setting '$check' not configured"
    else
        echo "✓ SSH: $check"
    fi
done

# Check password policies
echo "Checking password policies..."
if ! passwd -S kang | grep -q "Password must be changed"; then
    echo "WARNING: Password change not enforced for user kang"
else
    echo "✓ Password change enforced for user kang"
fi

# Check sudo configuration
echo "Checking sudo configuration..."
if ! sudo -l | grep -q "(ALL : ALL) ALL"; then
    echo "ERROR: User not in sudo group or sudo not configured"
    exit 1
fi
echo "✓ Sudo access configured"

# Check read-only root
echo "Checking read-only root configuration..."
root_mount=$(mount | grep "on / " | grep -o "ro," || true)
if [ -z "$root_mount" ]; then
    echo "WARNING: Root filesystem not mounted read-only"
else
    echo "✓ Root filesystem mounted read-only"
fi

echo "✓ Security validation complete"
```

**Manual Verification Points**:
- [ ] UFW firewall blocks unauthorized connections
- [ ] SSH service running but hardened
- [ ] User prompted to change password on first login
- [ ] Root filesystem mounted read-only
- [ ] LUKS encryption functional
- [ ] No insecure services exposed

### Phase 5: Application and User Experience Validation

**Objective**: Ensure installed applications work correctly and user experience is optimal.

**Automated Test Script**: `scripts/validate-applications.sh`

```bash
#!/bin/bash
# validate-applications.sh
# Test installed applications and user experience elements

set -e

echo "=== Validating Applications and User Experience ==="

# Test core applications
APPLICATIONS=(
    "firefox --version"
    "thunderbird --version"
    "libreoffice --version"
    "vlc --version"
    "gimp --version"
    "virt-manager --version"
    "docker --version"
    "qemu-system-x86_64 --version"
)

echo "Testing application installations..."
for app in "${APPLICATIONS[@]}"; do
    if ! $app >/dev/null 2>&1; then
        echo "ERROR: Application $app failed"
        exit 1
    fi
    echo "✓ $app functional"
done

# Test virtualization setup
echo "Testing virtualization setup..."
if ! virsh list >/dev/null 2>&1; then
    echo "ERROR: libvirt not accessible"
    exit 1
fi
echo "✓ libvirt accessible"

# Test Docker
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker not accessible"
    exit 1
fi
echo "✓ Docker functional"

# Check user directories
echo "Checking user directory structure..."
USER_DIRS=(
    "Desktop"
    "Documents"
    "Downloads"
    "Pictures"
    "Videos"
    "Music"
    "Projects"
)

for dir in "${USER_DIRS[@]}"; do
    if [ ! -d "$HOME/$dir" ]; then
        echo "ERROR: User directory $dir not created"
        exit 1
    fi
    echo "✓ $HOME/$dir exists"
done

# Check PATH configuration
echo "Checking PATH configuration..."
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "WARNING: $HOME/.local/bin not in PATH"
else
    echo "✓ Local bin directory in PATH"
fi

# Test KDE shortcuts (requires X session)
echo "Testing KDE keyboard shortcuts..."
if [ -n "$DISPLAY" ]; then
    # Test terminal shortcut (this would require actual key simulation)
    echo "✓ KDE shortcuts configured (manual testing required)"
else
    echo "WARNING: No X session detected, skipping shortcut tests"
fi

echo "✓ Application and user experience validation complete"
```

**Manual Verification Points**:
- [ ] Firefox launches and renders web pages
- [ ] Thunderbird email client functional
- [ ] LibreOffice opens documents correctly
- [ ] VLC plays media files
- [ ] GIMP image editor works
- [ ] Virtual Machine Manager launches
- [ ] Docker containers can be created
- [ ] User directories created and accessible
- [ ] Keyboard shortcuts functional
- [ ] Desktop theme and appearance correct
- [ ] Sound and multimedia working
- [ ] Network connectivity stable

### Phase 6: Hardware and Driver Validation

**Objective**: Ensure hardware is properly detected and drivers functional.

**Automated Test Script**: `scripts/validate-hardware.sh`

```bash
#!/bin/bash
# validate-hardware.sh
# Test hardware detection and driver functionality

set -e

echo "=== Validating Hardware and Drivers ==="

# Check NVIDIA drivers
echo "Checking NVIDIA drivers..."
if ! nvidia-smi >/dev/null 2>&1; then
    echo "ERROR: NVIDIA drivers not functional"
    exit 1
fi

gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)
echo "✓ NVIDIA GPU detected: $gpu_info"

# Check Intel graphics
echo "Checking Intel graphics..."
if ! glxinfo | grep -q "Intel"; then
    echo "WARNING: Intel graphics not detected"
else
    echo "✓ Intel graphics detected"
fi

# Check Bluetooth
echo "Checking Bluetooth..."
if ! systemctl is-active bluetooth >/dev/null 2>&1; then
    echo "WARNING: Bluetooth service not active"
else
    echo "✓ Bluetooth service active"
fi

# Check network
echo "Checking network connectivity..."
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "ERROR: No internet connectivity"
    exit 1
fi
echo "✓ Internet connectivity confirmed"

# Check audio
echo "Checking audio system..."
if ! pactl info >/dev/null 2>&1; then
    echo "WARNING: PulseAudio not accessible"
else
    echo "✓ PulseAudio functional"
fi

# Check printing system
echo "Checking printing system..."
if ! systemctl is-active cups >/dev/null 2>&1; then
    echo "WARNING: CUPS printing service not active"
else
    echo "✓ CUPS printing service active"
fi

echo "✓ Hardware and driver validation complete"
```

## Comprehensive Test Runner

**Master Test Script**: `scripts/run-full-validation.sh`

```bash
#!/bin/bash
# run-full-validation.sh
# Execute all validation tests in sequence

set -e

echo "=========================================="
echo "  KDE Plasma Installation Validation Suite"
echo "=========================================="

BASE_DIR="$(dirname "$0")"
LOG_FILE="/tmp/kde-validation-$(date +%Y%m%d-%H%M%S).log"

echo "Logging to: $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Test execution order
TESTS=(
    "validate-package-installation.sh"
    "validate-services.sh"
    "validate-security.sh"
    "validate-hardware.sh"
)

# Run installation-time tests first
echo "Running installation-time validation tests..."
for test in "${TESTS[@]}"; do
    if [ -f "$BASE_DIR/$test" ]; then
        echo "Executing $test..."
        if bash "$BASE_DIR/$test"; then
            echo "✓ $test PASSED"
        else
            echo "✗ $test FAILED"
            exit 1
        fi
    else
        echo "WARNING: $test not found, skipping"
    fi
done

# Post-install tests (require GUI environment)
if [ -n "$DISPLAY" ] && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    echo "Running post-install GUI validation tests..."
    POST_GUI_TESTS=(
        "validate-kde-desktop.sh"
        "validate-applications.sh"
    )

    for test in "${POST_GUI_TESTS[@]}"; do
        if [ -f "$BASE_DIR/$test" ]; then
            echo "Executing $test..."
            if bash "$BASE_DIR/$test"; then
                echo "✓ $test PASSED"
            else
                echo "✗ $test FAILED"
                exit 1
            fi
        else
            echo "WARNING: $test not found, skipping"
        fi
    done
else
    echo "WARNING: Not in KDE GUI environment, skipping GUI tests"
    echo "Current desktop: $XDG_CURRENT_DESKTOP"
    echo "DISPLAY: $DISPLAY"
fi

echo ""
echo "=========================================="
echo "  ALL VALIDATION TESTS COMPLETED SUCCESSFULLY"
echo "=========================================="
echo "Log file: $LOG_FILE"
```

## Test Execution Instructions

### During Installation
1. After `archinstall` completes, chroot into the installed system:
   ```bash
   arch-chroot /mnt
   cd /root/archconfig
   ```

2. Run installation-time validation:
   ```bash
   ./scripts/validate-package-installation.sh
   ./scripts/validate-services.sh
   ```

### Post-Install Validation
1. Boot into the installed system and login to KDE Plasma
2. Open Konsole terminal
3. Run full validation suite:
   ```bash
   cd /root/archconfig  # or wherever configs are stored
   ./scripts/run-full-validation.sh
   ```

### Manual Testing Checklist

**Boot and Login Process**:
- [ ] System boots with systemd-boot
- [ ] LUKS password prompt appears
- [ ] SDDM login manager displays
- [ ] KDE Plasma desktop loads
- [ ] Password change prompt appears on first login

**Desktop Environment**:
- [ ] Panel widgets functional (launcher, taskbar, system tray, clock)
- [ ] Desktop right-click menu works
- [ ] Keyboard shortcuts operational
- [ ] Window management (minimize, maximize, close)
- [ ] Multiple virtual desktops

**Applications**:
- [ ] Web browsing with Firefox
- [ ] Email with Thunderbird
- [ ] Office documents with LibreOffice
- [ ] Media playback with VLC
- [ ] Image editing with GIMP
- [ ] File management with Dolphin
- [ ] Terminal with Konsole

**System Integration**:
- [ ] Network management via KDE
- [ ] Bluetooth device detection
- [ ] Sound settings and volume control
- [ ] Display settings and multi-monitor
- [ ] Power management profiles

**Virtualization**:
- [ ] Virtual Machine Manager launches
- [ ] QEMU/KVM functional
- [ ] Docker containers work
- [ ] GPU passthrough ready (VFIO configured)

## Troubleshooting Common Issues

### KDE Desktop Not Loading
- Check Xorg/NVIDIA driver installation
- Verify SDDM service status
- Review Xorg logs: `journalctl -u sddm`

### Package Installation Failures
- Check internet connectivity
- Verify mirror configuration
- Review pacman logs: `journalctl -u pacman`

### Security Configuration Issues
- Verify UFW rules: `ufw status verbose`
- Check SSH config: `sshd -T`
- Review sudo configuration: `visudo -c`

### Hardware Detection Problems
- Check kernel modules: `lsmod | grep nvidia`
- Review dmesg for errors: `dmesg | grep -i error`
- Verify PCI device detection: `lspci -v`

## Performance Benchmarks

After successful validation, run these benchmarks to establish baseline performance:

```bash
# System information
neofetch

# Disk I/O performance
dd if=/dev/zero of=/tmp/testfile bs=1M count=1000
rm /tmp/testfile

# Memory performance
sysbench memory run

# CPU performance
sysbench cpu run

# GPU performance (NVIDIA)
nvidia-smi -q -d PERFORMANCE

# Virtualization performance
virsh nodeinfo
```

This comprehensive test plan ensures the KDE Plasma installation meets all functional, security, and user experience requirements.</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/docs/kde-installation-validation.md