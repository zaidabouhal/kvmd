#!/bin/bash
# Installation script for PiKVM webcam support

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SERVICES_DIR="$ROOT_DIR/configs/os/services"
MODULES_DIR="/etc/modules-load.d"
SYSTEMD_DIR="/etc/systemd/system"
BIN_DIR="/usr/bin"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Function to install a script
install_script() {
    local src="$1"
    local dst="$2"
    
    echo "Installing $dst..."
    cp "$src" "$dst"
    chmod +x "$dst"
}

# Function to install a systemd service
install_service() {
    local service="$1"
    
    echo "Installing $service..."
    cp "$SERVICES_DIR/$service" "$SYSTEMD_DIR/"
    systemctl enable "$service"
    systemctl daemon-reload
}

# Install scripts
install_script "$SCRIPT_DIR/webcam-setup.sh" "$BIN_DIR/kvmd-webcam"
install_script "$SCRIPT_DIR/webcam-stream.sh" "$BIN_DIR/kvmd-webcam-stream"

# Install modules configuration
mkdir -p "$MODULES_DIR"
cp "$ROOT_DIR/configs/os/modules-load.d/v4l2loopback.conf" "$MODULES_DIR/"

# Install services
install_service "kvmd-webcam.service"
install_service "kvmd-webcam-stream.service"

# Install Janus plugin configuration
JANUS_CONF_DIR="/etc/janus"
mkdir -p "$JANUS_CONF_DIR"
cp "$ROOT_DIR/configs/janus/janus.plugin.webcam2pikvm.jcfg" "$JANUS_CONF_DIR/"

# Update Janus main config to load our plugin
if ! grep -q "janus.plugin.webcam2pikvm" "$JANUS_CONF_DIR/janus.jcfg"; then
    echo "Updating Janus configuration..."
    sed -i '/^plugins: {/a \    "janus.plugin.webcam2pikvm" = {
        debug_level = 4;
        accept_vp8 = true;
        accept_h264 = true;
    };' "$JANUS_CONF_DIR/janus.jcfg"
fi

echo "Installation complete!"
echo "Please reboot or run the following commands to start the services:"
echo "  systemctl start kvmd-webcam"
echo "  systemctl start kvmd-webcam-stream"
