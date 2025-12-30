#!/bin/bash
# First Login Setup Script
# Configures multi-monitor support and other user-specific settings

SETUP_FLAG="$HOME/.first-login-complete"

# Check if already run
if [ -f "$SETUP_FLAG" ]; then
    exit 0
fi

echo "Running first-login setup..."

# Create common directories
mkdir -p "$HOME"/{Desktop,Documents,Downloads,Pictures,Videos,Music,Projects}
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

# Add local bin to PATH if not already there
if ! grep -q '$HOME/.local/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Set up basic git config prompt
if ! git config --global user.name >/dev/null 2>&1; then
    cat > "$HOME/.git-setup-reminder" << 'EOF'
# Remember to set up Git:
# git config --global user.name "Your Name"
# git config --global user.email "your.email@example.com"
EOF
fi

# KDE/Plasma multi-monitor configuration
if [ -n "$XDG_CURRENT_DESKTOP" ] && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    # Create basic KDE config directory
    mkdir -p "$HOME/.config/kscreenrc"
    
    # Enable display configuration module
    cat > "$HOME/.config/kdeglobals" << 'EOF'
[KScreen]
ScaleFactor=1
ScreenScaleFactors=
EOF

    # Set up KDE Plasma desktop experience
    echo "Configuring KDE Plasma desktop experience..."

    # Set default wallpaper
    mkdir -p "$HOME/.local/share/wallpapers"
    # Use a default wallpaper if available, or set a solid color
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "1" --group "Wallpaper" --group "org.kde.image" --group "General" --key "Image" "file:///usr/share/wallpapers/Next/contents/images/1920x1080.jpg"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "1" --group "Wallpaper" --group "org.kde.image" --group "General" --key "FillMode" "2"

    # Configure panel layout and widgets
    # Reset panel to default simple layout
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --key "activityId" ""
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --key "formfactor" "2"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --key "immutability" "1"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --key "lastScreen" "0"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --key "location" "4"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --key "plugin" "org.kde.panel"

    # Add essential widgets to panel
    # Application launcher
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "3" --key "immutability" "1"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "3" --key "plugin" "org.kde.plasma.kickoff"

    # Task manager
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "4" --key "immutability" "1"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "4" --key "plugin" "org.kde.plasma.taskmanager"

    # System tray
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "5" --key "immutability" "1"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "5" --key "plugin" "org.kde.plasma.systemtray"

    # Digital clock
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "6" --key "immutability" "1"
    kwriteconfig5 --file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" --group "Containments" --group "2" --group "Applets" --group "6" --key "plugin" "org.kde.plasma.digitalclock"

    # Set up keyboard shortcuts
    # Terminal shortcut (Ctrl+Alt+T)
    kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group "konsole" --group "org.kde.konsole.desktop" --key "_launch" "Ctrl+Alt+T\tCtrl+Alt+T\tLaunch Konsole"

    # File manager shortcut (Super+E)
    kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group "dolphin" --group "org.kde.dolphin.desktop" --key "_launch" "Meta+E\tMeta+E\tLaunch Dolphin"

    # Browser shortcut (Super+W)
    kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group "firefox" --group "firefox.desktop" --key "_launch" "Meta+W\tMeta+W\tLaunch Firefox"

    # System settings shortcut (Super+I)
    kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group "systemsettings" --group "systemsettings.desktop" --key "_launch" "Meta+I\tMeta+I\tLaunch System Settings"

    # Configure power management profiles
    # Set balanced power profile
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "AC" --group "DimDisplay" --key "idleTime" "300000"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "AC" --group "DPMSControl" --key "idleTime" "600000"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "AC" --group "HandleButtonEvents" --key "lidAction" "1"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "AC" --group "HandleButtonEvents" --key "powerButtonAction" "16"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "Battery" --group "DimDisplay" --key "idleTime" "120000"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "Battery" --group "DPMSControl" --key "idleTime" "300000"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "Battery" --group "HandleButtonEvents" --key "lidAction" "1"
    kwriteconfig5 --file "$HOME/.config/powerdevilrc" --group "Battery" --group "HandleButtonEvents" --key "powerButtonAction" "16"

    # Set up file associations
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/mimeapps.list" << 'EOF'
[Default Applications]
text/plain=org.kde.kate.desktop
text/html=firefox.desktop
image/jpeg=org.kde.gwenview.desktop
image/png=org.kde.gwenview.desktop
application/pdf=org.kde.okular.desktop
application/x-shellscript=org.kde.kate.desktop
inode/directory=org.kde.dolphin.desktop
EOF

    # Create helpful desktop shortcuts
    mkdir -p "$HOME/Desktop"

    # Terminal shortcut
    cat > "$HOME/Desktop/Terminal.desktop" << 'EOF'
