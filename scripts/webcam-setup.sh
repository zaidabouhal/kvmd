#!/bin/bash
# Script to set up webcam streaming from browser to UVC gadget

set -e

# Configuration
V4L2_DEVICE="/dev/video10"
MODULE="v4l2loopback"
MODULE_OPTS="devices=1 video_nr=10 card_label=\"PiKVM UVC\" exclusive_caps=1"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Function to check if a module is loaded
is_module_loaded() {
    lsmod | grep -q "^$1 "
}

# Function to load the v4l2loopback module
load_module() {
    echo "Loading $MODULE module..."
    if ! is_module_loaded "$MODULE"; then
        modprobe "$MODULE" $MODULE_OPTS
        echo "$MODULE module loaded with options: $MODULE_OPTS"
    else
        echo "$MODULE module is already loaded"
    fi
}

# Function to unload the v4l2loopback module
unload_module() {
    echo "Unloading $MODULE module..."
    if is_module_loaded "$MODULE"; then
        modprobe -r "$MODULE"
        echo "$MODULE module unloaded"
    else
        echo "$MODULE module is not loaded"
    fi
}

# Function to check if the video device exists
device_exists() {
    [ -e "$V4L2_DEVICE" ]
}

# Function to set up the virtual video device
setup_device() {
    echo "Setting up virtual video device..."
    
    # Create device node if it doesn't exist
    if ! device_exists; then
        mknod -m 666 "$V4L2_DEVICE" c 81 0
    fi
    
    # Set proper permissions
    chmod 666 "$V4L2_DEVICE"
    
    echo "Virtual video device ready at $V4L2_DEVICE"
}

# Main function
main() {
    case "$1" in
        start)
            load_module
            setup_device
            ;;
        stop)
            unload_module
            ;;
        status)
            if is_module_loaded "$MODULE"; then
                echo "$MODULE module is loaded"
                if device_exists; then
                    echo "Virtual video device exists at $V4L2_DEVICE"
                    v4l2-ctl --device "$V4L2_DEVICE" --all
                else
                    echo "Virtual video device does not exist at $V4L2_DEVICE"
                fi
            else
                echo "$MODULE module is not loaded"
            fi
            ;;
        *)
            echo "Usage: $0 {start|stop|status}"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"
