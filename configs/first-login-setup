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

# Mark setup as complete
touch "$SETUP_FLAG"

echo "First-login setup complete!"