[Desktop Entry]
Name=Terminal
Comment=Open a terminal window
Exec=konsole
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF
    chmod +x "$HOME/Desktop/Terminal.desktop"

    # File Manager shortcut
    cat > "$HOME/Desktop/Files.desktop" << 'EOF'
[Desktop Entry]
Name=Files
Comment=Open file manager
Exec=dolphin
Icon=system-file-manager
Type=Application
Categories=Utility;FileManager;
EOF
    chmod +x "$HOME/Desktop/Files.desktop"

    # Browser shortcut
    cat > "$HOME/Desktop/Browser.desktop" << 'EOF'
[Desktop Entry]
Name=Web Browser
Comment=Open web browser
Exec=firefox
Icon=web-browser
Type=Application
Categories=Network;WebBrowser;
EOF
    chmod +x "$HOME/Desktop/Browser.desktop"

    # System Monitor shortcut
    cat > "$HOME/Desktop/System Monitor.desktop" << 'EOF'
[Desktop Entry]
Name=System Monitor
Comment=Monitor system resources
Exec=plasma-systemmonitor
Icon=utilities-system-monitor
Type=Application
Categories=System;Monitor;
EOF
    chmod +x "$HOME/Desktop/System Monitor.desktop"

    # Settings shortcut
    cat > "$HOME/Desktop/Settings.desktop" << 'EOF'
[Desktop Entry]
Name=System Settings
Comment=Configure system settings
Exec=systemsettings
Icon=preferences-system
Type=Application
Categories=Settings;
EOF
    chmod +x "$HOME/Desktop/Settings.desktop"

    echo "KDE Plasma desktop configuration complete."
fi

# Create a helper script for monitor setup
cat > "$HOME/.local/bin/setup-monitors" << 'EOF'
#!/bin/bash
# Monitor setup helper script

echo "Available displays:"
xrandr --query | grep " connected"

echo ""
echo "Use 'xrandr' to configure displays manually, or"
echo "use KDE System Settings > Display Configuration"
echo ""
echo "For persistent multi-monitor setup, configure via:"
echo "  KDE: System Settings > Display Configuration"
echo "  CLI: Create script in ~/.config/autostart-scripts/"
EOF

chmod +x "$HOME/.local/bin/setup-monitors"

# Blackwell Station specific configurations
echo "Applying Blackwell Station user configurations..."

# Set up SSH directory and keys (if available)
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Check for SSH key in environment or create placeholder
if [ -n "$SSH_AUTHORIZED_KEY" ]; then
    echo "$SSH_AUTHORIZED_KEY" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    echo "SSH key added to authorized_keys"
else
    echo "Warning: No SSH key provided. Add your public key to ~/.ssh/authorized_keys"
fi

# Configure git for Blackwell Station
git config --global user.name "Kang"
git config --global user.email "kang@blackwell-station.local"
git config --global init.defaultBranch main
git config --global pull.rebase true

# Set up development directories
mkdir -p "$HOME/Projects"
mkdir -p "$HOME/.config/libvirt"
mkdir -p "$HOME/.local/share/libvirt/images"

# Configure libvirt for user
cat > "$HOME/.config/libvirt/libvirt.conf" << 'EOF'
# Libvirt user configuration for Blackwell Station
uri_default = "qemu:///system"
EOF

# Set up basic aliases for virtualization work
cat >> "$HOME/.bashrc" << 'EOF'

# Blackwell Station aliases
alias vms='virsh list --all'
alias vm-start='virsh start'
alias vm-stop='virsh shutdown'
alias vm-destroy='virsh destroy'
alias vm-console='virsh console'
alias docker-clean='docker system prune -f'
alias logs='journalctl -f'
EOF

# Configure Docker rootless
if [ -f "$HOME/.local/bin/dockerd-rootless-setuptool.sh" ]; then
    echo "Docker rootless already configured"
else
    echo "Note: Run 'dockerd-rootless-setuptool.sh install' if Docker rootless is needed"
fi

# Set up basic monitoring shortcuts
cat > "$HOME/.local/bin/system-status" << 'EOF'
#!/bin/bash
echo "=== Blackwell Station System Status ==="
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $4}') available"
echo "VMs: $(virsh list --all | grep -c "running\|shut") running"
echo "Docker: $(docker ps | wc -l) containers"
echo "Uptime: $(uptime -p)"
EOF
chmod +x "$HOME/.local/bin/system-status"

# Mark setup as complete
touch "$SETUP_FLAG"

echo "First-login setup complete!"
echo "Welcome to Blackwell Station - E5-2665 v4 virtualization host"
