# PiKVM Webcam Support

This feature enables webcam streaming from a browser to a target machine via a virtual USB webcam (UVC gadget).

## Overview

The webcam support consists of several components:

1. **UVC Gadget**: Creates a virtual USB webcam device using the Linux USB gadget framework
2. **v4l2loopback**: Creates a virtual video device for routing the webcam stream
3. **FFmpeg**: Handles the video stream encoding and routing
4. **Janus WebRTC Plugin**: Manages the WebRTC connection with the browser

## Prerequisites

- Linux kernel with USB gadget and v4l2loopback support
- FFmpeg installed on the system
- Janus WebRTC server with webcam2pikvm plugin

## Installation

1. Make the installation script executable:
   ```bash
   chmod +x scripts/install-webcam-support.sh
   ```

2. Run the installation script as root:
   ```bash
   sudo ./scripts/install-webcam-support.sh
   ```

3. Start the webcam services:
   ```bash
   sudo systemctl start kvmd-webcam
   sudo systemctl start kvmd-webcam-stream
   ```

4. (Optional) Enable the services to start on boot:
   ```bash
   sudo systemctl enable kvmd-webcam
   sudo systemctl enable kvmd-webcam-stream
   ```

## Configuration

### Webcam Settings

Edit `/usr/bin/kvmd-webcam-stream` to adjust:
- Input device (default: `/dev/video0`)
- Output device (default: `/dev/video10`)
- Resolution (default: 1280x720)
- Frame rate (default: 30fps)
- Video format (default: yuyv422)

### Janus Configuration

The Janus configuration is located at `/etc/janus/janus.plugin.webcam2pikvm.jcfg`. You can modify:
- Debug level
- Supported codecs (VP8, H.264)
- Video quality settings

## Usage

1. Open the PiKVM web interface
2. Navigate to the webcam settings
3. Enable the webcam feature
4. The target machine should detect a new USB webcam device

## Troubleshooting

### Check Service Status

```bash
systemctl status kvmd-webcam
systemctl status kvmd-webcam-stream
```

### View Logs

```bash
journalctl -u kvmd-webcam -f
journalctl -u kvmd-webcam-stream -f
```

### Verify v4l2loopback

```bash
lsmod | grep v4l2loopback
v4l2-ctl --list-devices
```

### Test Video Device

```bash
ffplay -f v4l2 /dev/video10
```

## Uninstallation

To remove the webcam support:

1. Stop and disable the services:
   ```bash
   sudo systemctl stop kvmd-webcam kvmd-webcam-stream
   sudo systemctl disable kvmd-webcam kvmd-webcam-stream
   ```

2. Remove the configuration files:
   ```bash
   sudo rm -f /etc/modules-load.d/v4l2loopback.conf
   sudo rm -f /etc/systemd/system/kvmd-webcam.service
   sudo rm -f /etc/systemd/system/kvmd-webcam-stream.service
   sudo rm -f /usr/bin/kvmd-webcam
   sudo rm -f /usr/bin/kvmd-webcam-stream
   sudo rm -f /etc/janus/janus.plugin.webcam2pikvm.jcfg
   ```

3. Remove the v4l2loopback module:
   ```bash
   sudo modprobe -r v4l2loopback
   ```

## Known Issues

- The webcam may not be detected immediately on some systems. Try unplugging and replugging the USB connection.
- High-resolution streams may cause performance issues on resource-constrained systems.
- Some applications may require specific video formats or resolutions.
