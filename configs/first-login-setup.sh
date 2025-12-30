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
